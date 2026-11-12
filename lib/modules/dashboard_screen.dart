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
import 'home/home_screen_cubit.dart';
import 'home/home_screen_state.dart';
import 'results/results_screen_cubit.dart';
import 'results/results_screen_state.dart';
import 'results/widgets/results_overlays_widget.dart';
import 'app_settings/app_settings_cubit.dart';
import '../repository/file_removal/file_removal_repository.dart';

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
        child: BlocProvider(
          create: (context) {
            final home = context.read<HomeScreenCubit>();
            return ResultsScreenCubit(
              scanner: home.scanner,
              settings: context.read<AppSettingsCubit>(),
              remover: const FileRemovalRepository(),
              watchedFolders: () => [
                for (final f in home.state.allFolders) f.path,
              ],
            );
          },
          child: Stack(
            children: [
              BlocBuilder<HomeScreenCubit, HomeScreenState>(
                builder: (context, homeState) =>
                    BlocBuilder<ResultsScreenCubit, ResultsScreenState>(
                      buildWhen: (a, b) =>
                          a.activeGroups.length != b.activeGroups.length ||
                          a.reclaimableBytes != b.reclaimableBytes ||
                          a.freedBytes != b.freedBytes,
                      builder: (context, results) => AppShellWidget(
                        sidebar: SidebarSectionWidget(
                          activeItem: activeItem,
                          items: NavigationItem.sidebarItems,
                          onNavItemTap: (item) => context.go(item.route),
                          folderNames: [
                            for (final f in homeState.allFolders) f.displayName,
                          ],
                          duplicateGroupCount: results.activeGroups.length,
                          reclaimableBytes: results.reclaimableBytes,
                          freedBytes: results.freedBytes,
                        ),
                        body: widget.child,
                      ),
                    ),
              ),
              const Positioned.fill(child: ResultsOverlaysWidget()),
            ],
          ),
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
