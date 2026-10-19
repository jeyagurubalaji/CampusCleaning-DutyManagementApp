const express = require('express');
const router = express.Router();
const {
  getRooms,
  getRoom,
  createRoom,
  updateRoom,
  deleteRoom,
  getMyRooms,
} = require('../controllers/roomController');
const { protect, authorize } = require('../middleware/auth');

router.use(protect);

router.get('/my', authorize('invigilator'), getMyRooms);

router.route('/').get(getRooms).post(authorize('admin'), createRoom);

router
  .route('/:id')
  .get(getRoom)
  .put(authorize('admin'), updateRoom)
  .delete(authorize('admin'), deleteRoom);

module.exports = router;
