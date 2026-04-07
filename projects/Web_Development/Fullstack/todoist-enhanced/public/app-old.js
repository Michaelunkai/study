const API_BASE = 'http://localhost:3456/api';

let currentView = 'inbox';
let currentProjectId = null;
let projects = [];
let tasks = [];
let labels = [];
let stats = {};

// Initialize app
document.addEventListener('DOMContentLoaded', async () => {
    await loadInitialData();
    setupEventListeners();
    renderView();
});

// Load initial data with localStorage backup
async function loadInitialData() {
    try {
        const [projectsRes, tasksRes, labelsRes, statsRes] = await Promise.all([
            fetch(`${API_BASE}/projects`),
            fetch(`${API_BASE}/tasks`),
            fetch(`${API_BASE}/labels`),
            fetch(`${API_BASE}/stats`)
        ]);

        projects = await projectsRes.json();
        tasks = await tasksRes.json();
        labels = await labelsRes.json();
        stats = await statsRes.json();

        // Backup to localStorage immediately after loading
        saveToLocalStorage();

        renderProjects();
        updateCounts();
        updateStats();
        
        console.log(`[LOADED] ${tasks.length} tasks, ${projects.length} projects, ${labels.length} labels`);
    } catch (error) {
        console.error('Failed to load data from server:', error);
        // Try to restore from localStorage backup
        restoreFromLocalStorage();
    }
}

// Save all data to localStorage as backup
function saveToLocalStorage() {
    try {
        const backup = {
            tasks,
            projects,
            labels,
            stats,
            timestamp: new Date().toISOString()
        };
        localStorage.setItem('todoistEnhanced_backup', JSON.stringify(backup));
        console.log('[BACKUP] Data backed up to localStorage');
    } catch (error) {
        console.error('[BACKUP ERROR]', error);
    }
}

// Restore from localStorage if server fails
function restoreFromLocalStorage() {
    try {
        const backup = localStorage.getItem('todoistEnhanced_backup');
        if (backup) {
            const data = JSON.parse(backup);
            tasks = data.tasks || [];
            projects = data.projects || [];
            labels = data.labels || [];
            stats = data.stats || {};
            
            renderProjects();
            updateCounts();
            updateStats();
            renderView();
            
            showToast('⚠️ Restored from local backup (server offline)', 'warning');
            console.log(`[RESTORED] From backup: ${tasks.length} tasks, ${projects.length} projects`);
        } else {
            showToast('❌ No server connection and no backup found', 'error');
        }
    } catch (error) {
        console.error('[RESTORE ERROR]', error);
        showToast('❌ Failed to restore backup', 'error');
    }
}

// Auto-save to localStorage every time data changes
function autoBackup() {
    saveToLocalStorage();
}

// Setup event listeners
function setupEventListeners() {
    // Quick add button - FIXED to set context based on current view
    document.getElementById('quickAddBtn').addEventListener('click', () => {
        const taskInput = document.getElementById('taskInput');
        taskInput.focus();
        
        // Auto-set due date if in Today view
        if (currentView === 'today') {
            const dueDateInput = document.getElementById('dueDateInput');
            if (dueDateInput && !dueDateInput.value) {
                dueDateInput.value = new Date().toISOString().split('T')[0];
                // Show the details row
                document.getElementById('taskDetailsRow').style.display = 'flex';
            }
        }
        
        // Auto-set project if in project view
        if (currentProjectId) {
            const projectSelect = document.getElementById('projectSelect');
            if (projectSelect) {
                projectSelect.value = currentProjectId;
            }
        }
    });

    // Task input - IMPROVED with better feedback
    const taskInput = document.getElementById('taskInput');
    
    taskInput.addEventListener('focus', () => {
        // Show details row when focusing
        const detailsRow = document.getElementById('taskDetailsRow');
        if (detailsRow) detailsRow.style.display = 'flex';
        
        // Auto-set context based on current view
        if (currentView === 'today') {
            const dueDateInput = document.getElementById('dueDateInput');
            if (dueDateInput && !dueDateInput.value) {
                dueDateInput.value = new Date().toISOString().split('T')[0];
            }
        }
    });

    taskInput.addEventListener('keypress', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            const content = taskInput.value.trim();
            if (content) {
                addTask();
            } else {
                showToast('⚠️ Task cannot be empty', 'warning');
            }
        }
    });
    
    // Blur handler - collapse if empty
    taskInput.addEventListener('blur', () => {
        setTimeout(() => {
            if (!taskInput.value.trim() && !document.activeElement.closest('#taskDetailsRow')) {
                const detailsRow = document.getElementById('taskDetailsRow');
                if (detailsRow) detailsRow.style.display = 'none';
            }
        }, 200);
    });

    // Add task button
    document.getElementById('addTaskBtn').addEventListener('click', addTask);

    // Cancel button
    document.getElementById('cancelTaskBtn').addEventListener('click', () => {
        document.getElementById('taskInput').value = '';
        document.getElementById('taskDetailsRow').style.display = 'none';
    });

    // Navigation items
    document.querySelectorAll('.nav-item').forEach(item => {
        item.addEventListener('click', () => {
            const view = item.dataset.view;
            if (view) switchView(view);
        });
    });

    // Add project button
    document.getElementById('addProjectBtn').addEventListener('click', () => {
        openModal('projectModal');
    });

    // Save project button
    document.getElementById('saveProjectBtn').addEventListener('click', saveProject);

    // Search input
    document.getElementById('searchInput').addEventListener('input', (e) => {
        searchTasks(e.target.value);
    });

    // Populate label select
    populateLabelSelect();
}

