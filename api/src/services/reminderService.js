const Task = require('../models/Task');
const { notifyParticipants } = require('./notificationService');
const { formatDate } = require('../utils/emailTemplates');

async function run() {
  const hours = Number(process.env.REMINDER_HOURS || 24);
  const now = new Date();
  const limit = new Date(now.getTime() + hours * 3600 * 1000);

  const tasks = await Task.find({
    status: { $ne: 'completed' },
    dueDate: { $gte: now, $lte: limit },
    reminderSentAt: null,
  });

  for (const t of tasks) {
    await notifyParticipants({
      actor: null,
      task: t,
      type: 'due_soon',
      title: 'Công việc sắp đến hạn',
      message: `Công việc "${t.title}" sắp đến hạn (${formatDate(t.dueDate)}).`,
    });
    t.reminderSentAt = now;
    await t.save();
  }
}

exports.start = () => {
  run().catch(console.error);
  setInterval(() => run().catch(console.error), 15 * 60 * 1000);
};