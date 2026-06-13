-- ─── Hamsa To Go — PostgreSQL Schema ─────────────────────────
-- Run once: psql -U postgres -d hamsa -f migrations/001_init.sql


-- ─── customers ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS customers (
    id              VARCHAR(128) PRIMARY KEY,   -- Firebase UID
    phone           VARCHAR(20),
    full_name       VARCHAR(200)    NOT NULL,
    fcm_token       TEXT,
    total_orders    INT             NOT NULL DEFAULT 0,
    total_spent     DECIMAL(10, 2)  NOT NULL DEFAULT 0.00,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_order_at   TIMESTAMP WITH TIME ZONE
);


-- ─── orders ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS orders (
    id              VARCHAR(128) PRIMARY KEY,   -- Firestore doc ID
    order_number    BIGINT,                     -- sequential, 1-based (counters/orders in Firestore)
    customer_id     VARCHAR(128)    NOT NULL REFERENCES customers(id),
    customer_name   VARCHAR(200)    NOT NULL,
    status          VARCHAR(20)     NOT NULL DEFAULT 'received',
    total_price     DECIMAL(10, 2)  NOT NULL,
    notes           TEXT            DEFAULT '',
    payment_method  VARCHAR(50),    -- online method (mada / card / apple_pay / stc_pay); no cash
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    picked_up_at    TIMESTAMP WITH TIME ZONE
);

-- Existing databases created before order_number was added
ALTER TABLE orders ADD COLUMN IF NOT EXISTS order_number BIGINT;

-- Cash is no longer accepted — drop the legacy 'cash' default so new
-- orders record the actual online method (or NULL if unknown).
ALTER TABLE orders ALTER COLUMN payment_method DROP DEFAULT;

CREATE INDEX IF NOT EXISTS idx_orders_customer_id  ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status        ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at    ON orders(created_at);
CREATE UNIQUE INDEX IF NOT EXISTS idx_orders_order_number
    ON orders(order_number) WHERE order_number IS NOT NULL;


-- ─── order_items ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS order_items (
    id              SERIAL          PRIMARY KEY,
    order_id        VARCHAR(128)    NOT NULL REFERENCES orders(id),
    menu_item_id    VARCHAR(128)    NOT NULL,
    name_en         VARCHAR(200)    NOT NULL,
    name_ar         VARCHAR(200)    NOT NULL,
    quantity        INT             NOT NULL,
    unit_price      DECIMAL(10, 2)  NOT NULL,
    subtotal        DECIMAL(10, 2)  NOT NULL,
    customizations  JSONB           DEFAULT '{}',
    notes           TEXT            DEFAULT ''
);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id     ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_menu_item_id ON order_items(menu_item_id);


-- ─── Useful views ─────────────────────────────────────────────

-- Daily revenue
CREATE OR REPLACE VIEW daily_revenue AS
SELECT
    DATE(created_at)    AS day,
    COUNT(*)            AS order_count,
    SUM(total_price)    AS revenue
FROM orders
WHERE status = 'picked_up'
GROUP BY DATE(created_at)
ORDER BY day DESC;


-- Best selling items
CREATE OR REPLACE VIEW top_items AS
SELECT
    menu_item_id,
    name_en,
    SUM(quantity)       AS total_sold,
    SUM(subtotal)       AS total_revenue
FROM order_items
GROUP BY menu_item_id, name_en
ORDER BY total_sold DESC;


-- Top customers
CREATE OR REPLACE VIEW top_customers AS
SELECT
    c.id,
    c.full_name,
    c.phone,
    c.total_orders,
    c.total_spent,
    c.last_order_at
FROM customers c
ORDER BY c.total_spent DESC;
