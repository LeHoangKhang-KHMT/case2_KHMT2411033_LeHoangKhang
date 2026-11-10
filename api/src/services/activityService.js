const TaskActivity = require('../models/TaskActivity');

exports.log = async ({ taskId, userId, action, details = {} }) => {
  try {
    await TaskActivity.create({ taskId, userId, action, details });
  } catch (err) {
    console.error('Lỗi ghi lịch sử hoạt động:', err.message);
  }
};