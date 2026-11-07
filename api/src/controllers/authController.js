const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const toPublicUser = (u) => ({
  id: u._id,
  fullName: u.fullName,
  email: u.email,
  avatarUrl: u.avatarUrl,
});

exports.register = async (req, res, next) => {
  try {
    const { fullName, email, password } = req.body;

    const existing = await User.findOne({ email: email.toLowerCase() });
    if (existing) {
      return res.status(409).json({ message: 'Email da duoc su dung' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const user = await User.create({ fullName, email, passwordHash });

    res.status(201).json({ message: 'Dang ky thanh cong', user: toPublicUser(user) });
  } catch (err) {
    next(err);
  }
};

exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email: email.toLowerCase() });
    const ok = user && (await bcrypt.compare(password, user.passwordHash));
    if (!ok) {
      return res.status(401).json({ message: 'Email hoac mat khau khong dung' });
    }

    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, {
      expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    });

    res.json({ message: 'Dang nhap thanh cong', token, user: toPublicUser(user) });
  } catch (err) {
    next(err);
  }
};

exports.getMe = async (req, res) => {
  res.json({ user: toPublicUser(req.user) });
};

exports.updateMe = async (req, res, next) => {
  try {
    const { fullName, avatarUrl } = req.body;
    if (fullName !== undefined) req.user.fullName = fullName;
    if (avatarUrl !== undefined) req.user.avatarUrl = avatarUrl;
    await req.user.save();
    res.json({ message: 'Cập nhật thành công', user: toPublicUser(req.user) });
  } catch (err) {
    next(err);
  }
};