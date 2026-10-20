const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('../models/User'); // Adjust the path to your User model if needed
require('dotenv').config();

const seedUsers = async () => {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI, {
      family: 4,
    });
    console.log('Database connected for seeding...');

    // Clear existing users (optional: remove this line if you want to keep existing data)
    await User.deleteMany({});
    console.log('Cleared existing users.');

    // Hash passwords securely
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash('admin123', salt);
    const staffPassword = await bcrypt.hash('password123', salt);

    const users = [
      {
        name: 'Administrator',
        email: 'admin@campus.edu',
        password: hashedPassword,
        role: 'admin',
      },
      {
        name: 'Invigilator Staff',
        email: 'invigilator@campus.edu',
        password: staffPassword,
        role: 'invigilator',
      },
      {
        name: 'Sweeper Staff',
        email: 'sweeper@campus.edu',
        password: staffPassword,
        role: 'sweeper',
      },
    ];

    await User.insertMany(users);
    console.log('Default users seeded successfully!');
    console.log('-----------------------------------');
    console.log('Admin: admin@campus.edu / admin123');
    console.log('Invigilator: invigilator@campus.edu / password123');
    console.log('Sweeper: sweeper@campus.edu / password123');
    console.log('-----------------------------------');

    process.exit(0);
  } catch (error) {
    console.error(`Seeding error: ${error.message}`);
    process.exit(1);
  }
};

seedUsers();