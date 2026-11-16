import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/duplicate_group_view_model.dart';
import '../../models/scan_progress_model.dart';
import '../../repository/file_removal/file_removal_repository_base.dart';
import '../../values/enums.dart';
import '../app_settings/app_settings_cubit.dart';
import '../home/file_scanner_cubit.dart';
import '../home/file_scanner_state.dart';
import 'results_screen_state.dart';

/// ResultsScreenCubit — everything about reviewing duplicates: the list and
/// its filter, the compare view, removing / restoring files, the confirm
/// dialog and the toast. Removal behaviour comes from [AppSettingsCubit].
class ResultsScreenCubit extends Cubit<ResultsScreenState> {
  ResultsScreenCubit({
    required FileScannerCubit scanner,
    required AppSettingsCubit settings,
    required FileRemovalRepositoryBase remover,
  }) : _scanner = scanner,
       _settings = settings,
       _remover = remover,
       super(const ResultsScreenState()) {
    _subscription = scanner.stream.listen(_onScannerState);
    _syncGroups();
  }

  final FileScannerCubit _scanner;
  final AppSettingsCubit _settings;
  final FileRemovalRepositoryBase _remover;

  late final StreamSubscription<FileScannerState> _subscription;
  Timer? _toastTimer;
  int _seenGroupCount = 0;

  /// Whether removed files can be put back (shown as "Undo" / "Restore").
  bool get canRestore => _remover.canRestore;

  //#region Scanner sync
  void _onScannerState(FileScannerState scan) {
    if (scan is FileScannerStateInitial) {
      _seenGroupCount = 0;
      _toastTimer?.cancel();
      emit(const ResultsScreenState());
      return;
    }
    final isFreshScan =
        scan is FileScannerStateScanningStarted &&
        scan.groups.isEmpty &&
        scan.progress.stage == ScanProgressStage.scanningFile;
    if (isFreshScan) {
      _seenGroupCount = 0;
      _toastTimer?.cancel();
      emit(const ResultsScreenState());
      return;
    }
    if (scan.getGroups.length != _seenGroupCount || !state.hasScanned) {
      _syncGroups();
    }
  }

  void _syncGroups({Map<String, RemovalMode>? removed}) {
    final map = removed ?? state.removed;
    final views = <DuplicateGroupView>[];
    for (final cubit in _scanner.state.getGroups) {
      final group = cubit.state.group;
      if (group.files.length < 2) continue;
      views.add(DuplicateGroupView.from(group, map));
    }
    _seenGroupCount = _scanner.state.getGroups.length;
    views.sort((a, b) => b.reclaimableBytes.compareTo(a.reclaimableBytes));
    emit(
      state.copyWith(
        groups: views,
        removed: map,
        hasScanned: _scanner.state is! FileScannerStateInitial,
      ),
    );
  }
  //#endregion

  //#region List
  void setFilter(FileCategory? category) =>
      emit(state.copyWith(filter: category));

  void openGroup(String key) => emit(state.copyWith(openGroupKey: key));

  /// Back to the list from the compare view.
  void closeGroup() => emit(state.copyWith(openGroupKey: null));

  /// Steps through unresolved groups in the compare view; wraps around.
  void stepGroup(int direction) {
    final list = state.navigableGroups;
    if (list.isEmpty) return closeGroup();
    final i = list.indexWhere((g) => g.key == state.openGroupKey);
    final next = list[(i + direction + list.length) % list.length];
    emit(state.copyWith(openGroupKey: next.key));
  }

  void keepCopy(String groupKey, String path) => emit(
    state.copyWith(keepSelection: {...state.keepSelection, groupKey: path}),
  );
  //#endregion

  //#region Removal
  /// Removes [paths], asking first when the settings or removal mode demand it.
  Future<void> requestRemove(List<String> paths, String label) async {
    if (paths.isEmpty || state.busy) return;
    final settings = _settings.state;
    if (settings.removalMode == RemovalMode.permanent ||
        settings.confirmBeforeEveryRemoval) {
      emit(
        state.copyWith(
          dialog: ResultsDialog(
            kind: ResultsDialogKind.removeSome,
            paths: paths,
            label: label,
          ),
        ),
      );
    } else {
      await _applyRemove(paths, label);
    }
  }

  void openRemoveAll() {
    if (state.busy || state.activeGroups.isEmpty) return;
    emit(
      state.copyWith(
        dialog: const ResultsDialog(kind: ResultsDialogKind.removeAll),
        folderChoices: const {},
        removeStep: 0,
      ),
    );
  }

  /// Records the folder to keep for the combo [comboKey].
  void chooseFolder(String comboKey, String folder) => emit(
    state.copyWith(folderChoices: {...state.folderChoices, comboKey: folder}),
  );

