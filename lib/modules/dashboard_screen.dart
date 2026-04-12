import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../values/app_routes.dart';
import '../values/app_strings.dart';
import '../values/enums.dart';
import '../views/app_shell_widget.dart';
import '../views/footer_section_widget.dart';
import '../views/header_section_widget.dart';
import '../views/sidebar_section_widget.dart';
import 'dashboard_screen_cubit.dart';
import 'dashboard_screen_state.dart';

class DashboardScreenContent extends StatefulWidget {
  const DashboardScreenContent({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<DashboardScreenContent> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreenContent> {
  final _cubit = DashboardScreenCubit();

  @override
  Widget build(BuildContext context) {
    final location =
        GoRouterState.of(context).uri.path;
    final activeItem = NavigationItem.fromRoute(location);

    return BlocProvider.value(
      value: _cubit,
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
          header:
              const HeaderSectionWidget(label: AppStrings.headerContextLabel),
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
