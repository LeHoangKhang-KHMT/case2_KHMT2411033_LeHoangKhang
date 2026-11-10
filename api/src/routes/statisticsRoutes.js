const express = require('express');
const ctrl = require('../controllers/statisticsController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.use(authMiddleware);
router.get('/tasks', ctrl.tasks);
router.get('/assignments', ctrl.assignments);
router.get('/deadlines', ctrl.deadlines);

module.exports = router;