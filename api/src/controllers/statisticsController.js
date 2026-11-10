const Task = require('../models/Task');
const TaskShare = require('../models/TaskShare');

const emptyStatus = () => ({ todo: 0, in_progress: 0, completed: 0 });

// Công việc người dùng có quyền truy cập (tạo, được giao, được chia sẻ)
async function accessibleFilter(userId) {
  const shares = await TaskShare.find({ userId }).select('taskId');
  return {
    $or: [
      { createdBy: userId },
      { assigneeIds: userId },
      { _id: { $in: shares.map((s) => s.taskId) } },
    ],
  };
}

async function statusCounts(filter) {
  const rows = await Task.aggregate([
    { $match: filter },
    { $group: { _id: '$status', count: { $sum: 1 } } },
  ]);
  const out = emptyStatus();
  rows.forEach((r) => {
    if (r._id in out) out[r._id] = r.count;
  });
  out.total = out.todo + out.in_progress + out.completed;
  return out;
}

exports.tasks = async (req, res, next) => {
  try {
    const filter = await accessibleFilter(req.user._id);
    const byStatus = await statusCounts(filter);

    const rows = await Task.aggregate([
      { $match: filter },
      { $group: { _id: '$priority', count: { $sum: 1 } } },
    ]);
    const byPriority = { low: 0, medium: 0, high: 0 };
    rows.forEach((r) => {
      if (r._id in byPriority) byPriority[r._id] = r.count;
    });

    res.json({ total: byStatus.total, byStatus, byPriority });
  } catch (err) {
    next(err);
  }
};

exports.assignments = async (req, res, next) => {
  try {
    const me = req.user._id;
    const [assigned, primary, created] = await Promise.all([
      statusCounts({ assigneeIds: me }),
      statusCounts({ primaryAssigneeId: me }),
      statusCounts({ createdBy: me }),
    ]);
    res.json({ assigned, primary, created });
  } catch (err) {
    next(err);
  }
};

exports.deadlines = async (req, res, next) => {
  try {
    const filter = await accessibleFilter(req.user._id);
    const open = { $and: [filter, { status: { $ne: 'completed' } }] };

    const startToday = new Date();
    startToday.setHours(0, 0, 0, 0);
    const soonLimit = new Date(startToday.getTime() + 8 * 24 * 3600 * 1000);

    const overdueFilter = { $and: [open, { dueDate: { $lt: startToday } }] };
    const soonFilter = { $and: [open, { dueDate: { $gte: startToday, $lt: soonLimit } }] };
    const fields = 'title dueDate priority status';

    const [overdue, dueSoon, overdueCount, dueSoonCount, noDueCount] = await Promise.all([
      Task.find(overdueFilter).sort({ dueDate: 1 }).limit(20).select(fields),
      Task.find(soonFilter).sort({ dueDate: 1 }).limit(20).select(fields),
      Task.countDocuments(overdueFilter),
      Task.countDocuments(soonFilter),
      Task.countDocuments({ $and: [open, { dueDate: null }] }),
    ]);

    res.json({ overdueCount, dueSoonCount, noDueCount, overdue, dueSoon });
  } catch (err) {
    next(err);
  }
};