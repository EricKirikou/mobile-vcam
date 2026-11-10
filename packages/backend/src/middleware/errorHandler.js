const logger = require('../config/logger');
const env = require('../config/env');

const notFoundHandler = (req, res, next) => {
  res.status(404).json({
    success: false,
    error: `Route not found: ${req.method} ${req.originalUrl}`
  });
};

const globalErrorHandler = (err, req, res, next) => {
  logger.error(`Unhandled Error [${req.method} ${req.url}]: ${err.message}`, {
    stack: err.stack,
    body: req.body,
    ip: req.ip
  });

  const statusCode = err.statusCode || 500;
  const message = env.NODE_ENV === 'production' && statusCode === 500
    ? 'Internal Server Error'
    : err.message || 'An unexpected error occurred';

  res.status(statusCode).json({
    success: false,
    error: message,
    ...(env.NODE_ENV !== 'production' && { stack: err.stack })
  });
};

module.exports = { notFoundHandler, globalErrorHandler };
