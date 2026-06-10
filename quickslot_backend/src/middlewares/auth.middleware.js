/**
 * Simple Authentication Middleware
 * Checks for the presence of the X-User-Id header.
 */
function requireAuth(req, res, next) {
  const userId = req.headers['x-user-id'];
  if (!userId) {
    return res.status(401).json({ error: 'Unauthorized', message: 'X-User-Id header is required' });
  }
  req.userId = userId;
  next();
}

module.exports = {
  requireAuth,
};
