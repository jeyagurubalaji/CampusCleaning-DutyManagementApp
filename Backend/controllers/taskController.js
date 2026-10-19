const CleaningTask = require('../models/CleaningTask');
const Room = require('../models/Room');
const User = require('../models/User');

// Parse YYYY-MM-DD as local calendar date (noon avoids DST edge cases)
const parseLocalDate = (dateStr) => {
  if (dateStr && /^\d{4}-\d{2}-\d{2}$/.test(dateStr)) {
    const [y, m, d] = dateStr.split('-').map(Number);
    return new Date(y, m - 1, d, 12, 0, 0, 0);
  }
  const now = new Date();
  return new Date(now.getFullYear(), now.getMonth(), now.getDate(), 12, 0, 0, 0);
};

// Helper to get start/end of local calendar day
const getDayBounds = (dateStr) => {
  const d = parseLocalDate(dateStr);
  const start = new Date(d.getFullYear(), d.getMonth(), d.getDate(), 0, 0, 0, 0);
  const end = new Date(d.getFullYear(), d.getMonth(), d.getDate(), 23, 59, 59, 999);
  return { start, end };
};

// Admin: Assign cleaning duties
exports.assignTasks = async (req, res) => {
  try {
    const { assignments, dutyDate } = req.body;

    if (!assignments || !Array.isArray(assignments) || assignments.length === 0) {
      return res.status(400).json({ success: false, message: 'Assignments array is required' });
    }

    const date = parseLocalDate(dutyDate);
    const { start, end } = getDayBounds(dutyDate);

    const created = [];
    const errors = [];

    for (const item of assignments) {
      const { roomId, sweeperId } = item;
      if (!roomId || !sweeperId) {
        errors.push({ item, error: 'roomId and sweeperId required' });
        continue;
      }

      const existing = await CleaningTask.findOne({
        room: roomId,
        dutyDate: { $gte: start, $lte: end },
        status: { $nin: ['rejected'] },
      });

      if (existing && existing.status !== 'rejected') {
        errors.push({ roomId, error: 'Task already exists for this room on this date' });
        continue;
      }

      const task = await CleaningTask.create({
        room: roomId,
        sweeper: sweeperId,
        assignedBy: req.user._id,
        dutyDate: date,
        status: 'pending',
        history: [
          {
            status: 'pending',
            changedBy: req.user._id,
            changedAt: new Date(),
            reason: 'Assigned by admin',
          },
        ],
      });

      created.push(task);
    }

    const populated = await CleaningTask.find({ _id: { $in: created.map((t) => t._id) } })
      .populate('room', 'name roomNumber type floor')
      .populate('sweeper', 'name email')
      .populate('assignedBy', 'name');

    res.status(201).json({
      success: true,
      count: populated.length,
      data: populated,
      errors: errors.length ? errors : undefined,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get all tasks (admin) with filters
exports.getTasks = async (req, res) => {
  try {
    const filter = {};
    if (req.query.status) filter.status = req.query.status;
    if (req.query.sweeper) filter.sweeper = req.query.sweeper;
    if (req.query.room) filter.room = req.query.room;

    if (req.query.date) {
      const { start, end } = getDayBounds(req.query.date);
      filter.dutyDate = { $gte: start, $lte: end };
    } else if (req.query.from || req.query.to) {
      filter.dutyDate = {};
      if (req.query.from) filter.dutyDate.$gte = new Date(req.query.from);
      if (req.query.to) filter.dutyDate.$lte = new Date(req.query.to);
    }

    const tasks = await CleaningTask.find(filter)
      .populate({
        path: 'room',
        select: 'name roomNumber type floor department',
        populate: { path: 'department', select: 'name code' },
      })
      .populate('sweeper', 'name email phone')
      .populate('assignedBy', 'name')
      .populate('verifiedBy', 'name')
      .sort({ dutyDate: -1, createdAt: -1 });

    res.json({ success: true, count: tasks.length, data: tasks });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Sweeper: Get my assigned tasks
exports.getMyTasks = async (req, res) => {
  try {
    const filter = { sweeper: req.user._id };

    if (req.query.date) {
      const { start, end } = getDayBounds(req.query.date);
      filter.dutyDate = { $gte: start, $lte: end };
    } else {
      const { start, end } = getDayBounds();
      filter.dutyDate = { $gte: start, $lte: end };
    }

    if (req.query.status) filter.status = req.query.status;

    const tasks = await CleaningTask.find(filter)
      .populate({
        path: 'room',
        select: 'name roomNumber type floor department',
        populate: { path: 'department', select: 'name code' },
      })
      .populate('assignedBy', 'name')
      .populate('verifiedBy', 'name')
      .sort({ status: 1, createdAt: 1 });

    res.json({ success: true, count: tasks.length, data: tasks });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Sweeper: Mark task as completed
exports.completeTask = async (req, res) => {
  try {
    const task = await CleaningTask.findById(req.params.id);
    if (!task) {
      return res.status(404).json({ success: false, message: 'Task not found' });
    }

    if (task.sweeper.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not your assigned task' });
    }

    if (task.status !== 'pending' && task.status !== 'rejected') {
      return res.status(400).json({
        success: false,
        message: `Cannot complete task with status: ${task.status}`,
      });
    }

    task.status = 'completed';
    task.completedAt = new Date();
    task.rejectionReason = null;
    task.history.push({
      status: 'completed',
      changedBy: req.user._id,
      changedAt: new Date(),
      reason: req.body.notes || 'Marked as completed by sweeper',
    });
    if (req.body.notes) task.notes = req.body.notes;

    await task.save();

    const populated = await CleaningTask.findById(task._id)
      .populate({
        path: 'room',
        select: 'name roomNumber type floor',
        populate: { path: 'department', select: 'name code' },
      })
      .populate('sweeper', 'name')
      .populate('verifiedBy', 'name');

    res.json({ success: true, data: populated });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Invigilator: Get tasks for my rooms
exports.getTasksForMyRooms = async (req, res) => {
  try {
    const myRooms = await Room.find({ invigilator: req.user._id, isActive: true }).select('_id');
    const roomIds = myRooms.map((r) => r._id);

    const filter = { room: { $in: roomIds } };

    if (req.query.date) {
      const { start, end } = getDayBounds(req.query.date);
      filter.dutyDate = { $gte: start, $lte: end };
    } else {
      const { start, end } = getDayBounds();
      filter.dutyDate = { $gte: start, $lte: end };
    }

    if (req.query.status) filter.status = req.query.status;

    const tasks = await CleaningTask.find(filter)
      .populate({
        path: 'room',
        select: 'name roomNumber type floor department',
        populate: { path: 'department', select: 'name code' },
      })
      .populate('sweeper', 'name email phone')
      .populate('assignedBy', 'name')
      .populate('verifiedBy', 'name')
      .sort({ status: 1, completedAt: -1 });

    res.json({ success: true, count: tasks.length, data: tasks });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Invigilator: Verify a completed task
exports.verifyTask = async (req, res) => {
  try {
    const task = await CleaningTask.findById(req.params.id).populate('room');
    if (!task) {
      return res.status(404).json({ success: false, message: 'Task not found' });
    }

    const room = await Room.findById(task.room._id || task.room);
    if (!room || room.invigilator?.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'You are not the invigilator for this room' });
    }

    if (task.status !== 'completed') {
      return res.status(400).json({
        success: false,
        message: `Can only verify completed tasks. Current status: ${task.status}`,
      });
    }

    task.status = 'verified';
    task.verifiedBy = req.user._id;
    task.verifiedAt = new Date();
    task.history.push({
      status: 'verified',
      changedBy: req.user._id,
      changedAt: new Date(),
      reason: req.body.notes || 'Verified by invigilator',
    });

    await task.save();

    const populated = await CleaningTask.findById(task._id)
      .populate({
        path: 'room',
        select: 'name roomNumber type floor',
        populate: { path: 'department', select: 'name code' },
      })
      .populate('sweeper', 'name')
      .populate('verifiedBy', 'name');

    res.json({ success: true, data: populated });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Invigilator: Reject a completed task
exports.rejectTask = async (req, res) => {
  try {
    const { reason } = req.body;
    if (!reason || reason.trim().length === 0) {
      return res.status(400).json({ success: false, message: 'Rejection reason is required' });
    }

    const task = await CleaningTask.findById(req.params.id).populate('room');
    if (!task) {
      return res.status(404).json({ success: false, message: 'Task not found' });
    }

    const room = await Room.findById(task.room._id || task.room);
    if (!room || room.invigilator?.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'You are not the invigilator for this room' });
    }

    if (task.status !== 'completed') {
      return res.status(400).json({
        success: false,
        message: `Can only reject completed tasks. Current status: ${task.status}`,
      });
    }

    task.status = 'rejected';
    task.rejectionReason = reason;
    task.verifiedBy = req.user._id;
    task.verifiedAt = new Date();
    task.history.push({
      status: 'rejected',
      changedBy: req.user._id,
      changedAt: new Date(),
      reason,
    });

    await task.save();

    const populated = await CleaningTask.findById(task._id)
      .populate({
        path: 'room',
        select: 'name roomNumber type floor',
        populate: { path: 'department', select: 'name code' },
      })
      .populate('sweeper', 'name')
      .populate('verifiedBy', 'name');

    res.json({ success: true, data: populated });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Dashboard stats for admin
exports.getDashboardStats = async (req, res) => {
  try {
    const { start, end } = getDayBounds(req.query.date);

    const todayFilter = { dutyDate: { $gte: start, $lte: end } };

    const [total, pending, completed, verified, rejected] = await Promise.all([
      CleaningTask.countDocuments(todayFilter),
      CleaningTask.countDocuments({ ...todayFilter, status: 'pending' }),
      CleaningTask.countDocuments({ ...todayFilter, status: 'completed' }),
      CleaningTask.countDocuments({ ...todayFilter, status: 'verified' }),
      CleaningTask.countDocuments({ ...todayFilter, status: 'rejected' }),
    ]);

    const recent = await CleaningTask.find(todayFilter)
      .populate('room', 'name roomNumber')
      .populate('sweeper', 'name')
      .sort({ updatedAt: -1 })
      .limit(10);

    res.json({
      success: true,
      data: {
        date: `${start.getFullYear()}-${String(start.getMonth() + 1).padStart(2, '0')}-${String(start.getDate()).padStart(2, '0')}`,
        stats: { total, pending, completed, verified, rejected },
        recent,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get single task
exports.getTask = async (req, res) => {
  try {
    const task = await CleaningTask.findById(req.params.id)
      .populate({
        path: 'room',
        select: 'name roomNumber type floor department invigilator',
        populate: [
          { path: 'department', select: 'name code' },
          { path: 'invigilator', select: 'name email' },
        ],
      })
      .populate('sweeper', 'name email phone')
      .populate('assignedBy', 'name')
      .populate('verifiedBy', 'name')
      .populate('history.changedBy', 'name');

    if (!task) {
      return res.status(404).json({ success: false, message: 'Task not found' });
    }

    res.json({ success: true, data: task });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};