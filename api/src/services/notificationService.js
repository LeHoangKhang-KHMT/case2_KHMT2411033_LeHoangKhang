const Notification = require('../models/Notification');
const User = require('../models/User');
const TaskShare = require('../models/TaskShare');
const { sendEmail } = require('./emailService');
const { taskEmail } = require('../utils/emailTemplates');

// Tạo thông báo trong app và gửi email cho từng người (bỏ qua người thực hiện).
async function notifyUsers({ actor, users, task, type, title, message }) {
  for (const u of users) {
    if (actor && actor._id && String(u._id) === String(actor._id)) continue;

    await Notification.create({ userId: u._id, taskId: task._id, type, title, message });

    // Gửi email chạy nền, không chờ kết quả
    sendEmail({
      taskId: task._id,
      to: u.email,
      eventType: type,
      subject: `[Task Manager] ${title}`,
      html: taskEmail({ heading: title, message, task }),
    });
  }
}

// Người tạo + người được giao + người được chia sẻ
async function getParticipants(task) {
  const shares = await TaskShare.find({ taskId: task._id }).select('userId');
  const ids = new Set(
    [task.createdBy, ...task.assigneeIds, ...shares.map((s) => s.userId)].map(String)
  );
  return User.find({ _id: { $in: [...ids] } });
}

async function notifyParticipants({ actor, task, type, title, message }) {
  const users = await getParticipants(task);
  return notifyUsers({ actor, users, task, type, title, message });
}

module.exports = { notifyUsers, notifyParticipants, getParticipants };