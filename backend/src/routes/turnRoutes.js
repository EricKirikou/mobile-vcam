const express = require('express');
const router = express.Router();
const turnController = require('../controllers/turnController');
const { authenticate } = require('../middleware/auth');

/**
 * GET /api/ice-servers
 * Returns ephemeral TURN credentials and ICE server configuration.
 * Required by both Desktop and Mobile clients before establishing WebRTC connection.
 */
router.get('/',
  authenticate,
  turnController.getIceServers.bind(turnController)
);

module.exports = router;
