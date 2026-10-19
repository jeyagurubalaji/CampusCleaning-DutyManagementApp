const User = require('../models/User');

exports.getUsers = async (req, res) => {
  try {
    const filter = { isActive: true };
    if (req.query.role) filter.role = req.query.role;
    if (req.query.department) filter.department = req.query.department;

    const users = await User.find(filter)
      .populate('department', 'name code')
      .select('-password')
      .sort({ name: 1 });

    res.json({ success: true, count: users.length, data: users });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getUser = async (req, res) => {
  try {
    const user = await User.findById(req.params.id)
      .populate('department', 'name code')
      .select('-password');
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    res.json({ success: true, data: user });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.createUser = async (req, res) => {
  try {
    const { name, email, password, role, department, phone } = req.body;

    if (!name || !email || !role) {
      return res.status(400).json({ success: false, message: 'Name, email and role are required' });
    }

    if (password && password.length < 6) {
      return res.status(400).json({ success: false, message: 'Password must be at least 6 characters' });
    }

    const normalizedEmail = email.toLowerCase().trim();
    const existing = await User.findOne({ email: normalizedEmail });
    if (existing) {
      if (existing.isActive === false) {
        // Soft-deleted earlier — remove permanently so email can be reused
        await User.findByIdAndDelete(existing._id);
      } else {
        return res.status(400).json({ success: false, message: 'Email already registered' });
      }
    }

    const user = await User.create({
      name,
      email: normalizedEmail,
      password: password || 'password123',
      role,
      department: department || null,
      phone: phone || '',
    });

    res.status(201).json({
      success: true,
      data: {
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        department: user.department,
        phone: user.phone,
      },
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({ success: false, message: 'Email already registered' });
    }
    res.status(400).json({ success: false, message: error.message });
  }
};

exports.updateUser = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('+password');
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const { name, email, phone, role, department, password } = req.body;

    if (name !== undefined) user.name = name;
    if (email !== undefined) user.email = email.toLowerCase().trim();
    if (phone !== undefined) user.phone = phone;
    if (role !== undefined) user.role = role;
    if (department !== undefined) user.department = department || null;

    // Update password only if provided (triggers bcrypt pre-save hook)
    if (password && password.trim().length > 0) {
      if (password.length < 6) {
        return res.status(400).json({ success: false, message: 'Password must be at least 6 characters' });
      }
      user.password = password;
    }

    await user.save();

    const populated = await User.findById(user._id)
      .populate('department', 'name code')
      .select('-password');

    res.json({ success: true, data: populated });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({ success: false, message: 'Email already registered' });
    }
    res.status(400).json({ success: false, message: error.message });
  }
};

exports.deleteUser = async (req, res) => {
  try {
    // Permanent delete — removes user from database completely
    const user = await User.findByIdAndDelete(req.params.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    res.json({
      success: true,
      message: 'User permanently deleted',
      data: { _id: user._id, email: user.email },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.resetPassword = async (req, res) => {
  try {
    const { password } = req.body;
    if (!password || password.length < 6) {
      return res.status(400).json({ success: false, message: 'Password must be at least 6 characters' });
    }

    const user = await User.findById(req.params.id).select('+password');
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    user.password = password;
    await user.save();

    res.json({ success: true, message: 'Password reset successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};