CREATE DATABASE IF NOT EXISTS grocery_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE grocery_db;

-- Table 1: users
CREATE TABLE IF NOT EXISTS users (
    id           INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    username     VARCHAR(150)  NOT NULL,
    email        VARCHAR(254)  NOT NULL,
    password     VARCHAR(255)  NOT NULL,
    first_name   VARCHAR(50)   NOT NULL DEFAULT '',
    last_name    VARCHAR(50)   NOT NULL DEFAULT '',
    phone        VARCHAR(20),
    role         ENUM('customer','staff','admin') NOT NULL DEFAULT 'customer',
    is_active    TINYINT(1)    NOT NULL DEFAULT 1,
    created_at   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_username (username),
    UNIQUE KEY uk_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table 2: categories
CREATE TABLE IF NOT EXISTS categories (
    id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name        VARCHAR(100) NOT NULL,
    description TEXT,
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_cat_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table 3: products
CREATE TABLE IF NOT EXISTS products (
    id          INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    name        VARCHAR(200)  NOT NULL,
    description TEXT,
    price       DECIMAL(10,2) NOT NULL,
    unit        VARCHAR(30)   NOT NULL DEFAULT 'each',
    stock       INT UNSIGNED  NOT NULL DEFAULT 0,
    image_url   VARCHAR(500),
    category_id INT UNSIGNED  NOT NULL,
    is_active   TINYINT(1)    NOT NULL DEFAULT 1,
    created_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_product_category
        FOREIGN KEY (category_id) REFERENCES categories(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_category (category_id),
    INDEX idx_price (price)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table 4: cart
CREATE TABLE IF NOT EXISTS cart (
    id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id    INT UNSIGNED NOT NULL,
    created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_user_cart (user_id),
    CONSTRAINT fk_cart_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table 5: cart_items
CREATE TABLE IF NOT EXISTS cart_items (
    id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    cart_id    INT UNSIGNED NOT NULL,
    product_id INT UNSIGNED NOT NULL,
    quantity   INT UNSIGNED NOT NULL DEFAULT 1,
    added_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_cart_product (cart_id, product_id),
    CONSTRAINT fk_ci_cart    FOREIGN KEY (cart_id)    REFERENCES cart(id)     ON DELETE CASCADE,
    CONSTRAINT fk_ci_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table 6: orders
CREATE TABLE IF NOT EXISTS orders (
    id               INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    user_id          INT UNSIGNED  NOT NULL,
    total_amount     DECIMAL(10,2) NOT NULL,
    status           ENUM('pending','processing','packed','out_for_delivery','delivered','cancelled')
                     NOT NULL DEFAULT 'pending',
    payment_method   VARCHAR(50)   NOT NULL DEFAULT 'card',
    payment_status   ENUM('unpaid','paid','refunded') NOT NULL DEFAULT 'unpaid',
    delivery_address TEXT,
    delivery_notes   TEXT,
    created_at       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_order_user
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table 7: order_items
CREATE TABLE IF NOT EXISTS order_items (
    id         INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    order_id   INT UNSIGNED  NOT NULL,
    product_id INT UNSIGNED  NOT NULL,
    quantity   INT UNSIGNED  NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_oi_order   FOREIGN KEY (order_id)   REFERENCES orders(id)   ON DELETE CASCADE,
    CONSTRAINT fk_oi_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ============================================================
--  SAMPLE DATA
-- ============================================================

-- users (6 records)
INSERT INTO users (username, email, password, first_name, last_name, phone, role) VALUES
('admin_tushar',  'tushar@grocerystore.com', 'hashed_pw_admin', 'Tushar',  'Chapagain', '0400000001', 'admin'),
('staff_alice',   'alice@grocerystore.com',  'hashed_pw_staff', 'Alice',   'Smith',     '0400000002', 'staff'),
('customer_john', 'john@example.com',        'hashed_pw_001',   'John',    'Brown',     '0411111111', 'customer'),
('customer_mary', 'mary@example.com',        'hashed_pw_002',   'Mary',    'Jones',     '0422222222', 'customer'),
('customer_alex', 'alex@example.com',        'hashed_pw_003',   'Alex',    'Taylor',    '0433333333', 'customer'),
('customer_sara', 'sara@example.com',        'hashed_pw_004',   'Sara',    'Wilson',    '0444444444', 'customer');

-- categories (7 records - real supermarket departments)
INSERT INTO categories (name, description) VALUES
('Fruit & Vegetables', 'Fresh seasonal fruit, vegetables and herbs'),
('Dairy & Eggs',       'Milk, cheese, yoghurt, butter and eggs'),
('Meat & Seafood',     'Fresh and frozen meat, poultry and seafood'),
('Bakery',             'Fresh bread, rolls, pastries and cakes'),
('Pantry & Dry Goods', 'Pasta, rice, canned goods, sauces and condiments'),
('Frozen Foods',       'Frozen meals, vegetables, ice cream and snacks'),
('Drinks',             'Water, juice, soft drinks, coffee and tea');

-- products (25 records across all departments)
INSERT INTO products (name, description, price, unit, stock, category_id) VALUES
-- Fruit & Vegetables (cat 1)
('Bananas',              'Cavendish bananas, per kg',                  2.90,  'kg',    80,  1),
('Broccoli',             'Fresh broccoli head, approx 500g',           2.50,  'each',  60,  1),
('Roma Tomatoes',        'Ripe roma tomatoes, per kg',                 3.99,  'kg',    70,  1),
('Baby Spinach',         'Washed baby spinach leaves, 120g bag',       3.50,  'bag',   45,  1),
('Carrots',              'Washed carrots, 1kg bag',                    1.99,  'bag',   90,  1),
('Granny Smith Apples',  'Crisp green apples, per kg',                 4.50,  'kg',    55,  1),
-- Dairy & Eggs (cat 2)
('Full Cream Milk 2L',   'Full cream fresh milk, 2 litre',             3.60,  'bottle',100, 2),
('Free Range Eggs 12pk', 'Cage-free large eggs, 12 pack',              6.50,  'pack',  75,  2),
('Tasty Cheese 500g',    'Cheddar tasty cheese block, 500g',           7.00,  'block', 50,  2),
('Greek Yoghurt 500g',   'Plain Greek yoghurt, 500g tub',              5.50,  'tub',   40,  2),
('Butter 250g',          'Unsalted butter, 250g block',                4.80,  'block', 60,  2),
-- Meat & Seafood (cat 3)
('Chicken Breast 500g',  'Skinless chicken breast fillets, 500g',      9.00,  'pack',  40,  3),
('Beef Mince 500g',      'Regular beef mince, 500g',                   8.50,  'pack',  35,  3),
('Salmon Fillets 2pk',   'Atlantic salmon fillets, 2 pack 300g',      12.00,  'pack',  25,  3),
('Pork Sausages 6pk',    'Thin pork sausages, 6 pack 500g',            7.50,  'pack',  30,  3),
-- Bakery (cat 4)
('White Sandwich Bread', 'Sliced white sandwich loaf, 700g',           3.50,  'loaf',  50,  4),
('Sourdough Loaf',       'Artisan sourdough loaf, freshly baked',      6.00,  'loaf',  20,  4),
('Croissants 4pk',       'Butter croissants, 4 pack',                  5.00,  'pack',  25,  4),
-- Pantry & Dry Goods (cat 5)
('Pasta Spaghetti 500g', 'Durum wheat spaghetti, 500g',                2.00,  'pack',  100, 5),
('Basmati Rice 1kg',     'Long grain basmati rice, 1kg bag',           4.00,  'bag',   80,  5),
('Tomato Pasta Sauce',   'Classic tomato and basil pasta sauce, 500g', 3.20,  'jar',   90,  5),
('Olive Oil 500ml',      'Extra virgin olive oil, 500ml bottle',       9.00,  'bottle',45,  5),
-- Frozen Foods (cat 6)
('Frozen Peas 1kg',      'Garden peas, frozen, 1kg bag',               3.50,  'bag',   60,  6),
('Vanilla Ice Cream 2L', 'Classic vanilla ice cream, 2 litre tub',     7.00,  'tub',   30,  6),
-- Drinks (cat 7)
('Orange Juice 2L',      'Fresh squeezed style orange juice, 2L',      5.00,  'bottle',55,  7);

-- cart (one per customer)
INSERT INTO cart (user_id) VALUES (3), (4), (5), (6);

-- cart_items
INSERT INTO cart_items (cart_id, product_id, quantity) VALUES
(1, 1,  2),   -- john: Bananas x2
(1, 7,  1),   -- john: Full Cream Milk x1
(1, 12, 1),   -- john: Chicken Breast x1
(2, 6,  1),   -- mary: Apples x1
(2, 8,  2),   -- mary: Eggs x2
(2, 19, 1),   -- mary: Pasta x1
(3, 2,  1),   -- alex: Broccoli x1
(3, 9,  1),   -- alex: Cheese x1
(3, 24, 1),   -- alex: Ice Cream x1
(4, 4,  2),   -- sara: Baby Spinach x2
(4, 25, 1);   -- sara: Orange Juice x1

-- orders (5 records)
INSERT INTO orders (user_id, total_amount, status, payment_method, payment_status, delivery_address) VALUES
(3, 24.90, 'delivered',        'card',   'paid',     '12 King St, Sydney NSW 2000'),
(4, 19.50, 'out_for_delivery', 'card',   'paid',     '45 Queen Ave, Melbourne VIC 3000'),
(5, 32.00, 'packed',           'paypal', 'paid',     '7 Park Rd, Brisbane QLD 4000'),
(6, 11.00, 'pending',          'card',   'unpaid',   '3 Beach Rd, Perth WA 6000'),
(3, 15.80, 'cancelled',        'card',   'refunded', '12 King St, Sydney NSW 2000');

-- order_items
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1, 1,  2, 2.90),   -- Bananas x2
(1, 7,  2, 3.60),   -- Milk x2
(1, 8,  1, 6.50),   -- Eggs x1
(1, 16, 1, 3.50),   -- Bread x1
(2, 6,  1, 4.50),   -- Apples x1
(2, 10, 1, 5.50),   -- Yoghurt x1
(2, 19, 2, 2.00),   -- Pasta x2
(2, 20, 1, 4.00),   -- Rice x1
(3, 12, 2, 9.00),   -- Chicken x2
(3, 14, 1,12.00),   -- Salmon x1
(4, 1,  1, 2.90),   -- Bananas x1
(4, 7,  1, 3.60),   -- Milk x1
(4, 23, 1, 3.50),   -- Frozen Peas x1
(5, 13, 1, 8.50),   -- Beef Mince x1
(5, 21, 1, 3.20),   -- Pasta Sauce x1
(5, 23, 1, 3.50);   -- Frozen Peas x1


-- ============================================================
--  VIEWS
-- ============================================================

CREATE OR REPLACE VIEW v_products_full AS
    SELECT p.id, p.name, p.description, p.price, p.unit,
           p.stock, p.is_active, c.name AS category
    FROM products p
    JOIN categories c ON c.id = p.category_id;

CREATE OR REPLACE VIEW v_low_stock AS
    SELECT p.id, p.name, p.stock, p.unit, p.price, c.name AS category
    FROM products p
    JOIN categories c ON c.id = p.category_id
    WHERE p.stock <= 10
    ORDER BY p.stock ASC;

CREATE OR REPLACE VIEW v_order_summary AS
    SELECT o.id AS order_id, u.username, u.email,
           o.total_amount, o.status, o.payment_status,
           o.delivery_address, o.created_at,
           COUNT(oi.id) AS line_items
    FROM orders o
    JOIN users u ON u.id = o.user_id
    LEFT JOIN order_items oi ON oi.order_id = o.id
    GROUP BY o.id, u.username, u.email, o.total_amount,
             o.status, o.payment_status, o.delivery_address, o.created_at;

CREATE OR REPLACE VIEW v_cart_summary AS
    SELECT u.username, u.email,
           COUNT(ci.id)               AS total_items,
           SUM(ci.quantity)           AS total_quantity,
           SUM(p.price * ci.quantity) AS cart_value
    FROM cart ca
    JOIN users u       ON u.id  = ca.user_id
    JOIN cart_items ci ON ci.cart_id = ca.id
    JOIN products p    ON p.id  = ci.product_id
    GROUP BY ca.id, u.username, u.email;

-- ============================================================
--  VERIFY
-- ============================================================
-- SHOW TABLES;
-- SELECT COUNT(*) FROM users;
-- SELECT COUNT(*) FROM products;
-- SELECT COUNT(*) FROM orders;
-- SELECT * FROM v_low_stock;
-- SELECT * FROM v_order_summary;
