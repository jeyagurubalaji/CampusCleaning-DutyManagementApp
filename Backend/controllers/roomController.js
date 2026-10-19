const Room = require('../models/Room');

exports.getRooms = async (req, res) => {
  try {
    const filter = { isActive: true };
    if (req.query.department) filter.department = req.query.department;
    if (req.query.type) filter.type = req.query.type;

    const rooms = await Room.find(filter)
      .populate('department', 'name code')
      .populate('invigilator', 'name email')
      .sort({ roomNumber: 1 });

    res.json({ success: true, count: rooms.length, data: rooms });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getRoom = async (req, res) => {
  try {
    const room = await Room.findById(req.params.id)
      .populate('department', 'name code')
      .populate('invigilator', 'name email');
    if (!room) {
      return res.status(404).json({ success: false, message: 'Room not found' });
    }
    res.json({ success: true, data: room });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.createRoom = async (req, res) => {
  try {
    const room = await Room.create(req.body);
    const populated = await Room.findById(room._id)
      .populate('department', 'name code')
      .populate('invigilator', 'name email');
    res.status(201).json({ success: true, data: populated });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

exports.updateRoom = async (req, res) => {
  try {
    const room = await Room.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    })
      .populate('department', 'name code')
      .populate('invigilator', 'name email');
    if (!room) {
      return res.status(404).json({ success: false, message: 'Room not found' });
    }
    res.json({ success: true, data: room });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

exports.deleteRoom = async (req, res) => {
  try {
    const room = await Room.findByIdAndUpdate(req.params.id, { isActive: false }, { new: true });
    if (!room) {
      return res.status(404).json({ success: false, message: 'Room not found' });
    }
    res.json({ success: true, message: 'Room deactivated', data: room });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get rooms assigned to an invigilator
exports.getMyRooms = async (req, res) => {
  try {
    const rooms = await Room.find({ invigilator: req.user._id, isActive: true })
      .populate('department', 'name code')
      .sort({ roomNumber: 1 });
    res.json({ success: true, count: rooms.length, data: rooms });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
