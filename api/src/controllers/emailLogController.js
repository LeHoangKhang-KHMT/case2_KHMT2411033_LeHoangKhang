const EmailLog = require('../models/EmailLog');
const Task = require('../models/Task');
const taskService = require('../services/taskService');
const emailService = require('../services/emailService');

exports.listByTask = async (req, res, next) => {
  try {
    const ctx = await taskService.loadTask(req, res, true);
    if (!ctx) return;
    const logs = await EmailLog.find({ taskId: ctx.task._id })
      .sort({ createdAt: -1 })
      .limit(50)
      .select('-body');
    res.json({ logs });
  } catch (err) {
    next(err);
  }
};

exports.retry = async (req, res, next) => {
  try {
    if (!taskService.isValidId(req.params.id)) {
      return res.status(400).json({ message: 'Mã email không hợp lệ' });
    }
    const log = await EmailLog.findById(req.params.id);
    if (!log) return res.status(404).json({ message: 'Không tìm thấy email' });

    const task = log.taskId ? await Task.findById(log.taskId) : null;
    if (!task || String(task.createdBy) !== String(req.user._id)) {
      return res.status(403).json({ message: 'Bạn không có quyền gửi lại email này' });
    }
    if (log.status !== 'failed') {
      return res.status(400).json({ message: 'Chỉ có thể gửi lại email thất bại' });
    }
    if (log.attempts >= emailService.MAX_ATTEMPTS) {
      return res.status(400).json({ message: 'Đã vượt quá số lần gửi lại cho phép' });
    }

    const updated = await emailService.retry(log);
    res.json({
      message: updated.status === 'sent' ? 'Gửi lại thành công' : 'Gửi lại thất bại',
      log: { id: updated._id, status: updated.status, attempts: updated.attempts },
    });
  } catch (err) {
    next(err);
  }
};