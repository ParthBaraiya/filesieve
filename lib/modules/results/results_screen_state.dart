import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/duplicate_group_view_model.dart';
import '../../values/enums.dart';

part 'results_screen_state.freezed.dart';

/// Which confirmation dialog is open.
enum ResultsDialogKind { removeSome, removeAll }

/// A pending confirmation: remove [paths] ([removeSome]) or one copy of every
/// group ([removeAll], where the paths are worked out on confirm).
@freezed
abstract class ResultsDialog with _$ResultsDialog {
  const factory ResultsDialog({
    required ResultsDialogKind kind,
    @Default(<String>[]) List<String> paths,
    @Default('') String label,
  }) = _ResultsDialog;
}

/// A short message at the bottom of the window, optionally with Undo.
@freezed
abstract class ResultsToast with _$ResultsToast {
  const factory ResultsToast({
    required String text,
    @Default(<String>[]) List<String> undoPaths,
  }) = _ResultsToast;
}

@freezed
abstract class ResultsScreenState with _$ResultsScreenState {
  const ResultsScreenState._();

  const factory ResultsScreenState({
    /// Every group found by the last scan, with this session's removals applied.
    @Default(<DuplicateGroupView>[]) List<DuplicateGroupView> groups,

    /// Active type filter; null shows all.
    FileCategory? filter,

    /// Path -> how it was removed this session.
    @Default(<String, RemovalMode>{}) Map<String, RemovalMode> removed,

    /// Group key -> path of the copy the user chose to keep.
    @Default(<String, String>{}) Map<String, String> keepSelection,
    @Default(KeepRule.oldest) KeepRule keepRule,

    /// Key of the group open in the compare view; null shows the list.
    String? openGroupKey,
    ResultsDialog? dialog,
    ResultsToast? toast,

    /// True while files are being removed (blocks a second submit).
    @Default(false) bool busy,
    @Default(0) int freedBytes,
    @Default(0) int freedCount,

    /// True once a scan has been started in this session.
    @Default(false) bool hasScanned,
  }) = _ResultsScreenState;

  /// Groups that still have two or more copies.
  List<DuplicateGroupView> get activeGroups =>
      groups.where((g) => g.isActive).toList();

  List<DuplicateGroupView> get visibleGroups => activeGroups
      .where((g) => filter == null || g.category == filter)
      .toList();

  int countFor(FileCategory? category) => activeGroups
      .where((g) => category == null || g.category == category)
      .length;

  int get extraCopies =>
      activeGroups.fold(0, (sum, g) => sum + g.remaining.length - 1);

  int get reclaimableBytes =>
      activeGroups.fold(0, (sum, g) => sum + g.reclaimableBytes);

  DuplicateGroupView? get openGroup {
    for (final g in groups) {
      if (g.key == openGroupKey) return g;
    }
    return null;
  }

  /// Groups the compare view can step through: unresolved ones plus the open one.
  List<DuplicateGroupView> get navigableGroups =>
      groups.where((g) => g.isActive || g.key == openGroupKey).toList();
}
