abstract final class AppStrings {
  static const String appName = 'Coopiq Internal';
  static const String appTagline = 'Plan, assign and track team work';
  static const String somethingWentWrong =
      'Something went wrong, please try again later.';
  static const sharedPrefUserKey = 'loggedInUser';
  static const sharedPrefThemeKey = 'themeMode';

  // Auth
  static const String signInTitle = 'Sign in to your workspace';
  static const String requestAccessTitle = 'Request access';
  static const String fullName = 'Full name';
  static const String email = 'Work email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm password';
  static const String signIn = 'Sign in';
  static const String requestAccess = 'Request access';
  static const String forgotPassword = 'Forgot password?';
  static const String noAccount = 'New to the team? ';
  static const String haveAccount = 'Already have an account? ';
  static const String approvalHint =
      'New accounts need an admin to approve them before you can sign in.';
  static const String resetPasswordTitle = 'Reset password';
  static const String resetPasswordBody =
      "We'll email you a link to choose a new password.";
  static const String sendLink = 'Send link';
  static const String accessRequested =
      'Request sent. You can sign in once an admin approves your account.';
  static const String resetEmailSent =
      'Password reset email sent. Check your inbox.';
  static const String accountDeactivated =
      'Your account was deactivated. Contact a workspace admin.';
  static const String sessionEnded =
      'Your session ended. Please sign in again.';

  // Validation
  static const String enterName = 'Please enter a name';
  static const String enterEmail = 'Please enter an email';
  static const String enterValidEmail = 'Enter a valid email';
  static const String enterPassword = 'Please enter a password';
  static const String passwordTooShort =
      'Password must be at least 6 characters';
  static const String passwordsDoNotMatch = 'Passwords do not match';
  static const String enterTitle = 'Please enter a title';
  static const String enterComment = 'Write a comment first';

  // Navigation
  static const String overview = 'Overview';
  static const String tasks = 'Tasks';
  static const String myTasks = 'My tasks';
  static const String team = 'Team';
  static const String profile = 'Profile';

  // Overview
  static const String goodMorning = 'Good morning';
  static const String goodAfternoon = 'Good afternoon';
  static const String goodEvening = 'Good evening';
  static const String openTasks = 'Open';
  static const String inProgress = 'In progress';
  static const String overdue = 'Overdue';
  static const String completed = 'Completed';
  static const String statusBreakdown = 'Status breakdown';
  static const String needsAttention = 'Needs attention';
  static const String needsAttentionEmpty =
      'Nothing overdue or due in the next 3 days.';
  static const String teamWorkload = 'Team workload';
  static const String recentlyUpdated = 'Recently updated';
  static const String viewAll = 'View all';
  static const String noTasksYetAdmin =
      'No tasks yet. Create one and assign it to a teammate.';
  static const String noTasksYetMember =
      'No tasks assigned to you yet. New assignments show up here instantly.';

  // Task list
  static const String searchTasks = 'Search tasks';
  static const String sortBy = 'Sort by';
  static const String priority = 'Priority';
  static const String anyPriority = 'Any priority';
  static const String assignee = 'Assignee';
  static const String anyone = 'Anyone';
  static const String unassigned = 'Unassigned';
  static const String clearFilters = 'Clear filters';
  static const String noMatches = 'No tasks match these filters';
  static const String allCaughtUp = "You're all caught up";
  static const String newTask = 'New task';
  static const String failedToLoadTasks = "Couldn't load tasks";
  static const String retry = 'Retry';

  // Task details
  static const String task = 'Task';
  static const String taskNotFound = 'This task was deleted or reassigned.';
  static const String updateStatus = 'Status';
  static const String details = 'Details';
  static const String description = 'Description';
  static const String noDescription = 'No description provided.';
  static const String dueDate = 'Due date';
  static const String assignedTo = 'Assigned to';
  static const String createdBy = 'Created by';
  static const String createdOn = 'Created';
  static const String lastUpdated = 'Last updated';
  static const String completedOn = 'Completed';
  static const String activity = 'Activity';
  static const String noActivity = 'No activity yet.';
  static const String addComment = 'Add a comment or progress update';
  static const String editTask = 'Edit task';
  static const String deleteTask = 'Delete task';
  static const String deleteTaskConfirm =
      'This permanently removes the task and its activity. This cannot be undone.';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String save = 'Save';
  static const String statusUpdated = 'Status updated';
  static const String taskDeleted = 'Task deleted';

  // Task form
  static const String title = 'Title';
  static const String descriptionHint = 'What needs to be done?';
  static const String status = 'Status';
  static const String createTask = 'Create task';
  static const String saveChanges = 'Save changes';
  static const String taskCreated = 'Task created';
  static const String taskUpdated = 'Task updated';
  static const String discardChangesTitle = 'Discard changes?';
  static const String discardChangesBody = 'Your edits will be lost.';
  static const String keepEditing = 'Keep editing';
  static const String discard = 'Discard';

  // Team
  static const String addMember = 'Add member';
  static const String pendingApproval = 'Awaiting approval';
  static const String inactive = 'Inactive';
  static const String activeMembers = 'Active members';
  static const String inactiveMembers = 'Inactive & pending';
  static const String makeAdmin = 'Make admin';
  static const String makeMember = 'Make member';
  static const String activate = 'Approve / activate';
  static const String deactivate = 'Deactivate';
  static const String viewTasks = 'View tasks';
  static const String you = 'You';
  static const String noTeamMembers = 'No team members yet.';
  static const String temporaryPassword = 'Temporary password';
  static const String role = 'Role';
  static const String sendResetLink = 'Email a password setup link';
  static const String sendResetLinkHint =
      'They can pick their own password instead of using the temporary one.';
  static const String failedToLoadTeam = "Couldn't load the team";

  // Profile
  static const String editName = 'Edit name';
  static const String appearance = 'Appearance';
  static const String system = 'System';
  static const String light = 'Light';
  static const String dark = 'Dark';
  static const String changePassword = 'Change password';
  static const String changePasswordHint =
      'We will email you a secure link to set a new password.';
  static const String signOut = 'Sign out';
  static const String signOutConfirm = 'Sign out of Coopiq Internal?';
  static const String memberSince = 'Member since';
  static const String nameUpdated = 'Name updated';
  static const String account = 'Account';
}
