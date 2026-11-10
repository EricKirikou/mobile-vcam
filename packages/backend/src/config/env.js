const dotenv = require('dotenv');
dotenv.config();

module.exports = {
  NODE_ENV: process.env.NODE_ENV || 'development',
  PORT: parseInt(process.env.PORT, 10) || 5000,
  HOST: process.env.HOST || '0.0.0.0',
  MONGO_URI: process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/mobile_virtual_camera',
  REDIS_URL: process.env.REDIS_URL || 'redis://127.0.0.1:6379',
  JWT_SECRET: process.env.JWT_SECRET || 'super_secret_jwt_key_virtual_camera_2026_xyz',
  JWT_EXPIRES_IN: process.env.JWT_EXPIRES_IN || '15m',
  REFRESH_TOKEN_SECRET: process.env.REFRESH_TOKEN_SECRET || 'refresh_secret_virtual_camera_2026_long_term',
  REFRESH_TOKEN_EXPIRES_IN: process.env.REFRESH_TOKEN_EXPIRES_IN || '30d',
  
  // STUN / TURN Configuration
  TURN_DOMAIN: process.env.TURN_DOMAIN || 'turn.virtualcam.local',
  TURN_SECRET: process.env.TURN_SECRET || 'turn_shared_secret_4490123487612',
  TURN_PORT: parseInt(process.env.TURN_PORT, 10) || 3478,
  TURN_TLS_PORT: parseInt(process.env.TURN_TLS_PORT, 10) || 5349,
  STUN_SERVERS: process.env.STUN_SERVERS ? process.env.STUN_SERVERS.split(',') : [
    'stun:stun.l.google.com:19302',
    'stun:stun1.l.google.com:19302'
  ],
  
  // Rate limiting & Security
  RATE_LIMIT_WINDOW_MS: 15 * 60 * 1000, // 15 mins
  RATE_LIMIT_MAX: parseInt(process.env.RATE_LIMIT_MAX, 10) || 100,
  CORS_ORIGIN: process.env.CORS_ORIGIN ? process.env.CORS_ORIGIN.split(',') : ['http://localhost:3000', 'http://127.0.0.1:3000'],
  FILE_UPLOAD_PATH: process.env.FILE_UPLOAD_PATH || './uploads',
  MAX_FILE_SIZE_BYTES: 100 * 1024 * 1024 // 100MB
};