// Add task - FIXED to always show and save correctly
async function addTask() {
    const content = document.getElementById('taskInput').value.trim();
    if (!content) {
        showToast('⚠️ Please enter a task description', 'warning');
        return;
    }

    const dueDate = document.getElementById('dueDateInput').value || null;
    const priority = parseInt(document.getElementById('priorityInput').value) || 1;
    const labelSelect = document.getElementById('labelInput');
    const selectedLabels = labelSelect ? Array.from(labelSelect.selectedOptions).map(opt => opt.value).filter(v => v) : [];
    const projectSelect = document.getElementById('projectSelect');
    const projectId = projectSelect ? projectSelect.value : currentProjectId;
    const description = document.getElementById('taskDescription')?.value || '';
    const recurringSelect = document.getElementById('recurringSelect');
    const recurring = recurringSelect && recurringSelect.value ? { interval: recurringSelect.value, every: 1 } : null;

    const task = {
        content,
        description,
        dueDate,
        priority,
        labels: selectedLabels,
        projectId: projectId || null,
        recurring,
        completed: false,
        createdAt: new Date().toISOString()
    };

    console.log('[ADD TASK] Creating:', task);

    try {
        const response = await fetch(`${API_BASE}/tasks`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(task)
        });

        if (!response.ok) {
            throw new Error(`Server returned ${response.status}`);
        }

        const newTask = await response.json();
        tasks.push(newTask);

        console.log('[ADD TASK] Success! Task ID:', newTask.id);

        // Clear form
        document.getElementById('taskInput').value = '';
        if (document.getElementById('dueDateInput')) document.getElementById('dueDateInput').value = '';
        if (document.getElementById('priorityInput')) document.getElementById('priorityInput').value = '1';
        if (document.getElementById('taskDescription')) document.getElementById('taskDescription').value = '';
        if (document.getElementById('recurringSelect')) document.getElementById('recurringSelect').value = '';
        const detailsRow = document.getElementById('taskDetailsRow');
        if (detailsRow) detailsRow.style.display = 'none';

        // AUTO-BACKUP: Save to localStorage
        autoBackup();

        // ALWAYS re-render and update counts
        renderView();
        updateCounts();
        
        // Show success notification
        showToast(`✅ Task created: "${content}"`, 'success');
        
        // If in a filtered view and task doesn't match, suggest switching
        if (currentView === 'today' && (!dueDate || !dueDate.startsWith(new Date().toISOString().split('T')[0]))) {
            setTimeout(() => {
                showToast('💡 Task saved to Inbox (not due today)', 'info');
            }, 1500);
        }
        
    } catch (error) {
        console.error('[ADD TASK ERROR]', error);
        showToast('❌ Failed to add task. Check console.', 'error');
        
        // Even if server fails, add to local array
        const localTask = {
            ...task,
            id: 'local_' + Date.now(),
            createdAt: new Date().toISOString()
        };
        tasks.push(localTask);
        renderView();
        updateCounts();
        autoBackup();
        showToast('⚠️ Task saved locally (server error)', 'warning');
    }
}

