import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../repository/scan_session_repository_impl.dart';
import '../../values/app_routes.dart';
import '../../values/app_strings.dart';
import '../../values/enums.dart';
import '../../views/app_shell_widget.dart';
import '../../views/footer_section_widget.dart';
import '../../views/header_section_widget.dart';
import '../../views/sidebar_section_widget.dart';
import 'home_screen_cubit.dart';
import 'home_screen_state.dart';
import 'widgets/home_content_section_widget.dart';

/// HomeScreen — the onboarding / empty-state screen shown when no scan data
/// exists (routed to from [LoadingScreen] when neither an active session nor
/// completed results are present).
///
/// Mounts a [BlocProvider] that owns a new [HomeScreenCubit] instance.
/// A [BlocListener] navigates to [AppRoutes.scanner] when folders are added.
///
/// **Note on repository instance**: A second [ScanSessionRepositoryImpl] is
/// intentionally instantiated here (separate from the one in `main.dart`
/// used by [LoadingScreen]). When ObjectBox is wired up in a future feature,
/// both should receive the same singleton via constructor injection.
///
/// Placeholder [SizedBox.shrink] widgets fill the header, body content, and
/// footer slots — replaced in Phase 4 (T025) and Phase 7 (T032).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          HomeScreenCubit(repository: ScanSessionRepositoryImpl()),
      child: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatelessWidget {
  const _HomeScreenContent();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HomeScreenCubit>();

    return BlocListener<HomeScreenCubit, HomeScreenState>(
      listener: (context, state) {
        if (state is HomeScreenFoldersAdded) {
          context.go(AppRoutes.scanner);
        }
      },
      child: AppShellWidget(
        sidebar: SidebarSectionWidget(
          activeItem: NavigationItem.scan,
          items: NavigationItem.values,
          onAddFolder: () => cubit.onPickFolder(),
          onNavItemTap: (item) => context.go(_routeForItem(item)),
        ),
        header: const HeaderSectionWidget(label: AppStrings.headerContextLabel),
        body: const HomeContentSectionWidget(),
        footer: const FooterSectionWidget(),
      ),
    );
  }

  String _routeForItem(NavigationItem item) => switch (item) {
        NavigationItem.scan => AppRoutes.home,
        NavigationItem.results => AppRoutes.results,
        NavigationItem.settings => AppRoutes.settings,
        NavigationItem.history => AppRoutes.history,
      };
}
