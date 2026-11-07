const express = require('express');
const taskController = require('../controllers/taskController');
const authMiddleware = require('../middleware/authMiddleware');
const { handleValidation } = require('../validators/authValidator');
const { createTaskRules, updateTaskRules } = require('../validators/taskValidator');
const router = express.Router();

router.use(authMiddleware);
router.get('/', taskController.listTasks);
router.get('/:id', taskController.getTask);
router.put('/:id', updateTaskRules, handleValidation, taskController.updateTask);
router.post('/', createTaskRules, handleValidation, taskController.createTask);

module.exports = router;