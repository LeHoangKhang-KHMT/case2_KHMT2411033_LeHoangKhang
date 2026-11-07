const express = require('express');
const taskController = require('../controllers/taskController');
const authMiddleware = require('../middleware/authMiddleware');
const { handleValidation } = require('../validators/authValidator');
const { createTaskRules } = require('../validators/taskValidator');

const router = express.Router();

router.use(authMiddleware);
router.get('/', taskController.listTasks);
router.post('/', createTaskRules, handleValidation, taskController.createTask);

module.exports = router;