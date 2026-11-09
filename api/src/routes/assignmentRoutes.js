const express = require('express');
const ctrl = require('../controllers/assignmentController');

const router = express.Router({ mergeParams: true });

router.get('/', ctrl.list);
router.post('/', ctrl.add);
router.patch('/:userId', ctrl.setPrimary);
router.delete('/:userId', ctrl.remove);

module.exports = router;