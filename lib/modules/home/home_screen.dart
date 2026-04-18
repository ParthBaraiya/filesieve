// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// import '../../repository/duplicate_finder_repository_impl.dart';
// import '../../repository/scan_session_repository_impl.dart';
// import 'home_screen_cubit.dart';
// import 'widgets/home_content_section_widget.dart';

// /// HomeScreen — the onboarding / empty-state screen shown when no scan data
// /// exists (routed to from [LoadingScreen] when neither an active session nor
// /// completed results are present).
// ///
// /// Mounts a [BlocProvider] that owns a new [HomeScreenCubit] instance.
// ///
// /// **Note on repository instance**: A second [ScanSessionRepositoryImpl] is
// /// intentionally instantiated here (separate from the one in `main.dart`
// /// used by [LoadingScreen]). When ObjectBox is wired up in a future feature,
// /// both should receive the same singleton via constructor injection.
// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (_) => HomeScreenCubit(
//         repository: ScanSessionRepositoryImpl(),
//         scanRepository: DuplicateFinderRepositoryImpl(
//           storePath:
//               '', // TODO(phase-6): thread actual ObjectBox storePath from app initialization
//         ),
//       ),
//       child: const HomeContentSectionWidget(),
//     );
//   }
// }
