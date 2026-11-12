import 'package:filesieve/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:objectbox/objectbox.dart';

import '../repository/duplicate_finder/duplicate_finder_repository.dart';
import '../repository/scan_session/scan_session_repository.dart';
import '../values/app_routes.dart';
import '../values/enums.dart';
import '../views/app_shell_widget.dart';
import '../views/sidebar_section_widget.dart';
import 'dashboard_screen_cubit.dart';
import 'dashboard_screen_state.dart';
import 'home/file_scanner_cubit.dart';
import 'home/file_scanner_state.dart';
import 'home/home_screen_cubit.dart';
import 'home/home_screen_state.dart';

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
            repository: ScanSessionRepository(),
            scanRepository: DuplicateFinderRepository(
              storePath:
                  serviceLocator.get<Store>().directoryPath,
            ),
          ),
        ),
      ],
      child: BlocListener<DashboardScreenCubit, DashboardScreenState>(
        bloc: _cubit,
        listener: (context, state) {
          if (state is DashboardScreenFoldersAdded) {
            context.go(AppRoutes.results);
          }
        },
        child: Builder(
          builder: (context) {
            final home = context.read<HomeScreenCubit>();
            return BlocBuilder<HomeScreenCubit, HomeScreenState>(
              builder: (context, homeState) => BlocBuilder<
                FileScannerCubit,
                FileScannerState
              >(
                bloc: home.scanner,
                builder: (context, scanState) {
                  var groupCount = 0;
                  var reclaimable = 0;
                  for (final cubit in scanState.getGroups) {
                    final group = cubit.state.group;
                    final n = group.files.length;
                    if (n < 2) continue;
                    groupCount++;
                    reclaimable += group.totalGroupSize * (n - 1) ~/ n;
                  }
                  return AppShellWidget(
                    sidebar: SidebarSectionWidget(
                      activeItem: activeItem,
                      items: NavigationItem.sidebarItems,
                      onNavItemTap: (item) => context.go(item.route),
                      folderNames: [
                        for (final f in homeState.allFolders) f.displayName,
                      ],
                      duplicateGroupCount: groupCount,
                      reclaimableBytes: reclaimable,
                      freedBytes: 0,
                    ),
                    body: widget.child,
                  );
                },
              ),
            );
          },
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
