const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authenticate } = require('../middleware/auth');
const { authLimiter } = require('../middleware/rateLimiter');
const { validateRequestBody } = require('../middleware/validator');

router.post('/register',
  authLimiter,
  validateRequestBody(['email', 'password', 'name']),
  authController.register.bind(authController)
);

router.post('/login',
  authLimiter,
  validateRequestBody(['email', 'password']),
  authController.login.bind(authController)
);

router.post('/google',
  authLimiter,
  validateRequestBody(['googleId', 'email']),
  authController.googleAuth.bind(authController)
);

router.post('/refresh',
  authLimiter,
  validateRequestBody(['refreshToken']),
  authController.refreshToken.bind(authController)
);

router.post('/logout',
  authenticate,
  authController.logout.bind(authController)
);

router.get('/profile',
  authenticate,
  authController.getProfile.bind(authController)
);

module.exports = router;
