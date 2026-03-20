# TodoMich ✓

**The ultimate smart task manager with a beautiful dark interface and powerful calendar integration.**

![TodoMich Screenshot](https://via.placeholder.com/800x400/1a1a1a/5f9fff?text=TodoMich+-+Smart+Task+Manager)

## 🌟 Features

### ✨ **Core Features**
- ✅ **Instant Task Creation** - Add tasks that appear IMMEDIATELY
- ✅ **Permanent Storage** - Every change saved permanently until you manually change it
- ✅ **Full Calendar View** - Perfect calendar in Inbox tab (just like Todoist)
- ✅ **Dark Mode by Default** - Beautiful, modern dark interface
- ✅ **Smart Views** - Inbox, Today, Upcoming, Completed
- ✅ **Unlimited Projects** - Organize tasks with colored projects
- ✅ **Priority Levels** - 4 priority levels (P1-P4)
- ✅ **Due Dates** - Natural date parsing and formatting
- ✅ **Quick Add** - Press Ctrl+K to quickly add tasks

### 🛡️ **Data Protection (5 Layers)**
1. **Server-side backups** - Automatic hourly rotation (24 backups)
2. **Auto-save** - Every 30 seconds + instant on change
3. **localStorage backup** - Client-side failsafe
4. **Daily snapshots** - 7 days of history
5. **Manual exports** - Download your data anytime

### 📅 **Calendar Features**
- **Month view** - See all your tasks in a calendar grid
- **Click any date** - Instantly add a task to that day
- **Task counts** - See how many tasks per day
- **Navigate months** - Previous/next month navigation
- **Today highlight** - Current day clearly marked

### 🎨 **UI/UX Excellence**
- **Instant feedback** - Tasks appear immediately after creation
- **Hover effects** - Smooth animations and transitions
- **Dark theme** - Easy on the eyes, modern look
- **Responsive design** - Works on all screen sizes
- **Keyboard shortcuts** - Ctrl+K for quick add, Esc to close
- **Empty states** - Helpful messages when lists are empty

## 🚀 Quick Start

### **Prerequisites**
- Node.js 14+ installed
- npm or yarn

### **Installation**

```bash
# Clone the repository
git clone https://github.com/yourusername/todomich.git
cd todomich

# Install dependencies
npm install

# Start the server
npm start
```

The app will be available at `http://localhost:3456`

### **Alternative: Quick Start Script**

Windows:
```powershell
.\start.ps1
```

Linux/Mac:
```bash
./start.sh
```

## 📖 Usage

### **Adding Tasks**

1. **Quick Add (Ctrl+K)**
   - Press `Ctrl+K` anywhere
   - Type your task
   - Press Enter

2. **From Calendar**
   - Click on any date in the calendar
   - Task is automatically assigned to that date

3. **From Project**
   - Navigate to a project
   - Click "Add Task"
   - Task is automatically assigned to that project

### **Managing Tasks**

- **Complete** - Click the checkbox
- **Edit** - Hover over task, click ✏️ icon
- **Delete** - Hover over task, click 🗑️ icon (with confirmation)
- **Move** - Edit task and change project

### **Projects**

- **Create** - Click + button in sidebar
- **View** - Click on project name
- **Edit** - (Coming soon: click ✏️ on hover)
- **Delete** - (Coming soon: click 🗑️ on hover)

### **Keyboard Shortcuts**

- `Ctrl+K` - Quick add task
- `Esc` - Close modals/dialogs

## 🏗️ Architecture

### **Tech Stack**

**Backend:**
- Express.js - Fast, minimalist web framework
- Node.js - JavaScript runtime
- JSON file storage - Simple, reliable data persistence

**Frontend:**
- Vanilla JavaScript - No frameworks, pure performance
- CSS3 - Modern styling with variables
- HTML5 - Semantic markup

### **File Structure**

```
todomich/
├── public/
│   ├── index.html          # Main HTML
│   ├── app.js              # Core application logic
│   ├── styles.css          # Dark mode styles
│   └── manifest.json       # PWA manifest
├── backups/                # Automatic backups
├── server.js               # Express server
├── db.json                 # Task database
├── package.json            # Dependencies
└── README.md               # This file
```

### **Data Flow**

1. User creates/modifies task
2. Request sent to Express API
3. Server updates db.json
4. Server creates backup
5. Response sent to client
6. Client updates UI IMMEDIATELY
7. Client saves to localStorage

**Result:** Instant feedback + permanent storage + 5-layer protection

## 🔧 Configuration

### **Change Port**

Edit `server.js`:
```javascript
const PORT = 3456; // Change to your preferred port
```

### **Backup Settings**

Edit `server.js`:
```javascript
const MAX_BACKUPS = 24;        // Number of hourly backups to keep
const MAX_DAILY_BACKUPS = 7;   // Number of daily backups to keep
```

### **Auto-save Interval**

Edit `public/app.js`:
```javascript
setInterval(async () => {
    saveToLocalStorage();
}, 30000); // Change 30000 to your preferred interval (in ms)
```

## 📊 API Endpoints

### **Tasks**
- `GET /api/tasks` - Get all tasks
- `POST /api/tasks` - Create a task
- `PUT /api/tasks/:id` - Update a task
- `DELETE /api/tasks/:id` - Delete a task

### **Projects**
- `GET /api/projects` - Get all projects
- `POST /api/projects` - Create a project
- `PUT /api/projects/:id` - Update a project
- `DELETE /api/projects/:id` - Delete a project

### **Labels**
- `GET /api/labels` - Get all labels
- `POST /api/labels` - Create a label
- `PUT /api/labels/:id` - Update a label
- `DELETE /api/labels/:id` - Delete a label

### **Stats**
- `GET /api/stats` - Get productivity stats

### **Data Management**
- `GET /api/export` - Export all data as JSON
- `POST /api/import` - Import data from JSON

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by Todoist's excellent UX
- Built with ❤️ for productivity enthusiasts
- Dark mode design inspired by modern dev tools

## 🐛 Known Issues

- [ ] Project editing requires modal implementation
- [ ] Label management UI needs enhancement
- [ ] Drag & drop task reordering coming soon

## 🗺️ Roadmap

- [ ] Recurring tasks automation
- [ ] Subtasks support
- [ ] Task dependencies
- [ ] Time tracking
- [ ] Pomodoro timer
- [ ] File attachments
- [ ] Collaboration features
- [ ] Mobile app (React Native)
- [ ] Browser extension
- [ ] API authentication

## 📧 Contact

**Till Thelet**
- GitHub: [@TillThelet](https://github.com/TillThelet)
- Email: michaelovsky22@gmail.com

---

**Made with ✓ by TodoMich**

*Transform your productivity. One task at a time.*
