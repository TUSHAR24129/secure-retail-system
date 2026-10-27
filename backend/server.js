// ============================================================
//  Grocery Store System - Backend API Server
//  File   : server.js
//  Author : Tushar Chapagain
// ============================================================

const express = require('express');
const mysql   = require('mysql2');
const cors    = require('cors');

const app  = express();
const PORT = 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Database connection
const db = mysql.createConnection({
    host     : '127.0.0.1',
    port     : 3306,
    user     : 'root',
    password : 'Admin123!',
    database : 'grocery_db'
});

db.connect((err) => {
    if (err) {
        console.error('Database connection failed:', err.message);
        process.exit(1);
    }
    console.log('Connected to grocery_db');
    console.log('Server running at: http://localhost:' + PORT);
});

// ── WELCOME ───────────────────────────────────────────────────
app.get('/', (req, res) => {
    res.json({
        message : 'Grocery Store API',
        version : '1.0.0',
        author  : 'Tushar Chapagain',
        routes  : [
            'GET  /api/products          - All products',
            'GET  /api/products/:id      - Single product',
            'GET  /api/products/category/:categoryId - Products by category',
            'POST /api/products          - Create product',
            'GET  /api/categories        - All categories',
            'GET  /api/users             - All users',
            'GET  /api/orders            - All orders',
            'GET  /api/orders/:id        - Single order with items',
            'POST /api/orders            - Create order',
            'GET  /api/cart/:userId      - User cart',
            'POST /api/cart/:userId      - Add item to cart',
            'DELETE /api/cart/:userId/:productId - Remove from cart',
            'GET  /api/low-stock         - Low stock products',
        ]
    });
});

// ── PRODUCTS ──────────────────────────────────────────────────

// GET all products
app.get('/api/products', (req, res) => {
    const sql = `
        SELECT p.id, p.name, p.description, p.price, p.unit,
               p.stock, p.image_url, p.is_active, c.name AS category
        FROM products p
        JOIN categories c ON c.id = p.category_id
        WHERE p.is_active = 1
        ORDER BY c.name, p.name
    `;
    db.query(sql, (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ count: results.length, products: results });
    });
});

// GET single product
app.get('/api/products/:id', (req, res) => {
    const sql = `
        SELECT p.id, p.name, p.description, p.price, p.unit,
               p.stock, p.image_url, p.is_active, c.name AS category
        FROM products p
        JOIN categories c ON c.id = p.category_id
        WHERE p.id = ?
    `;
    db.query(sql, [req.params.id], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        if (results.length === 0) return res.status(404).json({ error: 'Product not found' });
        res.json(results[0]);
    });
});

// GET products by category
app.get('/api/products/category/:categoryId', (req, res) => {
    const sql = `
        SELECT p.id, p.name, p.description, p.price, p.unit,
               p.stock, c.name AS category
        FROM products p
        JOIN categories c ON c.id = p.category_id
        WHERE p.category_id = ? AND p.is_active = 1
        ORDER BY p.name
    `;
    db.query(sql, [req.params.categoryId], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ count: results.length, products: results });
    });
});

// POST create product
app.post('/api/products', (req, res) => {
    const { name, description, price, unit, stock, image_url, category_id } = req.body;
    if (!name || !price || !category_id) {
        return res.status(400).json({ error: 'name, price, and category_id are required' });
    }
    const sql = 'INSERT INTO products (name, description, price, unit, stock, image_url, category_id) VALUES (?, ?, ?, ?, ?, ?, ?)';
    db.query(sql, [name, description, price, unit || 'each', stock || 0, image_url || null, category_id], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(201).json({ message: 'Product created', id: result.insertId });
    });
});

// ── CATEGORIES ────────────────────────────────────────────────

app.get('/api/categories', (req, res) => {
    db.query('SELECT * FROM categories ORDER BY id', (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ count: results.length, categories: results });
    });
});

// ── USERS ────────────────────────────────────────────────────

app.get('/api/users', (req, res) => {
    const sql = `
        SELECT id, username, email, first_name, last_name,
               phone, role, is_active, created_at
        FROM users ORDER BY id
    `;
    db.query(sql, (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ count: results.length, users: results });
    });
});

// ── ORDERS ───────────────────────────────────────────────────

// GET all orders
app.get('/api/orders', (req, res) => {
    const sql = `
        SELECT o.id, u.username, u.email,
               o.total_amount, o.status, o.payment_method,
               o.payment_status, o.delivery_address, o.created_at
        FROM orders o
        JOIN users u ON u.id = o.user_id
        ORDER BY o.created_at DESC
    `;
    db.query(sql, (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ count: results.length, orders: results });
    });
});

