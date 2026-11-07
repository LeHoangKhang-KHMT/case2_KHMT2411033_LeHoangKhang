const express = require('express');
const authController = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');
const {
  registerRules,
  loginRules,
  updateMeRules,
  changePasswordRules,
  handleValidation,
} = require('../validators/authValidator');

const router = express.Router();

router.post('/register', registerRules, handleValidation, authController.register);
router.post('/login', loginRules, handleValidation, authController.login);

router.get('/me', authMiddleware, authController.getMe);
router.put('/me', authMiddleware, updateMeRules, handleValidation, authController.updateMe);
router.put(
  '/change-password',
  authMiddleware,
  changePasswordRules,
  handleValidation,
  authController.changePassword
);

module.exports = router;