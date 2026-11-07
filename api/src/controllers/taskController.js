const Task = require('../models/Task');
const taskService = require('../services/taskService');

exports.createTask = async (req, res, next) => {
  try {
    const { title, description, priority, startDate, dueDate } = req.body;

    const task = await Task.create({
      title,
      description,
      priority,
      startDate: startDate || null,
      dueDate: dueDate || null,
      createdBy: req.user._id,
    });

    res.status(201).json({ message: 'Tạo công việc thành công', task });
  } catch (err) {
    next(err);
  }
};

exports.listTasks = async (req, res, next) => {
  try {
    const scope = req.query.scope || 'all';
    const me = req.user._id;

    let filter;
    if (scope === 'created') {
      filter = { createdBy: me };
    } else if (scope === 'assigned') {
      filter = { assigneeIds: me };
    } else if (scope === 'shared') {
      // Nhóm C sẽ bổ sung: tìm theo bảng task_shares
      return res.json({ tasks: [] });
    } else if (scope === 'all') {
      filter = { $or: [{ createdBy: me }, { assigneeIds: me }] };
    } else {
      return res.status(400).json({ message: 'Phạm vi danh sách không hợp lệ' });
    }

    const tasks = await Task.find(filter).sort({ createdAt: -1 });
    res.json({ tasks });
  } catch (err) {
    next(err);
  }
};

exports.getTask = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!taskService.isValidId(id)) {
      return res.status(400).json({ message: 'Mã công việc không hợp lệ' });
    }

    const task = await Task.findById(id)
      .populate('createdBy', 'fullName email')
      .populate('assigneeIds', 'fullName email')
      .populate('primaryAssigneeId', 'fullName email');

    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc' });
    }

    const access = taskService.getAccess(task, req.user._id);
    if (!access) {
      return res.status(403).json({ message: 'Bạn không có quyền truy cập công việc này' });
    }

    res.json({ task, access });
  } catch (err) {
    next(err);
  }
};