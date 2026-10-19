const express = require('express');
const router = express.Router();
const {
  assignTasks,
  getTasks,
  getMyTasks,
  completeTask,
  getTasksForMyRooms,
  verifyTask,
  rejectTask,
  getDashboardStats,
  getTask,
} = require('../controllers/taskController');
const { protect, authorize } = require('../middleware/auth');

router.use(protect);

// Admin routes
router.get('/stats', authorize('admin'), getDashboardStats);
router.post('/assign', authorize('admin'), assignTasks);
router.get('/', authorize('admin'), getTasks);

// Sweeper routes
router.get('/my', authorize('sweeper'), getMyTasks);
router.put('/:id/complete', authorize('sweeper'), completeTask);

// Invigilator routes
router.get('/invigilator', authorize('invigilator'), getTasksForMyRooms);
router.put('/:id/verify', authorize('invigilator'), verifyTask);
router.put('/:id/reject', authorize('invigilator'), rejectTask);

// Common
router.get('/:id', getTask);

module.exports = router;