// GET single order with items
app.get('/api/orders/:id', (req, res) => {
    const orderSql = `
        SELECT o.id, u.username, u.email, o.total_amount,
               o.status, o.payment_status, o.delivery_address,
               o.delivery_notes, o.created_at
        FROM orders o JOIN users u ON u.id = o.user_id
        WHERE o.id = ?
    `;
    const itemsSql = `
        SELECT oi.id, p.name AS product, p.unit, oi.quantity,
               oi.unit_price, (oi.quantity * oi.unit_price) AS subtotal
        FROM order_items oi
        JOIN products p ON p.id = oi.product_id
        WHERE oi.order_id = ?
    `;
    db.query(orderSql, [req.params.id], (err, orderRows) => {
        if (err) return res.status(500).json({ error: err.message });
        if (orderRows.length === 0) return res.status(404).json({ error: 'Order not found' });
        db.query(itemsSql, [req.params.id], (err2, itemRows) => {
            if (err2) return res.status(500).json({ error: err2.message });
            res.json({ order: orderRows[0], items: itemRows });
        });
    });
});

// POST create order
app.post('/api/orders', (req, res) => {
    const { user_id, total_amount, payment_method, delivery_address, delivery_notes, items } = req.body;
    if (!user_id || !total_amount || !items || items.length === 0) {
        return res.status(400).json({ error: 'user_id, total_amount, and items[] are required' });
    }
    const orderSql = 'INSERT INTO orders (user_id, total_amount, payment_method, delivery_address, delivery_notes) VALUES (?, ?, ?, ?, ?)';
    db.query(orderSql, [user_id, total_amount, payment_method || 'card', delivery_address || '', delivery_notes || ''], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        const orderId = result.insertId;
        const itemValues = items.map(i => [orderId, i.product_id, i.quantity, i.unit_price]);
        db.query('INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES ?', [itemValues], (err2) => {
            if (err2) return res.status(500).json({ error: err2.message });
            res.status(201).json({ message: 'Order created successfully', order_id: orderId });
        });
    });
});

// ── CART ─────────────────────────────────────────────────────

// GET cart for a user
app.get('/api/cart/:userId', (req, res) => {
    const sql = `
        SELECT ci.id, p.name AS product, p.unit, p.price,
               ci.quantity, (p.price * ci.quantity) AS subtotal
        FROM cart ca
        JOIN cart_items ci ON ci.cart_id = ca.id
        JOIN products p    ON p.id = ci.product_id
        WHERE ca.user_id = ?
        ORDER BY ci.added_at
    `;
    db.query(sql, [req.params.userId], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        const total = results.reduce((sum, r) => sum + parseFloat(r.subtotal), 0);
        res.json({
            user_id    : req.params.userId,
            items      : results,
            item_count : results.length,
            cart_total : total.toFixed(2)
        });
    });
});

// POST add item to cart
app.post('/api/cart/:userId', (req, res) => {
    const { product_id, quantity } = req.body;
    if (!product_id) return res.status(400).json({ error: 'product_id is required' });

    // Get or create cart for user
    db.query('INSERT IGNORE INTO cart (user_id) VALUES (?)', [req.params.userId], (err) => {
        if (err) return res.status(500).json({ error: err.message });
        db.query('SELECT id FROM cart WHERE user_id = ?', [req.params.userId], (err2, cartRows) => {
            if (err2) return res.status(500).json({ error: err2.message });
            const cartId = cartRows[0].id;
            const sql = `
                INSERT INTO cart_items (cart_id, product_id, quantity)
                VALUES (?, ?, ?)
                ON DUPLICATE KEY UPDATE quantity = quantity + VALUES(quantity)
            `;
            db.query(sql, [cartId, product_id, quantity || 1], (err3) => {
                if (err3) return res.status(500).json({ error: err3.message });
                res.status(201).json({ message: 'Item added to cart' });
            });
        });
    });
});

// DELETE remove item from cart
app.delete('/api/cart/:userId/:productId', (req, res) => {
    const sql = `
        DELETE ci FROM cart_items ci
        JOIN cart ca ON ca.id = ci.cart_id
        WHERE ca.user_id = ? AND ci.product_id = ?
    `;
    db.query(sql, [req.params.userId, req.params.productId], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        if (result.affectedRows === 0) return res.status(404).json({ error: 'Item not found in cart' });
        res.json({ message: 'Item removed from cart' });
    });
});

// ── LOW STOCK ─────────────────────────────────────────────────

app.get('/api/low-stock', (req, res) => {
    db.query('SELECT * FROM v_low_stock', (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ count: results.length, low_stock_products: results });
    });
});

// ── START ─────────────────────────────────────────────────────
app.listen(PORT);
