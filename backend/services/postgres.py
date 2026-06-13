"""
PostgreSQL service — writes order analytics data alongside Firestore.

If DATABASE_URL is not set, all functions silently skip so the app
continues working with Firestore-only during development.
"""

import os
import json
import psycopg2
from psycopg2.extras import execute_values
import re
from urllib.parse import unquote

_conn = None


def _parse_db_url(url: str) -> dict:
    """
    Parse postgresql://user:pass@host:port/db reliably.
    urlparse doesn't recognise the postgresql:// scheme so we use regex.
    Splits on the LAST @ so passwords containing @ work correctly.
    """
    # Strip scheme
    rest = re.sub(r'^[^:]+://', '', url)
    # Split on LAST @ to separate credentials from host
    at_pos = rest.rfind('@')
    if at_pos == -1:
        raise ValueError(f"Cannot parse DATABASE_URL: {url!r}")
    credentials = rest[:at_pos]
    hostpart    = rest[at_pos + 1:]
    # Split credentials on FIRST : only
    colon_pos = credentials.index(':')
    user     = unquote(credentials[:colon_pos])
    password = unquote(credentials[colon_pos + 1:])
    # Parse host:port/db
    m = re.match(r'([^:/]+):(\d+)/([^?]+)', hostpart)
    if not m:
        raise ValueError(f"Cannot parse host part: {hostpart!r}")
    return {
        "user":     user,
        "password": password,
        "host":     m.group(1),
        "port":     int(m.group(2)),
        "dbname":   m.group(3),
    }


def _get_conn():
    global _conn
    url = os.getenv("DATABASE_URL")
    if not url:
        return None
    try:
        if _conn is None or _conn.closed:
            params = _parse_db_url(url)
            _conn = psycopg2.connect(**params, sslmode="require")
            _conn.autocommit = True
        return _conn
    except Exception as e:
        print(f"[Postgres] Connection failed: {e}")
        return None


def init_db():
    """Create tables on startup if they don't exist."""
    conn = _get_conn()
    if not conn:
        url = os.getenv("DATABASE_URL")
        if not url:
            print("[Postgres] DATABASE_URL not set — skipping PostgreSQL setup.")
        else:
            print("[Postgres] Could not connect — check DATABASE_URL and ?sslmode=require.")
        return
    sql_path = os.path.join(os.path.dirname(__file__), "..", "migrations", "001_init.sql")
    try:
        with open(sql_path, "r", encoding="utf-8") as f:
            sql = f.read()
        with conn.cursor() as cur:
            cur.execute(sql)
        print("[Postgres] Schema ready.")
    except Exception as e:
        print(f"[Postgres] Schema init failed: {e}")


# ─── Customers ────────────────────────────────────────────────

def upsert_customer(uid: str, phone: str, full_name: str) -> None:
    """Insert customer if new, update name/phone if existing."""
    conn = _get_conn()
    if not conn:
        return
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO customers (id, phone, full_name)
                VALUES (%s, %s, %s)
                ON CONFLICT (id) DO UPDATE
                    SET phone     = EXCLUDED.phone,
                        full_name = EXCLUDED.full_name
                """,
                (uid, phone, full_name),
            )
    except Exception as e:
        print(f"[Postgres] upsert_customer failed: {e}")


def delete_customer(uid: str) -> None:
    """
    Remove a customer from analytics on account deletion.

    Hard-deletes the row when the customer has no orders. If they have
    past orders, the orders FK (orders.customer_id REFERENCES customers)
    prevents a hard delete and we must preserve them for revenue history,
    so we instead scrub the personal data (name/phone/fcm token).
    """
    conn = _get_conn()
    if not conn:
        return
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT COUNT(*) FROM orders WHERE customer_id = %s", (uid,))
            has_orders = cur.fetchone()[0] > 0
            if has_orders:
                cur.execute(
                    """
                    UPDATE customers
                    SET full_name = 'Deleted Account',
                        phone     = NULL,
                        fcm_token = NULL
                    WHERE id = %s
                    """,
                    (uid,),
                )
            else:
                cur.execute("DELETE FROM customers WHERE id = %s", (uid,))
    except Exception as e:
        print(f"[Postgres] delete_customer failed: {e}")


# ─── Orders ───────────────────────────────────────────────────

def insert_order(order_data: dict) -> None:
    """
    Write a new order row. Called right after Firestore create.
    order_data keys: id, order_number, customer_id, customer_name,
                     status, total_price, notes, created_at
    """
    conn = _get_conn()
    if not conn:
        return
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO orders
                    (id, order_number, customer_id, customer_name, status,
                     total_price, notes, payment_method, created_at, updated_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (id) DO NOTHING
                """,
                (
                    order_data["id"],
                    order_data.get("order_number"),
                    order_data["customer_id"],
                    order_data.get("customer_name", ""),
                    order_data.get("status", "received"),
                    order_data["total_price"],
                    order_data.get("notes", ""),
                    order_data.get("payment_method"),
                    order_data.get("created_at"),
                    order_data.get("created_at"),
                ),
            )
    except Exception as e:
        print(f"[Postgres] insert_order failed: {e}")


def insert_order_items(order_id: str, items: list) -> None:
    """
    Write all line items for an order.
    Each item dict: menu_item_id, name_en, name_ar,
                    quantity, price, customizations, notes
    """
    conn = _get_conn()
    if not conn:
        return
    try:
        rows = [
            (
                order_id,
                item.get("menu_item_id", ""),
                item.get("name_en", ""),
                item.get("name_ar", ""),
                item.get("quantity", 1),
                item.get("price", 0.0),
                item.get("price", 0.0) * item.get("quantity", 1),
                json.dumps(item.get("customizations", {})),
                item.get("notes", ""),
            )
            for item in items
        ]
        with conn.cursor() as cur:
            execute_values(
                cur,
                """
                INSERT INTO order_items
                    (order_id, menu_item_id, name_en, name_ar,
                     quantity, unit_price, subtotal, customizations, notes)
                VALUES %s
                """,
                rows,
            )
    except Exception as e:
        print(f"[Postgres] insert_order_items failed: {e}")


def update_order_status(order_id: str, status: str) -> None:
    """Sync status change. Sets picked_up_at when status = picked_up."""
    conn = _get_conn()
    if not conn:
        return
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                UPDATE orders
                SET status     = %s,
                    updated_at = NOW(),
                    picked_up_at = CASE WHEN %s = 'picked_up' THEN NOW() ELSE picked_up_at END
                WHERE id = %s
                """,
                (status, status, order_id),
            )
            # Update customer stats when order is completed
            if status == "picked_up":
                cur.execute(
                    """
                    UPDATE customers c
                    SET total_orders  = total_orders + 1,
                        total_spent   = total_spent + o.total_price,
                        last_order_at = NOW()
                    FROM orders o
                    WHERE o.id = %s AND c.id = o.customer_id
                    """,
                    (order_id,),
                )
    except Exception as e:
        print(f"[Postgres] update_order_status failed: {e}")
