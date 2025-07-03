const express = require('express');
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

const pool = mysql.createPool({
  host: process.env.DB_HOST || '127.0.0.1',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'recyclehub',
  port: 3306
});

// Test database connection
pool.getConnection()
  .then(conn => {
    console.log('Connected to MySQL database');
    conn.release();
  })
  .catch(err => {
    console.error('Failed to connect to MySQL:', err);
  });

// Middleware to verify JWT
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ message: 'Token required' });

  jwt.verify(token, process.env.JWT_SECRET || 'your_jwt_secret', (err, user) => {
    if (err) return res.status(403).json({ message: 'Invalid token' });
    req.user = user;
    next();
  });
};

// Register endpoint
app.post('/api/register', async (req, res) => {
  const { username, email, password } = req.body;
  console.log('Register attempt:', { username, email });
  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    await pool.execute(
      'INSERT INTO users (username, email, password) VALUES (?, ?, ?)',
      [username, email, hashedPassword]
    );
    console.log('User registered:', email);
    res.status(201).json({ message: 'User registered successfully' });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ message: 'Error registering user', error: error.message });
  }
});

// Login endpoint
app.post('/api/login', async (req, res) => {
  const { email, password } = req.body;
  console.log('Login attempt:', { email });
  try {
    const [rows] = await pool.execute('SELECT * FROM users WHERE email = ?', [email]);
    console.log('Database query result:', rows);
    const user = rows[0];
    if (!user || !(await bcrypt.compare(password, user.password))) {
      console.log('Invalid credentials for:', email);
      return res.status(401).json({ message: 'Invalid credentials' });
    }
    const token = jwt.sign({ id: user.id, email: user.email }, process.env.JWT_SECRET || 'your_jwt_secret', {
      expiresIn: '1h',
    });
    console.log('Login successful for:', email);
    res.json({ token, user: { id: user.id, username: user.username, email: user.email } });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Error logging in', error: error.message });
  }
});

// Get all products
app.get('/api/products', async (req, res) => {
  try {
    const [rows] = await pool.execute('SELECT * FROM products');
    res.json(rows);
  } catch (error) {
    console.error('Products error:', error);
    res.status(500).json({ message: 'Error fetching products', error: error.message });
  }
});

// Create order
app.post('/api/orders', authenticateToken, async (req, res) => {
  const { product_id, customer_name, customer_email, customer_phone, location, order_id, amount } = req.body;
  console.log('Order attempt:', { product_id, customer_email });
  try {
    await pool.execute(
      'INSERT INTO orders (user_id, product_id, customer_name, customer_email, customer_phone, location, order_id, amount, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [req.user.id, product_id, customer_name, customer_email, customer_phone, location, order_id, amount, 'pending']
    );
    console.log('Order created for user:', req.user.id);
    res.status(201).json({ message: 'Order created successfully' });
  } catch (error) {
    console.error('Order error:', error);
    res.status(500).json({ message: 'Error creating order', error: error.message });
  }
});

// Update order status
app.put('/api/orders/:order_id', async (req, res) => {
  const { status } = req.body;
  console.log('Update order status:', { order_id: req.params.order_id, status });
  try {
    await pool.execute('UPDATE orders SET status = ? WHERE order_id = ?', [status, req.params.order_id]);
    console.log('Order status updated:', req.params.order_id);
    res.json({ message: 'Order status updated' });
  } catch (error) {
    console.error('Update order error:', error);
    res.status(500).json({ message: 'Error updating order status', error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));