// Complete task
async function completeTask(taskId) {
    try {
        await fetch(`${API_BASE}/tasks/${taskId}/complete`, {
            method: 'POST'
        });

        const task = tasks.find(t => t.id === taskId);
        if (task) task.completed = true;

        // Update stats
        stats.totalTasksCompleted++;
        stats.karma += task.priority * 5;

        // AUTO-BACKUP: Save to localStorage
        autoBackup();

        renderView();
        updateCounts();
        updateStats();

        // Show completion animation
        showNotification('Task completed! 🎉');
    } catch (error) {
        console.error('Failed to complete task:', error);
    }
}

// Delete task with undo option
let lastDeletedTask = null;

async function deleteTask(taskId) {
    const task = tasks.find(t => t.id === taskId);
    if (!task) return;
    
    // Store for undo
    lastDeletedTask = { ...task };
    
    try {
        await fetch(`${API_BASE}/tasks/${taskId}`, {
            method: 'DELETE'
        });

        tasks = tasks.filter(t => t.id !== taskId);
        
        // AUTO-BACKUP: Save to localStorage
        autoBackup();
        
        renderView();
        updateCounts();
        
        // Show undo notification
        showUndoNotification(task.content);
    } catch (error) {
        console.error('Failed to delete task:', error);
        showNotification('Failed to delete task', 'error');
    }
}

// Show undo notification with action
function showUndoNotification(taskName) {
    const existing = document.querySelector('.undo-notification');
    if (existing) existing.remove();
    
    const notification = document.createElement('div');
    notification.className = 'undo-notification';
    notification.innerHTML = `
        <span>🗑️ Deleted "${taskName.length > 30 ? taskName.substring(0, 30) + '...' : taskName}"</span>
        <button onclick="undoDelete()">Undo</button>
    `;
    notification.style.cssText = `
        position: fixed;
        bottom: 20px;
        left: 50%;
        transform: translateX(-50%);
        background: var(--bg-secondary);
        color: var(--text-primary);
        padding: 12px 20px;
        border-radius: 8px;
        display: flex;
        align-items: center;
        gap: 16px;
        box-shadow: 0 8px 24px rgba(0,0,0,0.2);
        z-index: 10000;
        animation: slideIn 0.3s ease;
    `;
    
    const btn = notification.querySelector('button');
    btn.style.cssText = `
        background: var(--primary);
        color: white;
        border: none;
        padding: 6px 16px;
        border-radius: 4px;
        cursor: pointer;
        font-weight: 600;
    `;
    
    document.body.appendChild(notification);
    
    // Auto-remove after 8 seconds
    setTimeout(() => {
        if (notification.parentElement) {
            notification.remove();
            lastDeletedTask = null;
        }
    }, 8000);
}

// Undo delete
async function undoDelete() {
    if (!lastDeletedTask) return;
    
    try {
        const response = await fetch(`${API_BASE}/tasks`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(lastDeletedTask)
        });
        
        const restoredTask = await response.json();
        tasks.push(restoredTask);
        
        document.querySelector('.undo-notification')?.remove();
        lastDeletedTask = null;
        
        renderView();
        updateCounts();
        showNotification('Task restored! ↩️');
    } catch (error) {
        console.error('Failed to restore task:', error);
    }
}

