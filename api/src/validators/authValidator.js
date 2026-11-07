const { body, validationResult } = require('express-validator');

exports.registerRules = [
  body('fullName').trim().notEmpty().withMessage('Ho ten khong duoc de trong'),
  body('email').isEmail().withMessage('Email khong hop le'),
  body('password').isLength({ min: 6 }).withMessage('Mat khau toi thieu 6 ky tu'),
];

exports.loginRules = [
  body('email').isEmail().withMessage('Email khong hop le'),
  body('password').notEmpty().withMessage('Vui long nhap mat khau'),
];

exports.updateMeRules = [
  body('fullName').optional().trim().notEmpty().withMessage('Họ tên không được để trống'),
];

exports.handleValidation = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ message: errors.array()[0].msg });
  }
  next();
};