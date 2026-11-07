const Task = require('../models/Task');

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