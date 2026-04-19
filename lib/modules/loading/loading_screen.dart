import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../repository/scan_session/scan_session_repository_base.dart';
import '../../values/app_routes.dart';

/// LoadingScreen — performs 3-branch routing on app launch per FR-001.
///
/// Receives a [ScanSessionRepositoryBase] as a constructor parameter.
/// Uses [WidgetsBinding.addPostFrameCallback] with a [_navigated] guard so
/// navigation fires once after the first frame and does NOT re-fire on hot
/// reload.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key, required this.repository});

  final ScanSessionRepositoryBase repository;

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_navigated) return;
      _navigated = true;
      await _route();
    });
  }

  Future<void> _route() async {
    if (!mounted) return;
    // Priority 1: completed results → results
    if (await widget.repository.hasCompletedResults()) {
      if (mounted) context.goNamed(AppRouteNames.results);
      return;
    }
    // Priority 2: active session → scanner
    if (await widget.repository.hasActiveSession()) {
      if (mounted) context.goNamed(AppRouteNames.scanner);
      return;
    }
    // Default: onboarding
    if (mounted) context.goNamed(AppRouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
