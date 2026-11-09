const esc = (s) =>
  String(s ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

const PRIORITY = { low: 'Thấp', medium: 'Trung bình', high: 'Cao' };
const STATUS = { todo: 'Chưa thực hiện', in_progress: 'Đang thực hiện', completed: 'Đã hoàn thành' };
const fmt = (d) => (d ? new Date(d).toLocaleDateString('vi-VN') : 'Chưa đặt');

exports.taskEmail = ({ heading, message, task }) => `
<div style="font-family:Arial,sans-serif;max-width:560px;margin:auto;border:1px solid #e0e0e0;border-radius:12px;overflow:hidden">
  <div style="background:#3f51b5;color:#fff;padding:16px 24px">
    <h2 style="margin:0;font-size:18px">${esc(heading)}</h2>
  </div>
  <div style="padding:24px;color:#222;line-height:1.5">
    <p style="margin-top:0">${esc(message)}</p>
    <table style="width:100%;border-collapse:collapse;font-size:14px">
      <tr><td style="padding:6px 0;color:#666;width:140px">Công việc</td><td><b>${esc(task.title)}</b></td></tr>
      <tr><td style="padding:6px 0;color:#666">Trạng thái</td><td>${esc(STATUS[task.status] || task.status)}</td></tr>
      <tr><td style="padding:6px 0;color:#666">Ưu tiên</td><td>${esc(PRIORITY[task.priority] || task.priority)}</td></tr>
      <tr><td style="padding:6px 0;color:#666">Hạn hoàn thành</td><td>${esc(fmt(task.dueDate))}</td></tr>
    </table>
    <p style="color:#888;font-size:12px;margin-bottom:0">Email tự động từ Task Manager.</p>
  </div>
</div>`;

exports.formatDate = fmt;