/// Every path in the app, so call sites never hand-build strings.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const blocked = '/blocked';
  static const login = '/login';

  // Home tabs.
  static const home = '/';
  static const tasks = '/tasks';
  static const team = '/team';
  static const performance = '/performance';
  static const profile = '/profile';

  static const adminTabs = [home, tasks, team, profile];
  static const employeeTabs = [home, tasks, performance, profile];

  // Pushed screens.
  static const notifications = '/notifications';
  static const addMember = '/team/add';
  static const newTaskPath = '/task/new';
  static const taskPath = '/task/:taskId';
  static const editTaskPath = '/task/:taskId/edit';
  static const employeePath = '/employee/:userId';

  static String task(String id) => '/task/$id';
  static String editTask(String id) => '/task/$id/edit';
  static String employee(String id) => '/employee/$id';
  static String newTask({String? assigneeId}) => assigneeId == null
      ? newTaskPath
      : Uri(
          path: newTaskPath,
          queryParameters: {'assignee': assigneeId},
        ).toString();
}
