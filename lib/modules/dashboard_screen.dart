import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../repository/duplicate_finder_repository_impl.dart';
import '../repository/scan_session_repository_impl.dart';
import '../values/app_routes.dart';
import '../values/enums.dart';
import '../views/app_shell_widget.dart';
import '../views/footer_section_widget.dart';
import '../views/sidebar_section_widget.dart';
import 'dashboard_screen_cubit.dart';
import 'dashboard_screen_state.dart';
import 'home/home_screen_cubit.dart';

class DashboardScreenContent extends StatefulWidget {
  const DashboardScreenContent({super.key, required this.child});

  final Widget child;

  @override
  State<DashboardScreenContent> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreenContent> {
  final _cubit = DashboardScreenCubit();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final activeItem = NavigationItem.fromRoute(location);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _cubit),
        BlocProvider(
          create: (context) => HomeScreenCubit(
            repository: ScanSessionRepositoryImpl(),
            scanRepository: DuplicateFinderRepositoryImpl(
              storePath:
                  '', // TODO(phase-6): thread actual ObjectBox storePath from app initialization
            ),
          ),
        ),
      ],
      child: BlocListener<DashboardScreenCubit, DashboardScreenState>(
        bloc: _cubit,
        listener: (context, state) {
          if (state is DashboardScreenFoldersAdded) {
            context.go(AppRoutes.scanner);
          }
        },
        child: AppShellWidget(
          sidebar: SidebarSectionWidget(
            activeItem: activeItem,
            items: NavigationItem.values,
            onAddFolder: () =>
                context.read<DashboardScreenCubit>().onPickFolder(),
            onNavItemTap: (item) => context.go(item.route),
          ),
          body: widget.child,
          footer: const FooterSectionWidget(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }
}
