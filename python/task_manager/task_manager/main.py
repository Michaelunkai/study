import tkinter as tk
from tkinter import Label, Button, Entry, Listbox

tasks = []

def exit_app():
    root.destroy()

def add_task():
    task_name = task_name_entry.get()
    priority = priority_entry.get()
    due_date = due_date_entry.get()

    task_details = {"Task Name": task_name, "Priority": priority, "Due Date": due_date}
    tasks.append(task_details)

    # Clear entry fields after adding a task
    task_name_entry.delete(0, tk.END)
    priority_entry.delete(0, tk.END)
    due_date_entry.delete(0, tk.END)

    # Update the task listbox
    update_task_list()

def update_task_list():
    task_listbox.delete(0, tk.END)
    for task in tasks:
        task_listbox.insert(tk.END, f"{task['Task Name']} - Priority: {task['Priority']} - Due Date: {task['Due Date']}")

# Create the main window
root = tk.Tk()
root.title("Task Manager")

# Add a welcome label
label = Label(root, text="Welcome to Task Manager!")
label.pack(pady=10)

# Entry fields for task details
task_name_label = Label(root, text="Task Name:")
task_name_label.pack()
task_name_entry = Entry(root)
task_name_entry.pack()

priority_label = Label(root, text="Priority:")
priority_label.pack()
priority_entry = Entry(root)
priority_entry.pack()

due_date_label = Label(root, text="Due Date:")
due_date_label.pack()
due_date_entry = Entry(root)
due_date_entry.pack()

# Add an "Add Task" button
add_task_button = Button(root, text="Add Task", command=add_task)
add_task_button.pack(pady=10)

# Task listbox
task_listbox = Listbox(root)
task_listbox.pack(pady=10)

# Add an exit button
exit_button = Button(root, text="Exit", command=exit_app)
exit_button.pack(pady=10)

# Run the Tkinter event loop
root.mainloop()
