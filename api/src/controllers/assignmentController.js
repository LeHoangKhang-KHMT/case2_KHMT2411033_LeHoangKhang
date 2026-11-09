const User = require('../models/User');
const taskService = require('../services/taskService');
const notificationService = require('../services/notificationService');

const normalizeEmails = (v) => [
  ...new Set(
    (Array.isArray(v) ? v : [])
      .map((e) => String(e).trim().toLowerCase())
      .filter(Boolean)
  ),
];

const buildList = async (task) => {
  const users = await User.find({ _id: { $in: task.assigneeIds } }).select(
    'fullName email avatarUrl'
  );
  const primary = task.primaryAssigneeId ? String(task.primaryAssigneeId) : null;
  return users.map((u) => ({
    id: u._id,
    fullName: u.fullName,
    email: u.email,
    avatarUrl: u.avatarUrl,
    isPrimary: String(u._id) === primary,
  }));
};

exports.list = async (req, res, next) => {
  try {
    const ctx = await taskService.loadTask(req, res);
    if (!ctx) return;
    res.json({ assignees: await buildList(ctx.task) });
  } catch (err) {
    next(err);
  }
};

exports.add = async (req, res, next) => {
  try {
    const ctx = await taskService.loadTask(req, res, true);
    if (!ctx) return;
    const { task } = ctx;

    const emails = normalizeEmails(req.body.emails);
    if (emails.length === 0) {
      return res.status(400).json({ message: 'Vui lòng nhập ít nhất một email' });
    }

    const users = await User.find({ email: { $in: emails } });
    const found = new Set(users.map((u) => u.email));
    const notFound = emails.filter((e) => !found.has(e));

    const added = [];
    for (const u of users) {
      if (!task.assigneeIds.some((a) => String(a) === String(u._id))) {
        task.assigneeIds.push(u._id);
        added.push(u);
      }
    }
    await task.save();

    if (added.length > 0) {
      notificationService
        .notifyUsers({
          actor: req.user,
          users: added,
          task,
          type: 'task_assigned',
          title: 'Bạn được giao công việc mới',
          message: `${req.user.fullName} đã giao cho bạn công việc "${task.title}".`,
        })
        .catch(console.error);
    }

    res.json({
      message: 'Giao việc thành công',
      assignees: await buildList(task),
      notFound,
    });
  } catch (err) {
    next(err);
  }
};

exports.setPrimary = async (req, res, next) => {
  try {
    const ctx = await taskService.loadTask(req, res, true);
    if (!ctx) return;
    const { task } = ctx;
    const { userId } = req.params;

    if (!taskService.isValidId(userId)) {
      return res.status(400).json({ message: 'Mã người dùng không hợp lệ' });
    }
    if (!task.assigneeIds.some((a) => String(a) === userId)) {
      return res.status(404).json({ message: 'Người dùng chưa được giao việc này' });
    }

    if (req.body.isPrimary !== false) {
      task.primaryAssigneeId = userId;
    } else if (task.primaryAssigneeId && String(task.primaryAssigneeId) === userId) {
      task.primaryAssigneeId = null;
    }
    await task.save();

    res.json({ message: 'Cập nhật người phụ trách thành công', assignees: await buildList(task) });
  } catch (err) {
    next(err);
  }
};

exports.remove = async (req, res, next) => {
  try {
    const ctx = await taskService.loadTask(req, res, true);
    if (!ctx) return;
    const { task } = ctx;
    const { userId } = req.params;

    if (!taskService.isValidId(userId)) {
      return res.status(400).json({ message: 'Mã người dùng không hợp lệ' });
    }

    task.assigneeIds = task.assigneeIds.filter((a) => String(a) !== userId);
    if (task.primaryAssigneeId && String(task.primaryAssigneeId) === userId) {
      task.primaryAssigneeId = null;
    }
    await task.save();

    res.json({ message: 'Đã hủy giao việc', assignees: await buildList(task) });
  } catch (err) {
    next(err);
  }
};