// Edit task
async function editTask(taskId) {
    const task = tasks.find(t => t.id === taskId);
    if (!task) return;

    const newContent = prompt('Edit task:', task.content);
    if (!newContent || newContent === task.content) return;

    try {
        const response = await fetch(`${API_BASE}/tasks/${taskId}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ content: newContent })
        });

        const updatedTask = await response.json();
        const index = tasks.findIndex(t => t.id === taskId);
        tasks[index] = updatedTask;

        renderView();
    } catch (error) {
        console.error('Failed to update task:', error);
    }
}

// Save project
async function saveProject() {
    const name = document.getElementById('projectNameInput').value.trim();
    if (!name) return;

    const color = document.getElementById('projectColorInput').value;

    try {
        const response = await fetch(`${API_BASE}/projects`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name, color })
        });

        const newProject = await response.json();
        projects.push(newProject);

        // Clear form
        document.getElementById('projectNameInput').value = '';
        document.getElementById('projectColorInput').value = '#808080';

        // AUTO-BACKUP: Save to localStorage
        autoBackup();

        closeModal('projectModal');
        renderProjects();
    } catch (error) {
        console.error('Failed to create project:', error);
    }
}

// Wrapper for autoBackup to ensure it's called everywhere
window.addEventListener('beforeunload', () => {
    // One final backup before closing
    autoBackup();
});

// Periodic auto-backup every 30 seconds
setInterval(() => {
    autoBackup();
}, 30000);

// Switch view
function switchView(view, projectId = null) {
    currentView = view;
    currentProjectId = projectId;

    // Update active nav item
    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.remove('active');
        if (item.dataset.view === view) {
            item.classList.add('active');
        }
    });

    renderView();
}

// Render view
function renderView() {
    const viewTitle = document.getElementById('viewTitle');
    const tasksContainer = document.getElementById('tasksContainer');
    const statsView = document.getElementById('statsView');
    const activityView = document.getElementById('activityView');
    const completedView = document.getElementById('completedView');
    const calendarView = document.getElementById('calendarView');

    // Hide all views
    tasksContainer.style.display = 'none';
    statsView.style.display = 'none';
    activityView.style.display = 'none';
    if (completedView) completedView.style.display = 'none';
    if (calendarView) calendarView.style.display = 'none';

    // Update active nav item
    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.remove('active');
        if (item.dataset.view === currentView) {
            item.classList.add('active');
        }
    });

    if (currentView === 'stats') {
        viewTitle.textContent = '📊 Statistics';
        statsView.style.display = 'block';
        renderStats();
    } else if (currentView === 'activity') {
        viewTitle.textContent = '⏱️ Activity Log';
        activityView.style.display = 'block';
        renderActivity();
    } else if (currentView === 'completed') {
        viewTitle.textContent = '✅ Completed';
        if (completedView) {
            completedView.style.display = 'block';
            renderCompletedView();
        }
    } else {
        tasksContainer.style.display = 'block';
        renderTasks();
    }
    
    // Update project select and labels
    populateProjectSelect();
    renderLabels();
}

// Render tasks - FIXED to always show tasks correctly
function renderTasks() {
    const viewTitle = document.getElementById('viewTitle');
    const tasksList = document.getElementById('tasksList');

    // Filter out completed tasks AND subtasks (parentId is set)
    let filteredTasks = tasks.filter(t => !t.completed && !t.parentId);
    
    console.log(`[RENDER] View: ${currentView}, Total uncompleted tasks: ${filteredTasks.length}`);

    if (currentView === 'inbox') {
        viewTitle.textContent = '📥 Inbox';
        filteredTasks = filteredTasks.filter(t => !t.projectId);
        console.log(`[RENDER] Inbox: ${filteredTasks.length} tasks`);
    } else if (currentView === 'today') {
        viewTitle.textContent = '📅 Today';
        const today = new Date().toISOString().split('T')[0];
        filteredTasks = filteredTasks.filter(t => {
            // Show tasks due today OR tasks with no due date (so new tasks appear)
            return (t.dueDate && t.dueDate.startsWith(today));
        });
        console.log(`[RENDER] Today (${today}): ${filteredTasks.length} tasks`);
    } else if (currentView === 'upcoming') {
        viewTitle.textContent = '🗓️ Upcoming';
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        filteredTasks = filteredTasks.filter(t => {
            if (!t.dueDate) return false;
            const taskDate = new Date(t.dueDate);
            taskDate.setHours(0, 0, 0, 0);
            return taskDate > today;
        });
        filteredTasks.sort((a, b) => new Date(a.dueDate) - new Date(b.dueDate));
        console.log(`[RENDER] Upcoming: ${filteredTasks.length} tasks`);
    } else if (currentProjectId) {
        const project = projects.find(p => p.id === currentProjectId);
        viewTitle.textContent = project ? `📁 ${project.name}` : 'Project';
        filteredTasks = filteredTasks.filter(t => t.projectId === currentProjectId);
        console.log(`[RENDER] Project ${currentProjectId}: ${filteredTasks.length} tasks`);
    }

    if (filteredTasks.length === 0) {
        const emptyMessages = {
            inbox: 'No tasks in Inbox. Everything is organized! 🎯',
            today: 'No tasks due today. Enjoy your day! ☀️',
            upcoming: 'No upcoming tasks. All caught up! ✨',
            default: 'No tasks here yet. Add one above! ✍️'
        };
        const message = emptyMessages[currentView] || emptyMessages.default;
        
        tasksList.innerHTML = `
            <div class="empty-state">
                <div class="empty-state-icon">✓</div>
                <div class="empty-state-text">${message}</div>
                <button class="btn-primary" onclick="document.getElementById('taskInput').focus()" style="margin-top: 20px;">
                    ➕ Add Your First Task
                </button>
            </div>
        `;
        return;
    }

    tasksList.innerHTML = filteredTasks.map(task => renderTaskItem(task)).join('');
    console.log(`[RENDER] Rendered ${filteredTasks.length} task items`);
}

// Render projects with edit/delete buttons
function renderProjects() {
    const projectsList = document.getElementById('projectsList');

    if (projects.length === 0) {
        projectsList.innerHTML = '<div style="padding: 10px; color: #999; font-size: 13px;">No projects yet</div>';
        return;
    }

    projectsList.innerHTML = projects.map(project => `
        <div class="nav-item project-item ${currentProjectId === project.id ? 'active' : ''}" onclick="switchView('project', '${project.id}')">
            <span class="icon" style="color: ${project.color}">●</span>
            <span class="label">${escapeHtml(project.name)}</span>
            <div class="project-actions" style="display: flex; gap: 4px; opacity: 0; transition: opacity 0.2s;">
                <button class="btn-icon-small" onclick="event.stopPropagation(); editProject('${project.id}')" title="Edit">✏️</button>
                <button class="btn-icon-small" onclick="event.stopPropagation(); deleteProject('${project.id}')" title="Delete">🗑️</button>
            </div>
        </div>
    `).join('');
    
    // Add hover effect for project actions
    document.querySelectorAll('.project-item').forEach(item => {
        item.addEventListener('mouseenter', () => {
            const actions = item.querySelector('.project-actions');
            if (actions) actions.style.opacity = '1';
        });
        item.addEventListener('mouseleave', () => {
            const actions = item.querySelector('.project-actions');
            if (actions) actions.style.opacity = '0';
        });
    });
}

// Edit project
async function editProject(projectId) {
    const project = projects.find(p => p.id === projectId);
    if (!project) return;
    
    const newName = prompt('Edit project name:', project.name);
    if (!newName || newName === project.name) return;
    
    try {
        const response = await fetch(`${API_BASE}/projects/${projectId}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name: newName })
        });
        
        const updatedProject = await response.json();
        const index = projects.findIndex(p => p.id === projectId);
        projects[index] = updatedProject;
        
        autoBackup();
        renderProjects();
        showToast(`📁 Project renamed to "${newName}"`, 'success');
    } catch (error) {
        console.error('Failed to update project:', error);
        showToast('Failed to update project', 'error');
    }
}

