# Simple Todo List System

This project is demonstrates practical integration between high-level (C) and low-level (Assembly) programming by implementing a todo list manager where the core functionality runs in assembly language.

## Features

- Add tasks with priority levels (1-9)
- Automatic timestamp tracking for each task
- List all current tasks with priority and creation time
- Edit task text by index
- Change task priority by index
- Remove tasks by index
- Persistent storage to `todos.txt`
- Maximum capacity: 10 tasks
- Each task can be up to 79 characters long

## Build Instructions

Requires NASM and GCC (Windows x64):
```powershell
nasm -f win64 math.asm -o math.obj
gcc main.c math.obj -o todo.exe
```

## Running the Program

1. After building, open PowerShell in the project directory
2. Run the program using:
```powershell
.\todo.exe
```

## Usage

Once running, you'll see an interactive menu:

1. Select `1` to add a new task
   - Enter the task text and its priority (1-9)
   - Timestamp is automatically recorded
2. Select `2` to list all tasks
   - Shows all tasks with index, priority, text, and creation time
3. Select `3` to remove a task by its index
   - Enter the index number shown in the list
4. Select `4` to quit the program
   - Tasks are automatically saved to `todos.txt`
5. Select `5` to edit a task's text
   - Enter the task index and new text
6. Select `6` to change a task's priority
   - Enter the task index and new priority (1-9)

### Test Mode

For quick testing, run with the `-test` argument:
```powershell
.\todo.exe -test
```
This will automatically add a sample task and display it.

## Technical Details

- Frontend: C (user interface and program flow)
- Backend: NASM x64 Assembly (Windows)
- Data storage: Persistent file-based storage (`todos.txt`)
- Windows x64 calling convention
- Record format: Each task stores priority (1 byte), timestamp (8 bytes), and text (80 bytes)
