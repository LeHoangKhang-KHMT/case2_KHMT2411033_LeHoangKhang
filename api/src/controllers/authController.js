const bcrypt = require('bcryptjs');
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