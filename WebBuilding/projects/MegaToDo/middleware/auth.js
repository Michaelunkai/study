const jwt = require('jsonwebtoken');
const { get } = require('../db/init');

const JWT_SECRET = process.env.JWT_SECRET || 'megatodo-secret-change-in-production';

if (process.env.NODE_ENV === 'production' && !process.env.JWT_SECRET) {
  throw new Error('JWT_SECRET environment variable must be set in production');
}

async function authMiddleware(req, res, next) {
  // Whitelist auth routes (use originalUrl so this works both at top-level and inside sub-routers)
  if (req.originalUrl.startsWith('/api/auth') || req.originalUrl === '/api/health') {
    return next();
  }

  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Authentication required' });
  }

  const token = authHeader.substring(7);

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const user = await get('SELECT id, name, email, karma, theme FROM users WHERE id = ?', [decoded.userId]);
    if (!user) {
      return res.status(401).json({ error: 'User not found' });
    }
    req.user = user;
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token expired' });
    }
    return res.status(401).json({ error: 'Invalid token' });
  }
}

function generateToken(userId) {
  return jwt.sign({ userId }, JWT_SECRET, { expiresIn: '7d' });
}

module.exports = { authMiddleware, generateToken, JWT_SECRET };
