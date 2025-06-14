# Weekly Shift Planner

A Flutter app for managing weekly shift schedules with a Tuesday-Monday week layout.

## Features

- **Weekly Grid Layout**: Displays shifts in a grid with days from Tuesday to Monday
- **Week-Level Assignments**: Each worker has one shift type and housing for the entire week
- **Shift Types**:
  - `P` = Day shift (light blue background)
  - `Y` = Night shift (dark gray background)
  - `L` = Vacation (orange background, no housing shown)
  - Empty = Off day (light gray background)
- **Worker Management**: Add, edit, and delete workers with:
  - Custom name input (type any name)
  - Professions dropdown (10 fixed roles: Varu 1-4, Pasta 1-2, Huoltomies, Tarvikeauto, ICT, Pora)
  - Shift type selection for entire week
  - Housing assignments (E-A, E-B, N-A, N-B, etc.) when applicable
- **Mobile-Friendly**: Responsive design with horizontal scrolling for the weekly grid
- **In-Memory Storage**: No backend required, all data stored in app memory

## Example Workers

The app comes with 3 example workers showing different shift patterns:

1. **Mika Kumpulainen** (Varu 1): Day shift for entire week in E-A housing
2. **Eetu Savunen** (Pasta 1): Night shift for entire week in N-A housing
3. **Tomi Peltoniemi** (Huoltomies): Vacation for entire week (no housing)

## How to Run

1. Make sure you have Flutter installed
2. Navigate to the project directory
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the app

## Usage

- **View Schedule**: The main screen shows the weekly grid with merged cells
- **Add Worker**: Tap the + button to add a new worker
- **Edit Worker**: Tap the menu icon (⋮) next to a worker's name and select "Edit"
- **Delete Worker**: Tap the menu icon (⋮) next to a worker's name and select "Delete"
- **Legend**: The bottom shows color coding for different shift types

## Architecture

- `models/shift_data.dart`: Data models and constants
- `shift_planner_screen.dart`: Main screen with worker management
- `widgets/shift_grid.dart`: Weekly grid widget with cell merging logic
- `widgets/worker_editor.dart`: Dialog for adding/editing workers 