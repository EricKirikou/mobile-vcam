const crypto = require('crypto');
const env = require('../config/env');
const logger = require('../config/logger');

class TurnService {
  /**
   * Generates ephemeral TURN credentials using HMAC-SHA1
   * According to standard TURN REST API (RFC 5766)
   */
  generateIceServers(userId) {
    const ttlSeconds = 24 * 3600; // 24 hours validity
    const timestamp = Math.floor(Date.now() / 1000) + ttlSeconds;
    const username = `${timestamp}:${userId || 'anonymous'}`;

    const hmac = crypto.createHmac('sha1', env.TURN_SECRET);
    hmac.update(username);
    const password = hmac.digest('base64');

    const iceServers = [
      // Public Google STUN servers
      {
        urls: env.STUN_SERVERS
      },
      // Authenticated TURN relay servers (UDP, TCP, and TLS)
      {
        urls: [
          `turn:${env.TURN_DOMAIN}:${env.TURN_PORT}?transport=udp`,
          `turn:${env.TURN_DOMAIN}:${env.TURN_PORT}?transport=tcp`
        ],
        username: username,
        credential: password
      },
      // Secure TURNS over TLS port 5349 (Bypasses restrictive enterprise firewalls)
      {
        urls: [
          `turns:${env.TURN_DOMAIN}:${env.TURN_TLS_PORT}?transport=tcp`
        ],
        username: username,
        credential: password
      }
    ];

    logger.debug(`Generated ICE servers for user ${userId} with expiry ${new Date(timestamp * 1000).toISOString()}`);

    return {
      iceServers,
      iceTransportPolicy: 'all', // 'all' tries direct P2P first, then relays via TURN
      ttl: ttlSeconds
    };
  }
}

module.exports = new TurnService();
