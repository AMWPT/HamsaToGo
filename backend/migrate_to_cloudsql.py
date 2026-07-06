"""
One-off migration: copy analytics data from the old Supabase Postgres to the
new Cloud SQL (Data Connect) Postgres.

Both databases share the same logical schema (customers / orders / order_items),
so this is a straight column-by-column copy. It's idempotent — re-running is
safe (customers/orders use ON CONFLICT DO NOTHING).

Usage (PowerShell):
    $env:SOURCE_DATABASE_URL = "postgresql://...supabase-pooler...:5432/postgres"
    $env:DEST_DATABASE_URL   = "postgresql://postgres:PASSWORD@CLOUD_SQL_PUBLIC_IP:5432/hamsacafe-1-database"
    python migrate_to_cloudsql.py
"""
import os
import psycopg2
from psycopg2.extras import execute_values, Json

SRC = os.environ["SOURCE_DATABASE_URL"]
DST = os.environ["DEST_DATABASE_URL"]


def _conn(url):
    return psycopg2.connect(url, sslmode="require")


def migrate():
    src = _conn(SRC)
    dst = _conn(DST)
    dst.autocommit = False
    try:
        scur, dcur = src.cursor(), dst.cursor()

        # ── customers ──
        scur.execute(
            "SELECT id, phone, full_name, fcm_token, total_orders, "
            "total_spent, created_at, last_order_at FROM customers"
        )
        rows = scur.fetchall()
        execute_values(dcur,
            "INSERT INTO customers (id, phone, full_name, fcm_token, "
            "total_orders, total_spent, created_at, last_order_at) VALUES %s "
            "ON CONFLICT (id) DO NOTHING", rows)
        print(f"customers:   {len(rows)} copied")

        # ── orders ──
        scur.execute(
            "SELECT id, order_number, customer_id, customer_name, status, "
            "total_price, notes, payment_method, created_at, updated_at, "
            "picked_up_at FROM orders"
        )
        rows = scur.fetchall()
        execute_values(dcur,
            "INSERT INTO orders (id, order_number, customer_id, customer_name, "
            "status, total_price, notes, payment_method, created_at, updated_at, "
            "picked_up_at) VALUES %s ON CONFLICT (id) DO NOTHING", rows)
        print(f"orders:      {len(rows)} copied")

        # ── order_items ── (skip source id — Cloud SQL generates its own UUID)
        scur.execute(
            "SELECT order_id, menu_item_id, name_en, name_ar, quantity, "
            "unit_price, subtotal, customizations, notes FROM order_items"
        )
        rows = [
            (r[0], r[1], r[2], r[3], r[4], r[5], r[6],
             Json(r[7]) if r[7] is not None else None, r[8])
            for r in scur.fetchall()
        ]
        execute_values(dcur,
            "INSERT INTO order_items (order_id, menu_item_id, name_en, name_ar, "
            "quantity, unit_price, subtotal, customizations, notes) VALUES %s",
            rows)
        print(f"order_items: {len(rows)} copied")

        dst.commit()
        print("✓ Migration complete.")
    except Exception:
        dst.rollback()
        raise
    finally:
        src.close()
        dst.close()


if __name__ == "__main__":
    migrate()
