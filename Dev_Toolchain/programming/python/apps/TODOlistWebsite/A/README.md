# 🚀 TodoNotes - Beautiful Task & Note Management

A comprehensive web application that combines the best features of **Todoist** and **Samsung Notes** in one beautiful, modern interface. Built with FastAPI, featuring rich text editing, task management, and a stunning responsive design.

![TodoNotes Preview](https://via.placeholder.com/800x400/667eea/ffffff?text=TodoNotes+Dashboard)

## ✨ Features

### 📝 **Task Management (Todoist-inspired)**
- ✅ Create, edit, and organize tasks
- 📁 Project-based organization with custom colors
- 🎯 Priority levels (Low, Medium, High, Urgent)
- 📅 Due dates and deadline tracking
- 🏷️ Labels and tags
- ✅ Subtasks and task hierarchies
- 📊 Progress tracking and statistics

### 📒 **Rich Note Taking (Samsung Notes-inspired)**
- 📝 Rich text editing with Quill.js editor
- 🖼️ Image uploads and attachments
- 📁 Folder organization with custom colors
- 🔍 Full-text search across notes
- 💾 Auto-save functionality
- 📱 Responsive design for all devices
- 🎨 Beautiful typography and formatting

### 🎨 **Beautiful Modern UI**
- 🌈 Gradient backgrounds and modern design
- 📱 Fully responsive (mobile, tablet, desktop)
- ⚡ Fast and smooth animations
- 🔍 Global search with instant results
- ⌨️ Keyboard shortcuts for power users
- 🎯 Intuitive drag-and-drop interface
- 🌙 Beautiful color schemes and themes

### 🚀 **Technical Features**
- ⚡ FastAPI backend with high performance
- 🗃️ SQLite database with SQLAlchemy ORM
- 🐳 Docker containerization
- 📦 One-liner setup and deployment
- 🔄 Auto-refresh and real-time updates
- 💾 Local storage for drafts
- 🔒 Session-based authentication ready
- 📈 Scalable architecture

## 🚀 Quick Start

### One-Liner Installation & Run

```bash
python run.py
```

That's it! This single command will:
1. ✅ Check Docker installation
2. 🏗️ Build the application
3. 🚀 Start all services
4. 🌐 Open your browser automatically
5. 📋 Show you all the details

### Alternative Docker Commands

```bash
# Using Docker Compose
docker-compose up --build -d

# Using newer Docker Compose syntax
docker compose up --build -d
```

## 📋 Requirements

- 🐳 **Docker** (with Docker Compose)
- 🐍 **Python 3.11+** (for the run script)
- 🌐 **Modern web browser**

## 🖥️ Usage

### 🌐 Access the Application
- **Main Dashboard**: http://localhost:8000
- **Tasks**: http://localhost:8000/tasks  
- **Notes**: http://localhost:8000/notes

### ⌨️ Keyboard Shortcuts
- `Ctrl/Cmd + K` - Global search
- `Ctrl/Cmd + N` - New task/note
- `Ctrl/Cmd + S` - Save draft (in editor)
- `Escape` - Close modals/clear search

### 📱 Demo Account
The application starts with a demo account pre-loaded with sample data:
- 📊 Sample projects and tasks
- 📝 Example notes with rich content
- 🎨 Organized folders and categories

## 🏗️ Architecture

```
TodoNotes/
├── app/                    # FastAPI application
│   ├── main.py            # Main application & routes
│   ├── database.py        # Database models & config
│   ├── static/            # CSS, JS, uploads
│   └── templates/         # Jinja2 HTML templates
├── backend/               # File storage
│   ├── uploads/           # User uploads
│   └── logs/              # Application logs
├── requirements.txt       # Python dependencies
├── Dockerfile            # Container configuration
├── docker-compose.yml    # Multi-service setup
└── run.py                # One-liner runner script
```

## 🛠️ Development

### Local Development Setup
```bash
# Clone and enter directory
git clone <repository>
cd todonotes

# Install dependencies
pip install -r requirements.txt

# Run development server
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 🐳 Docker Development
```bash
# Build development image
docker build -t todonotes .

# Run with hot reload
docker run -p 8000:8000 -v $(pwd):/app todonotes
```

## 🎨 Customization

### 🎨 **Theming**
- Modify CSS variables in `app/static/css/main.css`
- Update color schemes and gradients
- Add custom animations and transitions

### 🗃️ **Database**
- SQLite by default (production-ready)
- Easy PostgreSQL/MySQL migration
- Pre-configured SQLAlchemy models

### 🔧 **Configuration**
- Environment variables in `docker-compose.yml`
- Upload limits and file types
- Database connections and paths

## 📊 Features Comparison

| Feature | TodoNotes | Todoist | Samsung Notes |
|---------|-----------|---------|---------------|
| ✅ Task Management | ✅ | ✅ | ❌ |
| 📝 Rich Text Notes | ✅ | ❌ | ✅ |
| 🖼️ File Attachments | ✅ | ✅ | ✅ |
| 📁 Organization | ✅ | ✅ | ✅ |
| 🔍 Global Search | ✅ | ✅ | ✅ |
| 📱 Responsive Design | ✅ | ✅ | ✅ |
| 🐳 Self-Hosted | ✅ | ❌ | ❌ |
| 💰 Free | ✅ | Limited | ❌ |
| ⚡ Fast Performance | ✅ | ✅ | ✅ |
| 🎨 Beautiful UI | ✅ | ✅ | ✅ |

## 🤝 Contributing

1. 🍴 Fork the repository
2. 🌿 Create your feature branch (`git checkout -b feature/amazing-feature`)
3. 💾 Commit your changes (`git commit -m 'Add amazing feature'`)
4. 📤 Push to the branch (`git push origin feature/amazing-feature`)
5. 🔄 Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- 🎨 **UI Design**: Inspired by modern productivity apps
- 📝 **Rich Text Editor**: Powered by Quill.js
- ⚡ **Backend**: Built with FastAPI
- 🐳 **Deployment**: Docker & Docker Compose
- 🎯 **Icons**: Font Awesome
- 🌈 **Fonts**: Inter typeface

## 📞 Support

- 📧 **Issues**: [GitHub Issues](https://github.com/yourusername/todonotes/issues)
- 📖 **Documentation**: [Wiki](https://github.com/yourusername/todonotes/wiki)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/yourusername/todonotes/discussions)

---

Made with ❤️ for productivity enthusiasts who want the best of both worlds: powerful task management and beautiful note-taking in one application.