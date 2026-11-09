const express = require('express');
const ctrl = require('../controllers/emailLogController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.use(authMiddleware);
router.post('/:id/retry', ctrl.retry);

module.exports = router;