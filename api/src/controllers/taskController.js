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

exports.updateTask = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!taskService.isValidId(id)) {
      return res.status(400).json({ message: 'Mã công việc không hợp lệ' });
    }

    const task = await Task.findById(id);
    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc' });
    }

    const access = taskService.getAccess(task, req.user._id);
    if (!access) {
      return res.status(403).json({ message: 'Bạn không có quyền truy cập công việc này' });
    }
    if (!access.canEdit) {
      return res.status(403).json({ message: 'Bạn không có quyền chỉnh sửa công việc này' });
    }

    const { title, description, priority, startDate, dueDate } = req.body;
    if (title !== undefined) task.title = title;
    if (description !== undefined) task.description = description;
    if (priority !== undefined) task.priority = priority;
    if (startDate !== undefined) task.startDate = startDate || null;
    if (dueDate !== undefined) task.dueDate = dueDate || null;

    if (task.startDate && task.dueDate && task.dueDate < task.startDate) {
      return res.status(400).json({ message: 'Hạn hoàn thành phải sau ngày bắt đầu' });
    }

    await task.save();
    res.json({ message: 'Cập nhật công việc thành công', task });
  } catch (err) {
    next(err);
  }
};

exports.deleteTask = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!taskService.isValidId(id)) {
      return res.status(400).json({ message: 'Mã công việc không hợp lệ' });
    }

    const task = await Task.findById(id);
    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc' });
    }

    const access = taskService.getAccess(task, req.user._id);
    if (!access) {
      return res.status(403).json({ message: 'Bạn không có quyền truy cập công việc này' });
    }
    if (!access.canDelete) {
      return res.status(403).json({ message: 'Bạn không có quyền xóa công việc này' });
    }

    await task.deleteOne();
    res.json({ message: 'Xóa công việc thành công' });
  } catch (err) {
    next(err);
  }
};

exports.updateStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!taskService.isValidId(id)) {
      return res.status(400).json({ message: 'Mã công việc không hợp lệ' });
    }

    const task = await Task.findById(id);
    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc' });
    }

    const access = taskService.getAccess(task, req.user._id);
    if (!access) {
      return res.status(403).json({ message: 'Bạn không có quyền truy cập công việc này' });
    }
    if (!access.canUpdateStatus) {
      return res.status(403).json({ message: 'Bạn không có quyền cập nhật trạng thái' });
    }

    task.status = req.body.status;
    await task.save();
    res.json({ message: 'Cập nhật trạng thái thành công', task });
  } catch (err) {
    next(err);
  }
};