  /// Moves to the next "Remove all" step; needs the current choice first.
  void nextRemoveStep() {
    final combos = state.choiceCombos;
    final step = state.removeStep;
    if (step >= combos.length) return;
    if (!state.folderChoices.containsKey(combos[step].key)) return;
    emit(state.copyWith(removeStep: step + 1));
  }

  void previousRemoveStep() {
    if (state.removeStep == 0) return;
    emit(state.copyWith(removeStep: state.removeStep - 1));
  }

  void cancelDialog() =>
      emit(state.copyWith(dialog: null, folderChoices: const {}, removeStep: 0));

  Future<void> confirmDialog() async {
    final dialog = state.dialog;
    if (dialog == null || state.busy) return;
    if (dialog.kind == ResultsDialogKind.removeSome) {
      return _applyRemove(dialog.paths, dialog.label);
    }
    final paths = <String>[];
    for (final combo in state.folderCombos) {
      // A single-folder combo has nothing to choose; otherwise every combo
      // must have been answered.
      final keep = combo.needsChoice
          ? state.folderChoices[combo.key]
          : combo.folders.first;
      if (keep == null) return;
      paths.addAll(combo.pathsToRemove(keep));
    }
    await _applyRemove(paths, _plural(paths.length, 'copy', 'copies'));
  }

  Future<void> _applyRemove(List<String> paths, String label) async {
    if (state.busy) return;
    emit(
      state.copyWith(
        busy: true,
        dialog: null,
        removeDone: 0,
        removeTotal: paths.length,
      ),
    );

    final mode = _settings.state.removalMode;
    final bytesByPath = {
      for (final g in state.groups)
        for (final v in g.versions) v.path: g.bytesEach,
    };
    final removed = {...state.removed};
    final done = <String>[];
    var failed = 0;
    var freed = 0;
    for (final path in paths) {
      try {
        await _remover.remove(path, mode);
        removed[path] = mode;
        done.add(path);
        freed += bytesByPath[path] ?? 0;
      } on FileRemovalException {
        failed++;
      }
      emit(state.copyWith(removeDone: done.length + failed));
    }

    _syncGroups(removed: removed);
    emit(
      state.copyWith(
        busy: false,
        removeDone: 0,
        removeTotal: 0,
        freedBytes: state.freedBytes + freed,
        freedCount: state.freedCount + done.length,
      ),
    );

    final trash = mode == RemovalMode.trash;
    final text = failed > 0
        ? "Couldn't remove ${_plural(failed, 'file', 'files')}. "
              '${done.isEmpty ? '' : 'Removed ${done.length}.'}'.trim()
        : trash
        ? 'Moved $label to Trash'
        : 'Permanently deleted $label';
    _showToast(
      ResultsToast(
        text: text,
        undoPaths: trash && _remover.canRestore ? done : const [],
      ),
    );
  }

  /// Puts previously trashed [paths] back.
  Future<void> restore(List<String> paths) async {
    if (paths.isEmpty || state.busy) return;
    final bytesByPath = {
      for (final g in state.groups)
        for (final v in g.versions) v.path: g.bytesEach,
    };
    final removed = {...state.removed};
    var freed = 0;
    var restored = 0;
    for (final path in paths) {
      if (await _remover.restore(path)) {
        removed.remove(path);
        freed += bytesByPath[path] ?? 0;
        restored++;
      }
    }
    _syncGroups(removed: removed);
    emit(
      state.copyWith(
        freedBytes: (state.freedBytes - freed).clamp(0, 1 << 62),
        freedCount: (state.freedCount - restored).clamp(0, 1 << 30),
        toast: null,
      ),
    );
    if (restored < paths.length) {
      _showToast(const ResultsToast(text: "Couldn't restore every file."));
    }
  }

  Future<void> revealInFolder(String path, String folderName) async {
    await _remover.revealInFolder(path);
    _showToast(ResultsToast(text: 'Opening $folderName in your file manager'));
  }
  //#endregion

  //#region Toast
  void dismissToast() {
    _toastTimer?.cancel();
    emit(state.copyWith(toast: null));
  }

  void _showToast(ResultsToast toast) {
    _toastTimer?.cancel();
    emit(state.copyWith(toast: toast));
    _toastTimer = Timer(const Duration(seconds: 5), dismissToast);
  }
  //#endregion

  static String _plural(int n, String one, String many) =>
      '$n ${n == 1 ? one : many}';

  @override
  Future<void> close() {
    _toastTimer?.cancel();
    _subscription.cancel();
    return super.close();
  }
}
