const winston = require('winston');
const env = require('./env');

const logger = winston.createLogger({
  level: env.NODE_ENV === 'production' ? 'info' : 'debug',
  format: winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.errors({ stack: true }),
    winston.format.splat(),
    winston.format.json()
  ),
  defaultMeta: { service: 'mobile-virtual-camera-backend' },
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.printf(
          info => `[${info.timestamp}] [${info.level}] [${info.service}]: ${info.message}${info.stack ? '\n' + info.stack : ''}`
        )
      )
    })
  ]
});

module.exports = logger;
