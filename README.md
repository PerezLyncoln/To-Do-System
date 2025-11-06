# Simple Todo List System

This project is demonstrates practical integration between high-level (C) and low-level (Assembly) programming by implementing a todo list manager where the core functionality runs in assembly language.

## Features

- Add tasks to your todo list
- List all current tasks
- Remove tasks by index
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
   - Type your task and press Enter
2. Select `2` to list all tasks
   - Shows all tasks with their index numbers
3. Select `3` to remove a task by its index
   - Enter the index number shown in the list
4. Select `4` to quit the program

### Test Mode

For quick testing, run with the `-test` argument:
```powershell
.\todo.exe -test
```
This will automatically add a sample task and display it.

## Technical Details

- Frontend: C (user interface and program flow)
- Backend: NASM x64 Assembly (Windows)
- Data storage: In-memory (non-persistent)
- Windows x64 calling convention
