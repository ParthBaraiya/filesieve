import 'package:filesieve/models/app_settings_model.dart';
import 'package:filesieve/modules/app_settings/app_settings_cubit.dart';
import 'package:filesieve/modules/home/file_scanner_cubit.dart';
import 'package:filesieve/modules/results/results_screen_cubit.dart';
import 'package:filesieve/modules/results/results_screen_state.dart';
import 'package:filesieve/values/enums.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/results_fakes.dart';

void main() {
  late FakeRemover remover;
  late AppSettingsCubit settings;
  late FileScannerCubit scanner;
  late ResultsScreenCubit cubit;

  Future<void> setUpCubit() async {
    remover = FakeRemover();
    settings = AppSettingsCubit(
      repository: MemorySettings(),
      initial: const AppSettingsModel(),
    );
    scanner = FileScannerCubit(
      repo: FakeFinder([
        makeGroup('small.txt', 100, [('A', 0), ('B', 5)]),
        makeGroup('big.mp4', 1000, [('A', 3), ('B', 1), ('Docs', 9)]),
      ]),
    );
    cubit = ResultsScreenCubit(
      scanner: scanner,
      settings: settings,
      remover: remover,
    );
    await scanner.startScan(['C:\\A']);
    await Future<void>.delayed(Duration.zero);
  }

  setUp(setUpCubit);
  tearDown(() async {
    await cubit.close();
    await scanner.close();
    await settings.close();
  });

  test('groups are listed biggest reclaimable first with correct totals', () {
    final s = cubit.state;
    expect(s.activeGroups.map((g) => g.name), ['big.mp4', 'small.txt']);
    expect(s.extraCopies, 3);
    expect(s.reclaimableBytes, 2 * 1000 + 100);
    expect(s.hasScanned, isTrue);
  });

  test('trash removal skips confirmation and offers undo', () async {
    final group = cubit.state.activeGroups.first;
    final path = group.versions.first.path;

    await cubit.requestRemove([path], '1 copy of big.mp4');

    expect(remover.removed[path], RemovalMode.trash);
    expect(cubit.state.dialog, isNull);
    expect(cubit.state.toast?.text, 'Moved 1 copy of big.mp4 to Trash');
    expect(cubit.state.toast?.undoPaths, [path]);
    expect(cubit.state.freedBytes, 1000);
    expect(cubit.state.openGroup, isNull);
    expect(cubit.state.activeGroups.first.remaining.length, 2);
  });

  test('permanent removal asks first, and has no undo', () async {
    settings.setRemovalMode(RemovalMode.permanent);
    final path = cubit.state.activeGroups.first.versions.first.path;

    await cubit.requestRemove([path], '1 copy of big.mp4');
    expect(cubit.state.dialog?.kind, ResultsDialogKind.removeSome);
    expect(remover.removed, isEmpty);

    await cubit.confirmDialog();
    expect(remover.removed[path], RemovalMode.permanent);
    expect(cubit.state.dialog, isNull);
    expect(cubit.state.toast?.undoPaths, isEmpty);
    expect(cubit.state.toast?.text, 'Permanently deleted 1 copy of big.mp4');
  });

  test('confirm-every-removal switch forces the dialog in trash mode', () async {
    settings.setConfirmBeforeEveryRemoval(true);
    await cubit.requestRemove([cubit.state.activeGroups.first.versions.first.path], 'x');
    expect(cubit.state.dialog, isNotNull);
    cubit.cancelDialog();
    expect(cubit.state.dialog, isNull);
    expect(remover.removed, isEmpty);
  });

  test('remove all groups files by the exact set of folders they are in', () {
    final combos = cubit.state.folderCombos;
    // big.mp4 is in A, B, Docs; small.txt is in A, B. Each group is in one combo.
    expect(combos.length, 2);
    expect(combos.every((c) => c.fileCount == 1), isTrue);
    expect(combos.map((c) => c.folders.length).toSet(), {2, 3});
    expect(cubit.state.choiceCombos.length, 2);
  });

  test('remove all needs a folder choice for every combo before it removes', () async {
    cubit.openRemoveAll();
    await cubit.confirmDialog();
    expect(remover.removed, isEmpty);

    cubit.nextRemoveStep(); // nothing chosen yet -> stays on step 0
    expect(cubit.state.removeStep, 0);
  });

  test('remove all keeps the chosen folder per combo and removes the rest', () async {
    cubit.openRemoveAll();
    final combos = cubit.state.choiceCombos;
    // Pick the first folder of each combo (sorted by path: A before B/Docs).
    for (final c in combos) {
      cubit.chooseFolder(c.key, c.folders.first);
      cubit.nextRemoveStep();
    }
    expect(cubit.state.removeStep, combos.length);
    await cubit.confirmDialog();

    expect(remover.removed.containsKey(r'C:\A\big.mp4'), isFalse);
    expect(remover.removed.containsKey(r'C:\A\small.txt'), isFalse);
    expect(
      remover.removed.keys,
      containsAll([r'C:\B\big.mp4', r'C:\Docs\big.mp4', r'C:\B\small.txt']),
    );
    expect(remover.removed.length, 3);
    expect(cubit.state.activeGroups, isEmpty);
    expect(cubit.state.freedBytes, 2100);
  });

  test('back goes to the previous combo and keeps its answer', () {
    cubit.openRemoveAll();
    final combos = cubit.state.choiceCombos;
    cubit.chooseFolder(combos[0].key, combos[0].folders.last);
    cubit.nextRemoveStep();
    cubit.previousRemoveStep();
    expect(cubit.state.removeStep, 0);
    expect(cubit.state.folderChoices[combos[0].key], combos[0].folders.last);
  });

  test('restore puts files back and reduces freed bytes', () async {
    final path = cubit.state.activeGroups.first.versions.first.path;
    await cubit.requestRemove([path], 'x');
    await cubit.restore([path]);

    expect(remover.removed, isEmpty);
    expect(cubit.state.freedBytes, 0);
    expect(cubit.state.activeGroups.first.remaining.length, 3);
    expect(cubit.state.toast, isNull);
  });

  test('a failed removal is reported and not counted as freed', () async {
    final path = cubit.state.activeGroups.first.versions.first.path;
    remover.failing.add(path);
    await cubit.requestRemove([path], 'x');

    expect(cubit.state.freedBytes, 0);
    expect(cubit.state.toast?.text, contains("Couldn't remove 1 file"));
    expect(cubit.state.activeGroups.first.remaining.length, 3);
  });

  test('stepping through groups wraps around', () {
    final keys = cubit.state.navigableGroups.map((g) => g.key).toList();
    cubit.openGroup(keys.first);
    cubit.stepGroup(1);
    expect(cubit.state.openGroupKey, keys[1]);
    cubit.stepGroup(1);
    expect(cubit.state.openGroupKey, keys.first);
    cubit.stepGroup(-1);
    expect(cubit.state.openGroupKey, keys[1]);
  });

  test('resolved group stays reachable while open', () async {
    final group = cubit.state.activeGroups.last; // small.txt, 2 copies
    cubit.openGroup(group.key);
    await cubit.requestRemove([group.versions.last.path], 'x');

    expect(cubit.state.openGroup?.isResolved, isTrue);
    expect(cubit.state.activeGroups.length, 1);
    expect(cubit.state.navigableGroups.length, 2);
  });

  test('scanner reset clears the whole session', () async {
    await cubit.requestRemove([cubit.state.activeGroups.first.versions.first.path], 'x');
    await scanner.reset();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.groups, isEmpty);
    expect(cubit.state.removed, isEmpty);
    expect(cubit.state.freedBytes, 0);
    expect(cubit.state.hasScanned, isFalse);
  });
}