// Delete project
async function deleteProject(projectId) {
    const project = projects.find(p => p.id === projectId);
    if (!project) return;
    
    const taskCount = tasks.filter(t => t.projectId === projectId).length;
    const confirmMsg = taskCount > 0 
        ? `Delete project "${project.name}" and its ${taskCount} task(s)?`
        : `Delete project "${project.name}"?`;
    
    if (!confirm(confirmMsg)) return;
    
    try {
        await fetch(`${API_BASE}/projects/${projectId}`, {
            method: 'DELETE'
        });
        
        projects = projects.filter(p => p.id !== projectId);
        // Move tasks to Inbox
        tasks.forEach(t => {
            if (t.projectId === projectId) {
                t.projectId = null;
            }
        });
        
        if (currentProjectId === projectId) {
            switchView('inbox');
        }
        
        autoBackup();
        renderProjects();
        renderView();
        showToast(`🗑️ Project "${project.name}" deleted`, 'success');
    } catch (error) {
        console.error('Failed to delete project:', error);
        showToast('Failed to delete project', 'error');
    }
}

// Render stats
function renderStats() {
    document.getElementById('totalCompleted').textContent = stats.totalTasksCompleted || 0;
    document.getElementById('currentStreak').textContent = stats.currentStreak || 0;
    document.getElementById('longestStreak').textContent = stats.longestStreak || 0;
    document.getElementById('totalKarma').textContent = stats.karma || 0;
}

