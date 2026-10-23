# 🧹 Campus Cleaning System – Duty & Environment Management App

A cross-platform mobile application designed to **digitize and streamline campus cleaning operations**. The system manages cleaning duties, complaints, task assignments, and role-based workflows to improve campus sanitation and operational efficiency.

---

## 🚀 Key Features

- **Role-Based Access Control (RBAC)** – Separate access and dashboards for Administrators, Invigilators, and Sweepers.
- **Duty Management** – Assign and manage cleaning duties across different campus areas.
- **Task Tracking** – Track assigned duties and their completion status.
- **Complaint Management** – Report and monitor campus cleaning and sanitation issues.
- **Admin Management** – Manage users, duties, complaints, and campus operations.
- **Cross-Platform Support** – Flutter-based application supporting Android and iOS.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter, Dart |
| Backend | Node.js, Express.js |
| Database | MongoDB Atlas |
| ODM | Mongoose |
| API | REST API |
| Version Control | Git, GitHub |

---

## 📂 Project Structure

```text
CampusCleaning-DutyManagementApp/
│
├── frontend/
│   ├── lib/
│   │   ├── screens/
│   │   ├── models/
│   │   ├── providers/
│   │   └── services/
│   ├── assets/
│   └── pubspec.yaml
│
└── backend/
    ├── controllers/
    ├── models/
    ├── routes/
    └── server.js
```

---

## ⚙️ Getting Started

### Prerequisites

Make sure you have the following installed:

- Flutter SDK
- Dart SDK
- Node.js and npm
- MongoDB / MongoDB Atlas

### 1. Clone the Repository

```bash
git clone <YOUR_GITHUB_REPOSITORY_URL>
cd CampusCleaning-DutyManagementApp
```

### 2. Backend Setup

```bash
cd backend
npm install
npm start
```

Configure your MongoDB connection and other backend settings using environment variables.

### 3. Frontend Setup

Open a new terminal:

```bash
cd frontend
flutter pub get
flutter run
```

---

## 🔐 User Roles

| Role | Responsibilities |
|---|---|
| **Administrator** | Manage users, duties, complaints, and overall operations |
| **Invigilator** | Monitor assigned cleaning activities and tasks |
| **Sweeper** | View assigned duties and update task status |

---

## 📱 Application Workflow

```text
Administrator
      │
      ├── Manage Users
      ├── Assign Duties
      └── Monitor Complaints
              │
              ▼
        Invigilator
              │
              ├── Monitor Tasks
              └── Track Completion
                      │
                      ▼
                  Sweeper
                      │
                      └── Complete Assigned Duties
```

---

## 📄 License

This project is developed as an **academic and professional portfolio application**.