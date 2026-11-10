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
- Phone notifications through `flutter_local_notifications`, driven by Firestore (no
  server needed):
  - App open or in the background: instant, from the live listener.
  - App closed (Android): a WorkManager background check about every 15 minutes.
  - Updates that arrived while the app was closed pop up when it next runs.
  - Tapping a notification opens the task (or the Team tab for access requests),
    even from a cold start.
  - The bell keeps the full history.
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

## Subscription and remote switches

**Subscription** lives in Firestore at `environments/prod/subscription/current`:

| Field | Example | Meaning |
|---|---|---|
| `plan` | `Standard` | Shown on the Profile tab |
| `status` | `active` | Set to `suspended` to block the app immediately |
| `validUntil` | 31 Mar 2027, 23:59 IST | After this moment the app shows the "Contact me" screen |
| `validFrom` | 10 Nov 2026 | Informational |

The app can read this document but never write it (see `firestore.rules`); edit it in
the Firebase console. Changes apply live.

**Remote Config** (`remoteconfig.template.json`) controls:
- `app_enabled`: the master on/off switch.
- The texts and contact details on the "unavailable" screen.
- One `feature_*` switch per feature: sign-in options, task actions, team management,
  notifications, performance insights and Profile items.

The app ships with the same defaults, so it works before the template is published.
Published changes reach open apps within seconds.

- Publish: Firebase Console → Remote Config → ⋮ → *Publish from a file*, or
  `firebase deploy --only remoteconfig`.
- After adding a flag in `lib/features/app_control/domain/feature_flags.dart`,
  regenerate the template: `dart run tool/generate_remote_config.dart`.

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
environments/prod/subscription/current
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
pages). Navigation uses `go_router`: redirects send people to the splash,
"Contact me", login or home screen. Dependency injection uses `get_it`, and errors are typed `Failure`s returned
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
    home/          role-based tabs and the signed-in scope
    app_control/   subscription gate and Remote Config switches
```

```bash
flutter analyze
flutter test
```
