function errorHandler(err, req, res, next) {
  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal server error';
  const clientIp = req.ip || req.connection.remoteAddress;
  const path = req.path || req.url;
  
  // Log error details
  if (statusCode >= 500) {
    console.error(`[ERROR] ${statusCode} - Path: ${path}, IP: ${clientIp}, Error: ${message}`, err.stack);
  } else {
    console.warn(`[ERROR] ${statusCode} - Path: ${path}, IP: ${clientIp}, Error: ${message}`);
  }
  
  res.status(statusCode).json({
    success: false,
    message,
    ...(err.code && { code: err.code }),
  });
}

module.exports = errorHandler;
