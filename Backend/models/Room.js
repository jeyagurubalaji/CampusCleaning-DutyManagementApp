const mongoose = require('mongoose');

const roomSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Room name is required'],
      trim: true,
    },
    roomNumber: {
      type: String,
      required: [true, 'Room number is required'],
      trim: true,
    },
    type: {
      type: String,
      enum: ['classroom', 'laboratory', 'office', 'other'],
      default: 'classroom',
    },
    department: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Department',
      required: true,
    },
    floor: {
      type: Number,
      default: 1,
    },
    capacity: {
      type: Number,
      default: 0,
    },
    invigilator: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

roomSchema.index({ roomNumber: 1, department: 1 }, { unique: true });

module.exports = mongoose.model('Room', roomSchema);
