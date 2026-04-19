// import 'dart:io';

// import 'package:flutter_bloc/flutter_bloc.dart';

// import '../../repository/duplicate_finder_repository.dart';
// import '../../utils/cancel_token.dart';
// import 'scanner_screen_state.dart';

// /// Cubit that manages the scanner feature's state.
// ///
// /// Responsibilities:
// /// - Tracks selected directory paths in [ScannerInitial.selectedPaths].
// /// - Delegates all scan work to [DuplicateFinderRepository] (which owns the
// ///   [Isolate.spawn] and [SendPort]/[ReceivePort] wiring internally).
// /// - Emits [ScannerScanning] → [ScannerDone] on success, [ScannerCancelled]
// ///   on cancellation, or [ScannerError] on failure.
// class ScannerScreenCubit extends Cubit<ScannerScreenState> {
//   ScannerScreenCubit({required DuplicateFinderRepository repository})
//       : _repository = repository,
//         super(const ScannerInitial());

//   final DuplicateFinderRepository _repository;

//   /// Current cancel token; replaced at the start of each scan.
//   CancelToken _cancelToken = CancelToken();

//   // ---------------------------------------------------------------------------
//   // Folder selection (only valid in [ScannerInitial] state)
//   // ---------------------------------------------------------------------------

//   /// Adds [path] to the selected folder list.
//   ///
//   /// No-op if [path] is already selected or the state is not [ScannerInitial].
//   void addFolder(String path) {
//     if (state is! ScannerInitial) return;
//     final current = (state as ScannerInitial).selectedPaths;
//     if (current.contains(path)) return;
//     emit(ScannerInitial(selectedPaths: [...current, path]));
//   }

//   /// Removes [path] from the selected folder list.
//   ///
//   /// No-op if the state is not [ScannerInitial].
//   void removeFolder(String path) {
//     if (state is! ScannerInitial) return;
//     final current = (state as ScannerInitial).selectedPaths;
//     emit(ScannerInitial(
//       selectedPaths: current.where((p) => p != path).toList(),
//     ));
//   }

//   // ---------------------------------------------------------------------------
//   // Scan lifecycle
//   // ---------------------------------------------------------------------------

//   /// Starts a duplicate scan over [files].
//   ///
//   /// Creates a fresh [CancelToken] for this scan, emits [ScannerScanning],
//   /// and delegates to [DuplicateFinderRepository.find].
//   ///
//   /// On success: emits [ScannerDone] with the full list of duplicate groups.
//   /// On cancellation: emits [ScannerCancelled].
//   /// On other error: emits [ScannerError] with the exception message.
//   Future<void> startScan(List<File> files) async {
//     // A Completer cannot be reset; always create a new CancelToken per scan.
//     _cancelToken = CancelToken();

//     // Capture the flag before emitting — state changes after emit.
//     final byteCompare = state.byteByByteCompare;

//     emit(ScannerScanning(groups: [], byteByByteCompare: byteCompare));

//     try {
//       final groups = await _repository.find(
//         files: files,
//         onProgress: (p) {
//           // Bridge worker progress to UI state.
//           emit(ScannerScanning(
//             progress: p,
//             groups: state.allGroups,
//             byteByByteCompare: byteCompare,
//           ));
//         },
//         cancelToken: _cancelToken,
//         byteByByteCompare: byteCompare,
//       );
//       emit(ScannerDone(groups: groups, byteByByteCompare: byteCompare));
//     } on ScanCancelledException {
//       emit(ScannerCancelled(
//         groups: state.allGroups,
//         byteByByteCompare: byteCompare,
//       ));
//     } catch (e) {
//       emit(ScannerError(
//         message: e.toString(),
//         groups: const [],
//         byteByByteCompare: byteCompare,
//       ));
//     }
//   }

//   /// Resets to the initial state, clearing any results or error.
//   void reset() => emit(const ScannerInitial());

//   /// Toggles the byte-by-byte compare flag.
//   ///
//   /// Persists the flag across all state variants via [copyWith].
//   /// No-op when [value] equals the current flag.
//   void setByteCompare(bool value) {
//     if (state.byteByByteCompare == value) return;
//     final s = state;
//     emit(switch (s) {
//       ScannerInitial() => s.copyWith(byteByByteCompare: value),
//       ScannerScanning() => s.copyWith(byteByByteCompare: value),
//       ScannerDone() => s.copyWith(byteByByteCompare: value),
//       ScannerError() => s.copyWith(byteByByteCompare: value),
//       ScannerCancelled() => s.copyWith(byteByByteCompare: value),
//     });
//   }

//   /// Cancels the in-progress scan.
//   ///
//   /// Calls [CancelToken.cancel] on the active token. The cancel signal is
//   /// bridged to the worker isolate via [DuplicateFinderRepositoryImpl]'s
//   /// internal [SendPort] wiring; the next [CancelToken.throwIfCancelled]
//   /// call inside the pipeline raises [ScanCancelledException], which
//   /// [startScan] catches and converts into a [ScannerCancelled] emit.
//   ///
//   /// No-op when no scan is in progress.
//   void cancelScan() => _cancelToken.cancel();
// }
