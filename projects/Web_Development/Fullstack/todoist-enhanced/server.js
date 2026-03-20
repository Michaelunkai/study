const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = 3456;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(express.static('public'));

// Database (JSON file-based)
const DB_FILE = path.join(__dirname, 'db.json');

// Initialize database
function initDB() {
  if (!fs.existsSync(DB_FILE)) {
    const initialData = {
      projects: [],
      tasks: [],
      labels: [],
      filters: [],
      comments: [],
      activityLog: [],
      settings: {
        theme: 'light',
        defaultView: 'today',
        startOfWeek: 1
      },
      stats: {
        totalTasksCompleted: 0,
        currentStreak: 0,
        longestStreak: 0,
        karma: 0
      }
    };
    fs.writeFileSync(DB_FILE, JSON.stringify(initialData, null, 2));
  }
}

function readDB() {
  return JSON.parse(fs.readFileSync(DB_FILE, 'utf8'));
}

function writeDB(data) {
  try {
    // Write to main database
    fs.writeFileSync(DB_FILE, JSON.stringify(data, null, 2));
    
    // Create automatic backup every write
    const backupDir = path.join(__dirname, 'backups');
    if (!fs.existsSync(backupDir)) {
      fs.mkdirSync(backupDir);
    }
    
    // Keep hourly backups
    const timestamp = new Date().toISOString().replace(/:/g, '-').split('.')[0];
    const backupFile = path.join(backupDir, `backup-${timestamp}.json`);
    fs.writeFileSync(backupFile, JSON.stringify(data, null, 2));
    
    // Keep only last 24 backups (one per hour max)
    const backups = fs.readdirSync(backupDir)
      .filter(f => f.startsWith('backup-'))
      .sort()
      .reverse();
    
    if (backups.length > 24) {
      backups.slice(24).forEach(f => {
        try {
          fs.unlinkSync(path.join(backupDir, f));
        } catch (err) {}
      });
    }
    
    console.log(`[SAVE] Database saved successfully at ${new Date().toISOString()}`);
  } catch (error) {
    console.error('[ERROR] Failed to save database:', error);
    throw error;
  }
}

function logActivity(action, details) {
  const db = readDB();
  db.activityLog.unshift({
    id: uuidv4(),
    action,
    details,
    timestamp: new Date().toISOString()
  });
  if (db.activityLog.length > 1000) {
    db.activityLog = db.activityLog.slice(0, 1000);
  }
  writeDB(db);
}

// Projects API
app.get('/api/projects', (req, res) => {
  const db = readDB();
  res.json(db.projects);
});

app.post('/api/projects', (req, res) => {
  const db = readDB();
  const project = {
    id: uuidv4(),
    name: req.body.name,
    color: req.body.color || '#808080',
    isFavorite: req.body.isFavorite || false,
    viewStyle: req.body.viewStyle || 'list',
    parentId: req.body.parentId || null,
    order: db.projects.length,
    createdAt: new Date().toISOString()
  };
  db.projects.push(project);
  writeDB(db);
  logActivity('project_created', { projectName: project.name });
  res.json(project);
});

app.put('/api/projects/:id', (req, res) => {
  const db = readDB();
  const index = db.projects.findIndex(p => p.id === req.params.id);
  if (index === -1) return res.status(404).json({ error: 'Project not found' });
  
  db.projects[index] = { ...db.projects[index], ...req.body };
  writeDB(db);
  logActivity('project_updated', { projectName: db.projects[index].name });
  res.json(db.projects[index]);
});

app.delete('/api/projects/:id', (req, res) => {
  const db = readDB();
  const project = db.projects.find(p => p.id === req.params.id);
  if (!project) return res.status(404).json({ error: 'Project not found' });
  
  db.projects = db.projects.filter(p => p.id !== req.params.id);
  db.tasks = db.tasks.filter(t => t.projectId !== req.params.id);
  writeDB(db);
  logActivity('project_deleted', { projectName: project.name });
  res.json({ success: true });
});

// Tasks API
app.get('/api/tasks', (req, res) => {
  const db = readDB();
  let tasks = db.tasks;
  
  if (req.query.projectId) {
    tasks = tasks.filter(t => t.projectId === req.query.projectId);
  }
  if (req.query.filter === 'today') {
    const today = new Date().toISOString().split('T')[0];
    tasks = tasks.filter(t => t.dueDate && t.dueDate.startsWith(today));
  }
  if (req.query.filter === 'upcoming') {
    const today = new Date();
    tasks = tasks.filter(t => t.dueDate && new Date(t.dueDate) > today);
  }
  
  res.json(tasks);
});

