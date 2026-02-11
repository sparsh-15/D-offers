function errorHandler(err, req, res, next) {
  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal server error';
  res.status(statusCode).json({
    success: false,
    message,
    ...(err.code && { code: err.code }),
  });
}

module.exports = errorHandler;
