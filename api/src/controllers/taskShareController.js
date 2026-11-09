const User = require('../models/User');
const TaskShare = require('../models/TaskShare');
const taskService = require('../services/taskService');
const notificationService = require('../services/notificationService');

const PERMISSIONS = ['viewer', 'editor'];

const normalizeEmails = (v) => [
  ...new Set(
    (Array.isArray(v) ? v : [])
      .map((e) => String(e).trim().toLowerCase())
      .filter(Boolean)
  ),
];

const buildList = async (taskId) => {
  const shares = await TaskShare.find({ taskId })
    .populate('userId', 'fullName email avatarUrl')
    .sort({ createdAt: 1 });

  return shares
    .filter((s) => s.userId)
    .map((s) => ({
      id: s._id,
      permission: s.permission,
      createdAt: s.createdAt,
      user: {
        id: s.userId._id,
        fullName: s.userId.fullName,
        email: s.userId.email,
        avatarUrl: s.userId.avatarUrl,
      },
    }));
};

exports.list = async (req, res, next) => {
  try {
    const ctx = await taskService.loadTask(req, res);
    if (!ctx) return;
    res.json({ shares: await buildList(ctx.task._id) });
  } catch (err) {
    next(err);
  }
};

exports.add = async (req, res, next) => {
  try {
    const ctx = await taskService.loadTask(req, res, true);
    if (!ctx) return;
    const { task } = ctx;

    const permission = req.body.permission || 'viewer';
    if (!PERMISSIONS.includes(permission)) {
      return res.status(400).json({ message: 'Quyền không hợp lệ (viewer hoặc editor)' });
    }

    const emails = normalizeEmails(req.body.emails);
    if (emails.length === 0) {
      return res.status(400).json({ message: 'Vui lòng nhập ít nhất một email' });
    }

    const users = await User.find({ email: { $in: emails } });
    const found = new Set(users.map((u) => u.email));
    const notFound = emails.filter((e) => !found.has(e));

    // Không chia sẻ cho chính người tạo
    const targets = users.filter((u) => String(u._id) !== String(task.createdBy));

    const changed = [];
    for (const u of targets) {
      const existing = await TaskShare.findOne({ taskId: task._id, userId: u._id });
      if (!existing || existing.permission !== permission) changed.push(u);

      await TaskShare.findOneAndUpdate(
        { taskId: task._id, userId: u._id },
        { permission, sharedBy: req.user._id },
        { upsert: true, new: true, setDefaultsOnInsert: true }
      );
    }

    if (changed.length > 0) {
      const label = permission === 'editor' ? 'chỉnh sửa' : 'chỉ xem';
      notificationService
        .notifyUsers({
          actor: req.user,
          users: changed,
          task,
          type: 'task_shared',
          title: 'Bạn được mời tham gia công việc',
          message: `${req.user.fullName} đã chia sẻ công việc "${task.title}" với quyền ${label}.`,
        })
        .catch(console.error);
    }

    res.json({
      message: 'Chia sẻ thành công',
      shares: await buildList(task._id),
      notFound,
    });
  } catch (err) {
    next(err);
  }
};

exports.update = async (req, res, next) => {
  try {
    const ctx = await taskService.loadTask(req, res, true);
    if (!ctx) return;
    const { task } = ctx;
    const { shareId } = req.params;

    if (!taskService.isValidId(shareId)) {
      return res.status(400).json({ message: 'Mã chia sẻ không hợp lệ' });
    }
    if (!PERMISSIONS.includes(req.body.permission)) {
      return res.status(400).json({ message: 'Quyền không hợp lệ (viewer hoặc editor)' });
    }

    const share = await TaskShare.findOne({ _id: shareId, taskId: task._id });
    if (!share) {
      return res.status(404).json({ message: 'Không tìm thấy bản ghi chia sẻ' });
    }

    share.permission = req.body.permission;
    await share.save();

    res.json({ message: 'Đã đổi quyền', shares: await buildList(task._id) });
  } catch (err) {
    next(err);
  }
};

exports.remove = async (req, res, next) => {
  try {
    const ctx = await taskService.loadTask(req, res, true);
    if (!ctx) return;
    const { task } = ctx;
    const { shareId } = req.params;

    if (!taskService.isValidId(shareId)) {
      return res.status(400).json({ message: 'Mã chia sẻ không hợp lệ' });
    }

    const share = await TaskShare.findOneAndDelete({ _id: shareId, taskId: task._id });
    if (!share) {
      return res.status(404).json({ message: 'Không tìm thấy bản ghi chia sẻ' });
    }

    res.json({ message: 'Đã thu hồi quyền chia sẻ', shares: await buildList(task._id) });
  } catch (err) {
    next(err);
  }
};