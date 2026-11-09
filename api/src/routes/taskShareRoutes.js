const express = require('express');
const ctrl = require('../controllers/taskShareController');

const router = express.Router({ mergeParams: true });

router.get('/', ctrl.list);
router.post('/', ctrl.add);
router.patch('/:shareId', ctrl.update);
router.delete('/:shareId', ctrl.remove);

module.exports = router;