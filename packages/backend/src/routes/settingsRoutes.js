const express = require('express');
const router = express.Router();
const Settings = require('../models/Settings');
const { authenticate } = require('../middleware/auth');

router.get('/', authenticate, async (req, res, next) => {
  try {
    let settings = await Settings.findOne({ userId: req.user._id });
    if (!settings) {
      settings = await Settings.create({ userId: req.user._id });
    }
    res.status(200).json({ success: true, data: settings });
  } catch (err) {
    next(err);
  }
});

router.patch('/', authenticate, async (req, res, next) => {
  try {
    const settings = await Settings.findOneAndUpdate(
      { userId: req.user._id },
      { $set: req.body },
      { new: true, upsert: true, runValidators: true }
    );
    res.status(200).json({ success: true, data: settings });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
