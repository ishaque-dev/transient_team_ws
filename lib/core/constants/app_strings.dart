abstract final class AppStrings {
  static const String appName = 'Transient Team';
  static const String noInternetConnection = 'No internet connection';
  static const String somethingWentWrong =
      'Something went wrong, please try again later.';
  static const String responseParsingError =
      'Response received successfully..Unable to parse JSON';
  static const sharedPrefUserKey = 'loggedInUser';
  static const dbName = 'task.db';

  // Auth
  static const String welcomeBack = 'Welcome Back';
  static const String createAccount = 'Create Account';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String login = 'Login';
  static const String signUp = 'Sign Up';
  static const String dontHaveAccount = "Don't have an account? Sign Up";
  static const String alreadyHaveAccount = 'Already have an account? Login';

  // Auth Validations
  static const String enterEmail = 'Please enter email';
  static const String enterValidEmail = 'Enter a valid email';
  static const String enterPassword = 'Please enter password';
  static const String passwordTooShort = 'Password must be at least 6 characters';
  static const String passwordsDoNotMatch = 'Passwords do not match';

  // Dashboard
  static const String myWorkspace = 'My Workspace';
  static const String searchTasks = 'Search tasks...';
  static const String allStatus = 'All Status';
  static const String allPriorities = 'All Priorities';
  static const String retry = 'Retry';
  static const String noTasksFound = 'No tasks found. Get started!';
  static const String createFirstTask = 'Create Your First Task';
  static const String failedToLoadTasks = 'Failed to load tasks';

  // Task Details
  static const String taskDetails = 'Task Details';
  static const String description = 'Description';
  static const String dueDate = 'Due Date';
  static const String assignedTo = 'Assigned To';
  static const String unassigned = 'Unassigned';
  static const String deleteDialogTitle = 'Delete Task';
  static const String deleteDialogContent = 'Are you sure you want to delete this task?';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String reopenTask = 'Reopen Task';
  static const String markAsCompleted = 'Mark as Completed';

  // Task Form
  static const String editTask = 'Edit Task';
  static const String newTask = 'New Task';
  static const String title = 'Title';
  static const String priority = 'Priority';
  static const String assignTo = 'Assign To';
  static const String selectTeamMember = 'Select a team member';
  static const String status = 'Status';
  static const String saveTask = 'Save Task';

  // Form Validations
  static const String enterTitle = 'Enter title';
  static const String enterDescription = 'Enter description';
}
