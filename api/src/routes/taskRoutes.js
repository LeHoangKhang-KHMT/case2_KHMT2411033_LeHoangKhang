const express = require('express');
const taskController = require('../controllers/taskController');
const authMiddleware = require('../middleware/authMiddleware');
const { handleValidation } = require('../validators/authValidator');
const {
  createTaskRules,
  updateTaskRules,
  updateStatusRules,
} = require('../validators/taskValidator');

const router = express.Router();

router.use(authMiddleware);

router.get('/', taskController.listTasks);
router.post('/', createTaskRules, handleValidation, taskController.createTask);
router.get('/:id', taskController.getTask);
router.put('/:id', updateTaskRules, handleValidation, taskController.updateTask);
router.delete('/:id', taskController.deleteTask);
router.patch(
  '/:id/status',
  updateStatusRules,
  handleValidation,
  taskController.updateStatus
);

module.exports = router;