// Render activity log
async function renderActivity() {
    try {
        const response = await fetch(`${API_BASE}/activity`);
        const activities = await response.json();

        const activityList = document.getElementById('activityList');

        if (activities.length === 0) {
            activityList.innerHTML = '<div class="empty-state"><div class="empty-state-text">No activity yet</div></div>';
            return;
        }

        activityList.innerHTML = activities.map(activity => `
            <div class="activity-item">
                <div class="activity-icon">${getActivityIcon(activity.action)}</div>
                <div class="activity-content">
                    <div class="activity-text">${getActivityText(activity)}</div>
                    <div class="activity-time">${formatRelativeTime(activity.timestamp)}</div>
                </div>
            </div>
        `).join('');
    } catch (error) {
        console.error('Failed to load activity:', error);
    }
}

// Search tasks
async function searchTasks(query) {
    if (!query.trim()) {
        renderView();
        return;
    }

    try {
        const response = await fetch(`${API_BASE}/search?q=${encodeURIComponent(query)}`);
        const results = await response.json();

        const tasksList = document.getElementById('tasksList');
        const viewTitle = document.getElementById('viewTitle');

        viewTitle.textContent = `Search: "${query}"`;

        if (results.tasks.length === 0) {
            tasksList.innerHTML = '<div class="empty-state"><div class="empty-state-text">No results found</div></div>';
            return;
        }

        tasks = results.tasks;
        renderTasks();
    } catch (error) {
        console.error('Search failed:', error);
    }
}

// Update counts
function updateCounts() {
    const today = new Date().toISOString().split('T')[0];
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    
    const inboxCount = tasks.filter(t => !t.completed && !t.projectId && !t.parentId).length;
    const todayCount = tasks.filter(t => !t.completed && t.dueDate && t.dueDate.startsWith(today) && !t.parentId).length;
    const upcomingCount = tasks.filter(t => !t.completed && t.dueDate && new Date(t.dueDate) > new Date() && !t.parentId).length;
    const completedCount = tasks.filter(t => t.completed && !t.parentId).length;

    document.getElementById('inboxCount').textContent = inboxCount;
    document.getElementById('todayCount').textContent = todayCount;
    const upcomingEl = document.getElementById('upcomingCount');
    if (upcomingEl) upcomingEl.textContent = upcomingCount;
    const completedEl = document.getElementById('completedCount');
    if (completedEl) completedEl.textContent = completedCount;
}

// Render labels in sidebar
function renderLabels() {
    const labelsList = document.getElementById('labelsList');
    if (!labelsList) return;
    
    if (labels.length === 0) {
        labelsList.innerHTML = '<div style="padding: 8px 12px; color: var(--text-secondary); font-size: 12px;">No labels yet</div>';
        return;
    }
    
    labelsList.innerHTML = labels.map(label => `
        <div class="nav-item" onclick="filterByLabel('${label.id}')">
            <span class="icon" style="color: ${label.color}">●</span>
            <span class="label">${escapeHtml(label.name)}</span>
            <span class="count">${tasks.filter(t => t.labels?.includes(label.id)).length}</span>
        </div>
    `).join('');
}

// Filter tasks by label
function filterByLabel(labelId) {
    currentView = 'label';
    currentProjectId = null;
    
    const label = labels.find(l => l.id === labelId);
    document.getElementById('viewTitle').textContent = `🏷️ ${label?.name || 'Label'}`;
    
    const filteredTasks = tasks.filter(t => !t.completed && !t.parentId && t.labels?.includes(labelId));
    renderFilteredTasks(filteredTasks);
}

// Render filtered tasks
function renderFilteredTasks(filteredTasks) {
    const tasksList = document.getElementById('tasksList');
    
    if (filteredTasks.length === 0) {
        tasksList.innerHTML = `
            <div class="empty-state">
                <div class="empty-state-icon">✓</div>
                <div class="empty-state-text">No tasks found</div>
            </div>
        `;
        return;
    }
    
    tasksList.innerHTML = filteredTasks.map(task => renderTaskItem(task)).join('');
}

