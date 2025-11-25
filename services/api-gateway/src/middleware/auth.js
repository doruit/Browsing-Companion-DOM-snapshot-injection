const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'demo-secret-key-change-in-production';

// Mock user database for demo purposes
const MOCK_USERS = {
  'user1@example.com': {
    id: 'user1',
    email: 'user1@example.com',
    password: 'password1', // In production, use hashed passwords
    name: 'John Doe'
  },
  'user2@example.com': {
    id: 'user2',
    email: 'user2@example.com',
    password: 'password2',
    name: 'Jane Smith'
  },
  'b2b@company.com': {
    id: 'b2b-user',
    email: 'b2b@company.com',
    password: 'b2bpass',
    name: 'Business Customer'
  }
};

// Mock token storage (in production, use Redis or similar)
const VALID_TOKENS = new Set([
  'user1-token',
  'user2-token',
  'b2b-token'
]);

/**
 * Middleware to authenticate JWT tokens
 */
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  // For demo purposes, accept mock tokens
  if (VALID_TOKENS.has(token)) {
    // Map mock token to user
    const userMap = {
      'user1-token': 'user1',
      'user2-token': 'user2',
      'b2b-token': 'b2b-user'
    };
    req.user = { userId: userMap[token] };
    return next();
  }

  // Verify JWT
  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid or expired token' });
    }
    req.user = user;
    next();
  });
}

/**
 * Login endpoint handler
 */
function login(req, res) {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password required' });
  }

  const user = MOCK_USERS[email];
  
  if (!user || user.password !== password) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }

  // Generate JWT
  const token = jwt.sign(
    { userId: user.id, email: user.email },
    JWT_SECRET,
    { expiresIn: '24h' }
  );

  res.json({
    token,
    user: {
      id: user.id,
      email: user.email,
      name: user.name
    }
  });
}

module.exports = {
  authenticateToken,
  login,
  MOCK_USERS
};
