const jwt = require('jsonwebtoken');
const User = require('../models/User');

module.exports = async (req, res, next) => {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) {
      return res.status(401).json({ message: 'Chưa đăng nhập' });
    }

    const payload = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(payload.id);
    if (!user) {
      return res.status(401).json({ message: 'Tài khoản không tồn tại' });
    }

    req.user = user;
    next();
  } catch (err) {
    res.status(401).json({ message: 'Token không hợp lệ hoặc đã hết hạn' });
  }
};