// Extract task item rendering for reuse
function renderTaskItem(task) {
    const subtaskCount = tasks.filter(t => t.parentId === task.id).length;
    const completedSubtasks = tasks.filter(t => t.parentId === task.id && t.completed).length;
    
    return `
        <div class="task-item priority-${task.priority} ${subtaskCount > 0 ? 'has-subtasks' : ''}" data-task-id="${task.id}" draggable="true">
            <div class="task-checkbox" onclick="event.stopPropagation(); completeTask('${task.id}')"></div>
            <div class="task-content">
                <div class="task-title">
                    ${escapeHtml(task.content)}
                    ${task.recurring ? '<span class="recurring-indicator">🔄 ' + task.recurring.interval + '</span>' : ''}
                </div>
                <div class="task-meta">
                    ${task.dueDate ? `
                        <span class="task-due-date ${isOverdue(task.dueDate) ? 'overdue' : ''}">
                            📅 ${formatDate(task.dueDate)}
                        </span>
                    ` : ''}
                    ${subtaskCount > 0 ? `
                        <span class="subtask-indicator">📋 ${completedSubtasks}/${subtaskCount}</span>
                    ` : ''}
                    ${task.labels && task.labels.length > 0 ? `
                        <div class="task-labels">
                            ${task.labels.map(labelId => {
                                const label = labels.find(l => l.id === labelId);
                                return label ? `<span class="task-label" style="background: ${label.color}22; color: ${label.color}">${label.name}</span>` : '';
                            }).join('')}
                        </div>
                    ` : ''}
                    ${task.description ? '<span class="task-has-desc" title="Has description">📝</span>' : ''}
                </div>
                ${subtaskCount > 0 ? `
                    <div class="subtask-progress">
                        <div class="subtask-progress-bar" style="width: ${subtaskCount > 0 ? (completedSubtasks / subtaskCount) * 100 : 0}%"></div>
                    </div>
                ` : ''}
            </div>
            <div class="task-actions">
                <button class="task-action-btn" onclick="event.stopPropagation(); showSubtaskInput('${task.id}')" title="Add Subtask">➕</button>
                <button class="task-action-btn" onclick="event.stopPropagation(); editTask('${task.id}')" title="Edit">✏️</button>
                <button class="task-action-btn" onclick="event.stopPropagation(); deleteTask('${task.id}')" title="Delete">🗑️</button>
            </div>
        </div>
    `;
}

// Update stats display
function updateStats() {
    document.getElementById('karmaValue').textContent = stats.karma || 0;
    document.getElementById('streakValue').textContent = `${stats.currentStreak || 0} days`;
}

// Populate label select
function populateLabelSelect() {
    const labelSelect = document.getElementById('labelInput');
    if (labelSelect) {
        labelSelect.innerHTML = labels.map(label => 
            `<option value="${label.id}">${label.name}</option>`
        ).join('');
    }
}

// Populate project select
function populateProjectSelect() {
    const projectSelect = document.getElementById('projectSelect');
    if (projectSelect) {
        projectSelect.innerHTML = '<option value="">Inbox</option>' +
            projects.map(project => `<option value="${project.id}">${project.name}</option>`).join('');
    }
}

// Render completed tasks view
function renderCompletedView() {
    const completedList = document.getElementById('completedList');
    if (!completedList) return;
    
    const completedTasks = tasks.filter(t => t.completed && !t.parentId);
    
    if (completedTasks.length === 0) {
        completedList.innerHTML = `
            <div class="empty-state">
                <div class="empty-state-icon">🎯</div>
                <div class="empty-state-text">No completed tasks yet. Get to work!</div>
            </div>
        `;
        return;
    }
    
    completedList.innerHTML = completedTasks.map(task => `
        <div class="task-item completed" data-task-id="${task.id}">
            <div class="task-checkbox checked">✓</div>
            <div class="task-content">
                <div class="task-title" style="text-decoration: line-through; color: var(--text-secondary);">
                    ${escapeHtml(task.content)}
                </div>
                <div class="task-meta">
                    ${task.completedAt ? `<span>Completed ${formatRelativeTime(task.completedAt)}</span>` : ''}
                </div>
            </div>
            <div class="task-actions">
                <button class="task-action-btn" onclick="uncompleteTask('${task.id}')" title="Restore">↩️</button>
                <button class="task-action-btn" onclick="deleteTask('${task.id}')" title="Delete">🗑️</button>
            </div>
        </div>
    `).join('');
}

