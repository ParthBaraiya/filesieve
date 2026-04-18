import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repository/duplicate_finder_repository.dart';
import '../../utils/cancel_token.dart';
import 'scanner_screen_state.dart';

/// Cubit that manages the scanner feature's state.
///
/// Responsibilities:
/// - Tracks selected directory paths in [ScannerInitial.selectedPaths].
/// - Delegates all scan work to [DuplicateFinderRepository] (which owns the
///   [Isolate.spawn] and [SendPort]/[ReceivePort] wiring internally).
/// - Emits [ScannerScanning] → [ScannerDone] on success, or [ScannerError]
///   on failure / cancellation.
///
/// Phase 4 (T025) will wire [onProgress] to emit intermediate [ScannerScanning]
/// state updates.  Phase 5 (T030) will add a dedicated cancel action.
class ScannerScreenCubit extends Cubit<ScannerScreenState> {
  ScannerScreenCubit({required DuplicateFinderRepository repository})
      : _repository = repository,
        super(const ScannerInitial());

  final DuplicateFinderRepository _repository;

  /// Current cancel token; replaced at the start of each scan.
  CancelToken _cancelToken = CancelToken();

  // ---------------------------------------------------------------------------
  // Folder selection (only valid in [ScannerInitial] state)
  // ---------------------------------------------------------------------------

  /// Adds [path] to the selected folder list.
  ///
  /// No-op if [path] is already selected or the state is not [ScannerInitial].
  void addFolder(String path) {
    if (state is! ScannerInitial) return;
    final current = (state as ScannerInitial).selectedPaths;
    if (current.contains(path)) return;
    emit(ScannerInitial(selectedPaths: [...current, path]));
  }

  /// Removes [path] from the selected folder list.
  ///
  /// No-op if the state is not [ScannerInitial].
  void removeFolder(String path) {
    if (state is! ScannerInitial) return;
    final current = (state as ScannerInitial).selectedPaths;
    emit(ScannerInitial(
      selectedPaths: current.where((p) => p != path).toList(),
    ));
  }

  // ---------------------------------------------------------------------------
  // Scan lifecycle
  // ---------------------------------------------------------------------------

  /// Starts a duplicate scan over [files].
  ///
  /// Creates a fresh [CancelToken] for this scan, emits [ScannerScanning],
  /// and delegates to [DuplicateFinderRepository.find].
  ///
  /// On success: emits [ScannerDone] with the full list of duplicate groups.
  /// On cancellation: emits [ScannerError] with a cancellation message.
  /// On other error: emits [ScannerError] with the exception message.
  Future<void> startScan(List<File> files) async {
    // A Completer cannot be reset; always create a new CancelToken per scan.
    _cancelToken = CancelToken();

    emit(const ScannerScanning(groups: []));

    try {
      final groups = await _repository.find(
        files: files,
        onProgress: (p) {
          // Bridge worker progress to UI state.
          // allGroups stays [] until done — the pipeline emits groups only
          // at completion (Phase 6 wires streaming if needed).
          emit(ScannerScanning(progress: p, groups: state.allGroups));
        },
        cancelToken: _cancelToken,
        // byteByByteCompare added in Phase 7 (T037)
      );
      emit(ScannerDone(groups: groups));
    } on ScanCancelledException {
      // Phase 5 (T030) will emit a dedicated ScannerCancelled state.
      emit(const ScannerError(
        message: 'Scan was cancelled.',
        groups: [],
      ));
    } catch (e) {
      emit(ScannerError(
        message: e.toString(),
        groups: const [],
      ));
    }
  }

  /// Resets to the initial state, clearing any results or error.
  void reset() => emit(const ScannerInitial());
}