app.post('/api/tasks', (req, res) => {
  console.log('[API] POST /api/tasks - Request body:', req.body);
  const db = readDB();
  const task = {
    id: uuidv4(),
    content: req.body.content,
    description: req.body.description || '',
    projectId: req.body.projectId || null,
    parentId: req.body.parentId || null,
    priority: req.body.priority || 1,
    dueDate: req.body.dueDate || null,
    labels: req.body.labels || [],
    completed: false,
    order: db.tasks.length,
    createdAt: new Date().toISOString(),
    recurring: req.body.recurring || null
  };
  db.tasks.push(task);
  writeDB(db);
  logActivity('task_created', { taskContent: task.content });
  console.log(`[API] Task created successfully! ID: ${task.id}, Content: "${task.content}"`);
  res.json(task);
});

app.put('/api/tasks/:id', (req, res) => {
  const db = readDB();
  const index = db.tasks.findIndex(t => t.id === req.params.id);
  if (index === -1) return res.status(404).json({ error: 'Task not found' });
  
  db.tasks[index] = { ...db.tasks[index], ...req.body };
  writeDB(db);
  logActivity('task_updated', { taskContent: db.tasks[index].content });
  res.json(db.tasks[index]);
});

app.post('/api/tasks/:id/complete', (req, res) => {
  const db = readDB();
  const index = db.tasks.findIndex(t => t.id === req.params.id);
  if (index === -1) return res.status(404).json({ error: 'Task not found' });
  
  db.tasks[index].completed = true;
  db.tasks[index].completedAt = new Date().toISOString();
  db.stats.totalTasksCompleted++;
  db.stats.karma += db.tasks[index].priority * 5;
  
  writeDB(db);
  logActivity('task_completed', { taskContent: db.tasks[index].content });
  res.json(db.tasks[index]);
});

app.delete('/api/tasks/:id', (req, res) => {
  const db = readDB();
  const task = db.tasks.find(t => t.id === req.params.id);
  if (!task) return res.status(404).json({ error: 'Task not found' });
  
  db.tasks = db.tasks.filter(t => t.id !== req.params.id && t.parentId !== req.params.id);
  writeDB(db);
  logActivity('task_deleted', { taskContent: task.content });
  res.json({ success: true });
});

// Labels API
app.get('/api/labels', (req, res) => {
  const db = readDB();
  res.json(db.labels);
});

app.post('/api/labels', (req, res) => {
  const db = readDB();
  const label = {
    id: uuidv4(),
    name: req.body.name,
    color: req.body.color || '#808080',
    order: db.labels.length
  };
  db.labels.push(label);
  writeDB(db);
  res.json(label);
});

// Comments API
app.get('/api/tasks/:taskId/comments', (req, res) => {
  const db = readDB();
  const comments = db.comments.filter(c => c.taskId === req.params.taskId);
  res.json(comments);
});

app.post('/api/tasks/:taskId/comments', (req, res) => {
  const db = readDB();
  const comment = {
    id: uuidv4(),
    taskId: req.params.taskId,
    content: req.body.content,
    createdAt: new Date().toISOString()
  };
  db.comments.push(comment);
  writeDB(db);
  res.json(comment);
});

// Activity Log
app.get('/api/activity', (req, res) => {
  const db = readDB();
  res.json(db.activityLog.slice(0, 100));
});

// Stats
app.get('/api/stats', (req, res) => {
  const db = readDB();
  res.json(db.stats);
});

// Settings
app.get('/api/settings', (req, res) => {
  const db = readDB();
  res.json(db.settings);
});

app.put('/api/settings', (req, res) => {
  const db = readDB();
  db.settings = { ...db.settings, ...req.body };
  writeDB(db);
  res.json(db.settings);
});

// Search
app.get('/api/search', (req, res) => {
  const db = readDB();
  const query = req.query.q.toLowerCase();
  const results = {
    tasks: db.tasks.filter(t => 
      t.content.toLowerCase().includes(query) || 
      (t.description && t.description.toLowerCase().includes(query))
    ),
    projects: db.projects.filter(p => p.name.toLowerCase().includes(query))
  };
  res.json(results);
});

// Time Tracking
app.post('/api/tasks/:id/start-timer', (req, res) => {
  const db = readDB();
  const index = db.tasks.findIndex(t => t.id === req.params.id);
  if (index === -1) return res.status(404).json({ error: 'Task not found' });
  
  db.tasks[index].timeTracking = {
    active: true,
    startTime: new Date().toISOString(),
    totalTime: db.tasks[index].timeTracking?.totalTime || 0
  };
  writeDB(db);
  res.json(db.tasks[index]);
});

