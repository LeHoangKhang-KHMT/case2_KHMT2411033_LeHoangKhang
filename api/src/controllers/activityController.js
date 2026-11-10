const TaskActivity = require('../models/TaskActivity');
const taskService = require('../services/taskService');

exports.list = async (req, res, next) => {
  try {
    const ctx = await taskService.loadTask(req, res);
    if (!ctx) return;

    const items = await TaskActivity.find({ taskId: ctx.task._id })
      .populate('userId', 'fullName')
      .sort({ createdAt: -1 })
      .limit(100);

    res.json({
      activities: items.map((a) => ({
        id: a._id,
        action: a.action,
        details: a.details || {},
        createdAt: a.createdAt,
        user: { id: a.userId ? a.userId._id : null, fullName: a.userId ? a.userId.fullName : 'Người dùng đã xóa' },
      })),
    });
  } catch (err) {
    next(err);
  }
};