// Uncomplete a task (restore)
async function uncompleteTask(taskId) {
    try {
        const response = await fetch(`${API_BASE}/tasks/${taskId}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ completed: false, completedAt: null })
        });
        
        const updatedTask = await response.json();
        const index = tasks.findIndex(t => t.id === taskId);
        tasks[index] = updatedTask;
        
        renderView();
        updateCounts();
        showNotification('Task restored ↩️');
    } catch (error) {
        console.error('Failed to restore task:', error);
    }
}

// Clear all completed tasks
async function clearCompleted() {
    if (!confirm('Delete all completed tasks? This cannot be undone.')) return;
    
    const completedTasks = tasks.filter(t => t.completed);
    for (const task of completedTasks) {
        await fetch(`${API_BASE}/tasks/${task.id}`, { method: 'DELETE' });
    }
    
    tasks = tasks.filter(t => !t.completed);
    renderView();
    updateCounts();
    showNotification(`Cleared ${completedTasks.length} completed tasks 🗑️`);
}

// Add label
async function saveLabel() {
    const name = document.getElementById('labelNameInput')?.value.trim();
    if (!name) return;
    
    const color = document.getElementById('labelColorInput')?.value || '#808080';
    
    try {
        const response = await fetch(`${API_BASE}/labels`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name, color })
        });
        
        const newLabel = await response.json();
        labels.push(newLabel);
        
        renderLabels();
        populateLabelSelect();
        closeModal('labelModal');
        document.getElementById('labelNameInput').value = '';
        showNotification('Label created! 🏷️');
    } catch (error) {
        console.error('Failed to create label:', error);
    }
}

// Initialize save label button
document.getElementById('saveLabelBtn')?.addEventListener('click', saveLabel);

// Modal functions
function openModal(modalId) {
    document.getElementById(modalId).style.display = 'flex';
}

function closeModal(modalId) {
    document.getElementById(modalId).style.display = 'none';
}

// Utility functions
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function formatDate(dateString) {
    const date = new Date(dateString);
    const today = new Date();
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    if (date.toDateString() === today.toDateString()) {
        return 'Today';
    } else if (date.toDateString() === tomorrow.toDateString()) {
        return 'Tomorrow';
    } else {
        return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    }
}

function isOverdue(dateString) {
    const date = new Date(dateString);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return date < today;
}

function formatRelativeTime(timestamp) {
    const now = new Date();
    const date = new Date(timestamp);
    const diff = Math.floor((now - date) / 1000);

    if (diff < 60) return 'Just now';
    if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
    if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
    return `${Math.floor(diff / 86400)}d ago`;
}

function getActivityIcon(action) {
    const icons = {
        task_created: '✅',
        task_completed: '✔️',
        task_deleted: '🗑️',
        task_updated: '✏️',
        project_created: '📁',
        project_updated: '📝',
        project_deleted: '🗑️'
    };
    return icons[action] || '📌';
}

function getActivityText(activity) {
    const actions = {
        task_created: 'Created task',
        task_completed: 'Completed task',
        task_deleted: 'Deleted task',
        task_updated: 'Updated task',
        project_created: 'Created project',
        project_updated: 'Updated project',
        project_deleted: 'Deleted project'
    };
    const actionText = actions[activity.action] || activity.action;
    const details = activity.details.taskContent || activity.details.projectName || '';
    return `${actionText}: ${details}`;
}

function showNotification(message) {
    // Simple notification (could be enhanced with a proper toast system)
    const notification = document.createElement('div');
    notification.textContent = message;
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: #4caf50;
        color: white;
        padding: 15px 20px;
        border-radius: 6px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.2);
        z-index: 10000;
        animation: slideIn 0.3s ease;
    `;
    document.body.appendChild(notification);

    setTimeout(() => {
        notification.remove();
    }, 3000);
}
