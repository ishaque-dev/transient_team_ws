import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transient_team_ws/core/di/di.dart';
import 'package:transient_team_ws/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';
import 'package:transient_team_ws/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:transient_team_ws/features/tasks/presentation/pages/task_details_page.dart';
import 'package:transient_team_ws/features/tasks/presentation/pages/task_form_page.dart';
import 'package:transient_team_ws/features/tasks/presentation/widgets/task_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<TaskBloc>().add(const LoadMoreTasksRequested());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          serviceLocator<TaskBloc>()..add(const FetchTasksRequested()),
      child: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Workspace'),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: () =>
                    context.read<AuthBloc>().add(AuthLogoutRequested()),
                icon: const Icon(Icons.logout),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(110),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (query) => context
                          .read<TaskBloc>()
                          .add(TaskSearchChanged(query)),
                      decoration: InputDecoration(
                        hintText: 'Search tasks...',
                        prefixIcon: const Icon(Icons.search, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withAlpha(40),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        hintStyle: const TextStyle(color: Colors.white70),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All Status',
                          isSelected: context.select((TaskBloc bloc) =>
                              bloc.state.filterStatus == null),
                          onSelected: (_) {
                            context.read<TaskBloc>().add(
                                const TaskStatusFilterChanged(null));
                          },
                        ),
                        ...TaskStatus.values.map((status) => _FilterChip(
                              label: status.name.toUpperCase(),
                              isSelected: context.select((TaskBloc bloc) =>
                                  bloc.state.filterStatus == status),
                              onSelected: (selected) {
                                context.read<TaskBloc>().add(
                                    TaskStatusFilterChanged(
                                        selected ? status : null));
                              },
                            )),
                        const VerticalDivider(color: Colors.white24),
                        _FilterChip(
                          label: 'All Priorities',
                          isSelected: context.select((TaskBloc bloc) =>
                              bloc.state.filterPriority == null),
                          onSelected: (_) {
                            context.read<TaskBloc>().add(
                                const TaskPriorityFilterChanged(null));
                          },
                        ),
                        ...TaskPriority.values.map((priority) => _FilterChip(
                              label: priority.name.toUpperCase(),
                              isSelected: context.select((TaskBloc bloc) =>
                                  bloc.state.filterPriority == priority),
                              onSelected: (selected) {
                                context.read<TaskBloc>().add(
                                    TaskPriorityFilterChanged(
                                        selected ? priority : null));
                              },
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          body: BlocBuilder<TaskBloc, TaskState>(
            builder: (context, state) {
              if (state.status == TaskBlocStatus.loading && state.tasks.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == TaskBlocStatus.failure && state.tasks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(state.errorMessage ?? 'Failed to load tasks'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context
                            .read<TaskBloc>()
                            .add(const FetchTasksRequested()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              if (state.tasks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.task_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No tasks found. Get started!'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<TaskBloc>(),
                                child: const TaskFormPage(),
                              ),
                            ),
                          );
                        },
                        child: const Text('Create Your First Task'),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<TaskBloc>().add(const FetchTasksRequested());
                },
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: state.hasReachedMax
                      ? state.tasks.length
                      : state.tasks.length + 1,
                  itemBuilder: (context, index) {
                    if (index >= state.tasks.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    final task = state.tasks[index];
                    return TaskCard(
                      task: task,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<TaskBloc>(),
                              child: TaskDetailsPage(task: task),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<TaskBloc>(),
                    child: const TaskFormPage(),
                  ),
                ),
              );
            },
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        );
      }),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool) onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: onSelected,
        showCheckmark: false,
        selectedColor: Colors.white,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? Colors.green : Colors.grey.shade300,
          width: 1,
        ),
        labelStyle: TextStyle(
          color: isSelected ? Colors.green : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
