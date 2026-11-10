const turnService = require('../services/turnService');

class TurnController {
  getIceServers(req, res, next) {
    try {
      const config = turnService.generateIceServers(req.user ? req.user._id : 'guest');
      res.status(200).json({
        success: true,
        data: config
      });
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new TurnController();
