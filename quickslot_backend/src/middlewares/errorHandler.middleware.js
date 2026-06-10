/**
 * Global Error Handler Middleware
 */
function errorHandler(err, req, res, next) {
  console.error('Unhandled Error:', err);

  // PostgreSQL error code 23505 is Unique Violation (e.g., double booking check)
  if (err.code === '23505') {
    return res.status(409).json({
      error: 'Conflict',
      message: 'This slot has already been booked by another user.',
    });
  }

  // PostgreSQL error code 23503 is Foreign Key Violation (e.g., venue_id doesn't exist)
  if (err.code === '23503') {
    return res.status(400).json({
      error: 'Bad Request',
      message: 'Referenced record does not exist (e.g., invalid venue_id).',
    });
  }

  res.status(500).json({ error: 'Internal server error', message: err.message });
}

module.exports = {
  errorHandler,
};
