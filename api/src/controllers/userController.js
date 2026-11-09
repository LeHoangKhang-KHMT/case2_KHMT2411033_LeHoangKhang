const User = require('../models/User');
const { isValidId } = require('../services/taskService');

const escapeRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const toPublic = (u) => ({
  id: u._id,
  fullName: u.fullName,
  email: u.email,
  avatarUrl: u.avatarUrl,
});

exports.searchUsers = async (req, res, next) => {
  try {
    const q = String(req.query.q || '').trim();
    if (q.length < 2) return res.json({ users: [] });

    const rx = { $regex: escapeRegex(q), $options: 'i' };
    const users = await User.find({
      _id: { $ne: req.user._id },
      $or: [{ fullName: rx }, { email: rx }],
    })
      .select('fullName email avatarUrl')
      .limit(10);

    res.json({ users: users.map(toPublic) });
  } catch (err) {
    next(err);
  }
};

exports.getUser = async (req, res, next) => {
  try {
    if (!isValidId(req.params.id)) {
      return res.status(400).json({ message: 'Mã người dùng không hợp lệ' });
    }
    const user = await User.findById(req.params.id).select('fullName email avatarUrl');
    if (!user) return res.status(404).json({ message: 'Không tìm thấy người dùng' });
    res.json({ user: toPublic(user) });
  } catch (err) {
    next(err);
  }
};