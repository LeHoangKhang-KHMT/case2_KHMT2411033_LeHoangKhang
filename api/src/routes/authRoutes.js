const express = require('express');
const authController = require('../controllers/authController');
const { registerRules, handleValidation } = require('../validators/authValidator');

const router = express.Router();

router.post('/register', registerRules, handleValidation, authController.register);

module.exports = router;