const express = require('express');
const authMiddleware = require('../middleware/auth');
const { customerHelpChat } = require('../controllers/aiController');

const router = express.Router();

router.use(authMiddleware);

router.post('/chat', customerHelpChat);

module.exports = router;

