# Coopiq Internal

Team task management for Coopiq. Admins (owners) assign and review work.
Employees see their daily list, update progress and mark tasks complete. Everyone
gets live notifications.

## Features

**Admin / owner**
- Dashboard: open, overdue and completed tasks, deadline achievement, average rating,
  status breakdown, weekly completion chart, employee leaderboard, "needs attention"
  list and recent updates.
- Tasks: create, edit, reassign and delete tasks. Search and filter by status,
  priority and assignee; sort by due date, priority or recency.
- Ratings: rate each completed task on **completion quality** and **deadline
  achievement** (1–5 stars each), with optional feedback. The deadline score is
  pre-filled from how late the task was finished.
- Team: approve sign-up requests, add members directly, promote or demote admins,
  deactivate accounts, and open any employee's performance page.

**Employee**
- My day: a date strip with tasks due on the chosen day, overdue carry-over, and
  one-tap complete (with undo).
- My tasks: every assigned task, including completed ones, with filters.
- Performance: score, deadline achievement, average ratings, weekly trend and the
  feedback received.
- Comments and status changes on assigned tasks.

**Everyone**
- Email/password and Google sign-in.
- Real-time notifications: a system notification for every new update while the
  app is open or running in the background, plus a bell with an unread badge. These come from
  Firestore listeners; no server code is needed.
- Dark theme by default (light and system available) in Coopiq brand colours.

## How access works

1. The **first account** created becomes the admin (already done: Wasil and Ishaque are admins).
2. Later self sign-ups (email or Google) are created **inactive** and need an
   admin to approve them on the Team tab.
3. Admins can also add members directly with a temporary password, optionally
   emailing them a password-setup link.

`firestore.rules` enforces this model on the server: employees can only read their
own tasks and can only change a task's status.

## Performance score

0–100, combining deadline achievement (40%), admin ratings (40%) and completion
rate (20%). Missing parts are left out and the weights rescaled. Deadline achievement
= tasks finished on time ÷ (completed + overdue).

## Data model (Firestore)

```
environments/prod/meta/workspace
environments/prod/users/{uid}
environments/prod/tasks/{taskId}
environments/prod/tasks/{taskId}/activity/{id}
environments/prod/notifications/{id}
```

Every task change is written in one batch together with its activity entries and
notifications. Firestore's offline cache serves reads and queues writes while the
device is offline.

## Setup

1. **Deploy rules and indexes** (required before first use):
   ```bash
   firebase deploy --only firestore
   ```
2. **Enable sign-in providers** in Firebase Console → Authentication: Email/Password
   and Google.
3. **Android Google sign-in:** add your SHA-1 (and SHA-256) fingerprints in Firebase
   Console → Project settings → Android app, then download the new
   `google-services.json` into `android/app/`. Get the debug fingerprint with:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android
   ```
4. Run:
   ```bash
   flutter run
   ```

## Architecture

Feature-first clean architecture: `domain` (entities, use cases), `data`
(Firestore models and data sources, repositories) and `presentation` (BLoC/Cubit,
pages). Dependency injection uses `get_it`, and errors are typed `Failure`s returned
through `fpdart`'s `Either`.

```
lib/
  core/        config, DI, theme, Firestore paths, shared widgets, notifications
  features/
    auth/          sign-in, Google, approval flow, live profile
    tasks/         task list, My day, details, form, ratings, activity
    team/          members, approvals, roles
    analytics/     dashboard, employee performance
    notifications/ feed, unread state, system alerts
    profile/       account and appearance
    home/          role-based navigation shell
```

```bash
flutter analyze
flutter test
```
