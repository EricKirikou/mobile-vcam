const Redis = require('ioredis');
const env = require('./env');
const logger = require('./logger');

let redisClient = null;
let isConnected = false;

// Fallback in-memory store if Redis is unavailable in local dev without Docker
const inMemoryStore = new Map();

try {
  redisClient = new Redis(env.REDIS_URL, {
    maxRetriesPerRequest: 2,
    retryStrategy: (times) => {
      if (times > 3) {
        logger.warn('Redis connection retry limit reached. Falling back to local memory store.');
        return null;
      }
      return Math.min(times * 100, 2000);
    },
    lazyConnect: true
  });

  redisClient.connect().then(() => {
    isConnected = true;
    logger.info('Connected to Redis server successfully.');
  }).catch((err) => {
    logger.warn(`Redis failed to connect initially (${err.message}). Using resilient in-memory fallback.`);
  });

  redisClient.on('error', (err) => {
    isConnected = false;
    logger.warn(`Redis connection error: ${err.message}`);
  });
} catch (e) {
  logger.warn(`Could not initialize Redis client: ${e.message}`);
}

const safeRedis = {
  async set(key, value, mode, duration) {
    if (isConnected && redisClient) {
      try {
        if (mode === 'EX' && duration) {
          return await redisClient.set(key, value, 'EX', duration);
        }
        return await redisClient.set(key, value);
      } catch (err) {
        logger.warn(`Redis set failed: ${err.message}. Using fallback.`);
      }
    }
    inMemoryStore.set(key, { value, expiresAt: duration ? Date.now() + duration * 1000 : null });
    return 'OK';
  },

  async get(key) {
    if (isConnected && redisClient) {
      try {
        return await redisClient.get(key);
      } catch (err) {
        logger.warn(`Redis get failed: ${err.message}. Using fallback.`);
      }
    }
    const item = inMemoryStore.get(key);
    if (!item) return null;
    if (item.expiresAt && Date.now() > item.expiresAt) {
      inMemoryStore.delete(key);
      return null;
    }
    return item.value;
  },

  async del(key) {
    if (isConnected && redisClient) {
      try {
        return await redisClient.del(key);
      } catch (err) {
        logger.warn(`Redis del failed: ${err.message}. Using fallback.`);
      }
    }
    return inMemoryStore.delete(key) ? 1 : 0;
  },

  isLive() {
    return isConnected;
  }
};

module.exports = safeRedis;
