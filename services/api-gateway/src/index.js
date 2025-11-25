require('dotenv').config({ path: '.env.local' });
const express = require('express');
const bodyParser = require('body-parser');
const morgan = require('morgan');
const corsMiddleware = require('./middleware/cors');
const { authenticateToken, login } = require('./middleware/auth');

// Import routes
const chatRoutes = require('./routes/chat');
const productsRoutes = require('./routes/products');
const preferencesRoutes = require('./routes/preferences');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(morgan('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(corsMiddleware);

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy',
    service: 'API Gateway',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

// Public endpoints
app.post('/api/auth/login', login);

// Protected endpoints (require authentication)
app.use('/api/chat', authenticateToken, chatRoutes);
app.use('/api/products', authenticateToken, productsRoutes);
app.use('/api/preferences', authenticateToken, preferencesRoutes);

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    service: 'Browsing Companion API Gateway',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      login: 'POST /api/auth/login',
      chat: 'POST /api/chat',
      products: 'GET /api/products',
      preferences: 'GET /api/preferences'
    }
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err.message);
  res.status(err.status || 500).json({
    error: err.message || 'Internal server error'
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Start server
app.listen(PORT, () => {
  console.log(`API Gateway running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`AI Service URL: ${process.env.AI_SERVICE_URL || 'http://localhost:8000'}`);
});

module.exports = app;
