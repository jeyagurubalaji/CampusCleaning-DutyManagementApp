const mongoose = require('mongoose');

const cleaningTaskSchema = new mongoose.Schema(
  {
    room: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Room',
      required: true,
    },
    sweeper: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    assignedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    assignedDate: {
      type: Date,
      required: true,
      default: Date.now,
    },
    // Date for which the duty is assigned (YYYY-MM-DD)
    dutyDate: {
      type: Date,
      required: true,
    },
    status: {
      type: String,
      enum: ['pending', 'completed', 'verified', 'rejected'],
      default: 'pending',
    },
    completedAt: {
      type: Date,
      default: null,
    },
    verifiedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    verifiedAt: {
      type: Date,
      default: null,
    },
    rejectionReason: {
      type: String,
      default: null,
    },
    notes: {
      type: String,
      default: '',
    },
    // History of status changes for audit
    history: [
      {
        status: String,
        changedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        changedAt: { type: Date, default: Date.now },
        reason: String,
      },
    ],
  },
  { timestamps: true }
);

// Index for efficient queries
cleaningTaskSchema.index({ dutyDate: 1, status: 1 });
cleaningTaskSchema.index({ sweeper: 1, dutyDate: 1 });
cleaningTaskSchema.index({ room: 1, dutyDate: 1 });

module.exports = mongoose.model('CleaningTask', cleaningTaskSchema);
