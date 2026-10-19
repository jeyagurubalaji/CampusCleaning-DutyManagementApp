const express = require('express');
const router = express.Router();
const { login, getMe, updateProfile, register } = require('../controllers/authController');
const { protect, authorize } = require('../middleware/auth');

router.post('/login', login);
router.get('/me', protect, getMe);
router.put('/profile', protect, updateProfile);
router.post('/register', protect, authorize('admin'), register);

module.exports = router;
