const getTransporter = require('../config/email');
const EmailLog = require('../models/EmailLog');

const MAX_ATTEMPTS = 3;

async function deliver(log) {
  log.attempts += 1;
  try {
    if (!process.env.SMTP_USER || !process.env.SMTP_PASS) {
      throw new Error('Chưa cấu hình SMTP trong file .env');
    }
    await getTransporter().sendMail({
      from: process.env.MAIL_FROM || process.env.SMTP_USER,
      to: log.recipientEmail,
      subject: log.subject,
      html: log.body,
    });
    log.status = 'sent';
    log.sentAt = new Date();
    log.errorMessage = '';
  } catch (err) {
    log.status = 'failed';
    log.errorMessage = String((err && err.message) || err).slice(0, 300);
  }
  await log.save();
  return log;
}

exports.MAX_ATTEMPTS = MAX_ATTEMPTS;

exports.sendEmail = async ({ taskId = null, to, eventType, subject, html }) => {
  try {
    const log = await EmailLog.create({
      taskId,
      recipientEmail: to,
      eventType,
      subject,
      body: html,
      status: 'pending',
    });
    return await deliver(log);
  } catch (err) {
    console.error('Lỗi ghi log email:', err.message);
    return null;
  }
};

exports.retry = async (log) => deliver(log);