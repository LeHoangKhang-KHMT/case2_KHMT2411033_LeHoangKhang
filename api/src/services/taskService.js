const mongoose = require('mongoose');
const Task = require('../models/Task');
const TaskShare = require('../models/TaskShare');

const isValidId = (id) => mongoose.Types.ObjectId.isValid(id);
const idOf = (v) => String(v && v._id ? v._id : v);

// Trả về quyền của người dùng với công việc, hoặc null nếu không có quyền truy cập.
async function getAccess(task, userId) {
  const uid = String(userId);

  if (idOf(task.createdBy) === uid) {
    return {
      role: 'creator',
      canEdit: true,
      canDelete: true,
      canUpdateStatus: true,
      canManage: true,
    };
  }

  const isAssignee = task.assigneeIds.some((a) => idOf(a) === uid);
  const isPrimary = !!task.primaryAssigneeId && idOf(task.primaryAssigneeId) === uid;
  const share = await TaskShare.findOne({ taskId: task._id, userId });

  if (!isAssignee && !share) return null;

  const isEditor = !!share && share.permission === 'editor';
  let role = 'viewer';
  if (isEditor) role = 'editor';
  else if (isPrimary) role = 'primary';
  else if (isAssignee) role = 'assignee';

  return {
    role,
    canEdit: isEditor,
    canDelete: false,
    canUpdateStatus: isAssignee || isEditor,
    canManage: false,
  };
}

// Nạp công việc và kiểm tra quyền. Nếu lỗi thì đã trả response và hàm trả về null.
async function loadTask(req, res, requireManage = false) {
  const { id } = req.params;
  if (!isValidId(id)) {
    res.status(400).json({ message: 'Mã công việc không hợp lệ' });
    return null;
  }

  const task = await Task.findById(id);
  if (!task) {
    res.status(404).json({ message: 'Không tìm thấy công việc' });
    return null;
  }

  const access = await getAccess(task, req.user._id);
  if (!access) {
    res.status(403).json({ message: 'Bạn không có quyền truy cập công việc này' });
    return null;
  }
  if (requireManage && !access.canManage) {
    res.status(403).json({ message: 'Chỉ người tạo mới được thực hiện thao tác này' });
    return null;
  }

  return { task, access };
}

module.exports = { isValidId, idOf, getAccess, loadTask };