app.post('/api/tasks/:id/stop-timer', (req, res) => {
  const db = readDB();
  const index = db.tasks.findIndex(t => t.id === req.params.id);
  if (index === -1) return res.status(404).json({ error: 'Task not found' });
  
  const task = db.tasks[index];
  if (task.timeTracking?.active) {
    const elapsed = Date.now() - new Date(task.timeTracking.startTime).getTime();
    task.timeTracking.totalTime += elapsed;
    task.timeTracking.active = false;
  }
  writeDB(db);
  res.json(db.tasks[index]);
});

// Export
app.get('/api/export', (req, res) => {
  const db = readDB();
  const format = req.query.format || 'json';
  
  if (format === 'json') {
    res.json(db);
  } else if (format === 'csv') {
    const csv = convertToCSV(db.tasks);
    res.header('Content-Type', 'text/csv');
    res.attachment('todoist-export.csv');
    res.send(csv);
  }
});

function convertToCSV(tasks) {
  const headers = ['ID', 'Content', 'Description', 'Priority', 'Due Date', 'Completed', 'Created At'];
  const rows = tasks.map(t => [
    t.id,
    `"${t.content}"`,
    `"${t.description || ''}"`,
    t.priority,
    t.dueDate || '',
    t.completed,
    t.createdAt
  ]);
  return [headers.join(','), ...rows.map(r => r.join(','))].join('\n');
}

// Import
app.post('/api/import', (req, res) => {
  const db = readDB();
  const importData = req.body;
  
  if (importData.tasks) {
    db.tasks = [...db.tasks, ...importData.tasks.map(t => ({ ...t, id: uuidv4() }))];
  }
  if (importData.projects) {
    db.projects = [...db.projects, ...importData.projects.map(p => ({ ...p, id: uuidv4() }))];
  }
  
  writeDB(db);
  logActivity('data_imported', { count: importData.tasks?.length || 0 });
  res.json({ success: true, imported: { tasks: importData.tasks?.length || 0 } });
});

// Recurring Tasks - Process Daily
function processRecurringTasks() {
  const db = readDB();
  const today = new Date();
  
  db.tasks.forEach(task => {
    if (task.recurring && task.completed && task.completedAt) {
      const completedDate = new Date(task.completedAt);
      const shouldRecreate = checkRecurrenceCondition(completedDate, today, task.recurring);
      
      if (shouldRecreate) {
        const newTask = {
          ...task,
          id: uuidv4(),
          completed: false,
          completedAt: null,
          dueDate: calculateNextDueDate(task.dueDate, task.recurring),
          createdAt: new Date().toISOString()
        };
        db.tasks.push(newTask);
        logActivity('recurring_task_created', { taskContent: newTask.content });
      }
    }
  });
  
  writeDB(db);
}

function checkRecurrenceCondition(lastCompleted, today, recurrence) {
  const daysDiff = Math.floor((today - lastCompleted) / (1000 * 60 * 60 * 24));
  
  if (recurrence.interval === 'daily') {
    return daysDiff >= (recurrence.every || 1);
  } else if (recurrence.interval === 'weekly') {
    return daysDiff >= (7 * (recurrence.every || 1));
  } else if (recurrence.interval === 'monthly') {
    const monthsDiff = (today.getFullYear() - lastCompleted.getFullYear()) * 12 + 
                       (today.getMonth() - lastCompleted.getMonth());
    return monthsDiff >= (recurrence.every || 1);
  }
  return false;
}

function calculateNextDueDate(currentDueDate, recurrence) {
  if (!currentDueDate) return null;
  
  const date = new Date(currentDueDate);
  
  if (recurrence.interval === 'daily') {
    date.setDate(date.getDate() + (recurrence.every || 1));
  } else if (recurrence.interval === 'weekly') {
    date.setDate(date.getDate() + (7 * (recurrence.every || 1)));
  } else if (recurrence.interval === 'monthly') {
    date.setMonth(date.getMonth() + (recurrence.every || 1));
  }
  
  return date.toISOString().split('T')[0];
}

// Run recurring tasks check daily
setInterval(processRecurringTasks, 24 * 60 * 60 * 1000); // Once per day

// Initialize and start server
initDB();
processRecurringTasks(); // Run once on startup
app.listen(PORT, () => {
  console.log(`Todoist Enhanced running on http://localhost:${PORT}`);
});
