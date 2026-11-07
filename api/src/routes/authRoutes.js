const express = require('express');
const authController = require('../controllers/authController');
const {
  registerRules,
  loginRules,
  handleValidation,
} = require('../validators/authValidator');

const router = express.Router();

router.post('/register', registerRules, handleValidation, authController.register);
router.post('/login', loginRules, handleValidation, authController.login);

module.exports = router;