import 'package:filesieve/utils/extensions.dart';
import 'package:filesieve/utils/format_utils.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/duplicate_group_view_model.dart';
import '../../../values/app_palette.dart';
import '../../../values/app_strings.dart';
import '../../../values/enums.dart';
import '../../app_settings/app_settings_cubit.dart';
import '../results_screen_cubit.dart';
import '../results_screen_state.dart';
import 'compare_preview_widget.dart';
import 'compare_version_card_widget.dart';

/// CompareBody — one duplicate group: navigation, the copies side by side with
/// Keep / Remove actions, and a sticky footer to remove all the others.
class CompareBody extends StatelessWidget {
  const CompareBody({super.key, required this.state, required this.group});

  final ResultsScreenState state;
  final DuplicateGroupView group;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ResultsScreenCubit>();
    final palette = context.palette;
    final keep = group.keepFor(state.keepSelection[group.key]);
    final others = [
      for (final v in group.remaining)
        if (v.path != keep?.path) v,
    ];
    final nav = state.navigableGroups;
    final position = nav.indexWhere((g) => g.key == group.key) + 1;
    final hasNext = state.activeGroups.any((g) => g.key != group.key);
    final previewPath = group.remaining.isEmpty ? null : group.remaining.first.path;
    final oldestPath = group.oldest.path;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(32.w, 20.h, 32.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopRow(
                  position: 'Group $position of ${nav.length}',
                  onBack: cubit.closeGroup,
                  onPrevious: () => cubit.stepGroup(-1),
                  onNext: () => cubit.stepGroup(1),
                ),
                SizedBox(height: 18.h),
                _Title(group: group),
                if (group.isResolved) ...[
                  SizedBox(height: 18.h),
                  _ResolvedBanner(
                    hasNext: hasNext,
                    onPressed: hasNext ? () => cubit.stepGroup(1) : cubit.closeGroup,
                  ),
                ],
                SizedBox(height: 18.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 300.w,
                      child: ComparePreviewWidget(group: group, previewPath: previewPath),
                    ),
                    SizedBox(width: 18.w),
                    Expanded(
                      child: Column(
                        children: [
                          for (final v in group.versions) ...[
                            CompareVersionCardWidget(
                              key: ValueKey('compare.version.${v.path}'),
                              version: v,
                              isKeep: v.path == keep?.path,
                              isOldest: v.path == oldestPath,
                              canRestore: cubit.canRestore,
                              busy: state.busy,
                              onKeep: () => cubit.keepCopy(group.key, v.path),
                              onRemove: () => cubit.requestRemove(
                                [v.path],
                                '1 copy of ${group.name}',
                              ),
                              onReveal: () => cubit.revealInFolder(v.path, v.folderName),
                              onRestore: () => cubit.restore([v.path]),
                            ),
                            SizedBox(height: 10.h),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (!group.isResolved && keep != null)
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.footer,
              border: Border(top: BorderSide(color: palette.line)),
            ),
            child: _Footer(
              keepFolder: keep.folderName,
              otherCount: others.length,
              freedBytes: others.length * group.bytesEach,
              busy: state.busy,
              onSkip: () => cubit.stepGroup(1),
              onKeepOthers: () => cubit.requestRemove(
                [for (final v in others) v.path],
                '${others.length} ${others.length == 1 ? 'copy' : 'copies'} of ${group.name}',
              ),
            ),
          ),
      ],
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.position,
    required this.onBack,
    required this.onPrevious,
    required this.onNext,
  });

  final String position;
  final VoidCallback onBack;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12.w,
      runSpacing: 8.h,
      children: [
        TextButton.icon(
          key: const ValueKey('compare.back'),
          onPressed: onBack,
          icon: Icon(Icons.chevron_left, size: 16.r),
          label: const Text(AppStrings.cmpBack),
          style: TextButton.styleFrom(
            foregroundColor: palette.muted,
            textStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              position,
              key: const ValueKey('compare.position'),
              style: TextStyle(fontSize: 13.sp, color: palette.muted),
            ),
            SizedBox(width: 12.w),
            _SquareButton(
              buttonKey: 'compare.previous',
              tooltip: AppStrings.cmpPrevious,
              icon: Icons.chevron_left,
              onPressed: onPrevious,
            ),
            SizedBox(width: 6.w),
            _SquareButton(
              buttonKey: 'compare.next',
              tooltip: AppStrings.cmpNext,
              icon: Icons.chevron_right,
              onPressed: onNext,
            ),
          ],
        ),
      ],
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
    required this.buttonKey,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String buttonKey;
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Tooltip(
      message: tooltip,
      child: Material(
        key: ValueKey(buttonKey),
        color: palette.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9.r),
          side: BorderSide(color: palette.line),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(9.r),
          child: SizedBox(
            width: 36.r,
            height: 36.r,
            child: Icon(icon, size: 16.r, color: palette.text),
          ),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.group});

  final DuplicateGroupView group;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final copies = group.remaining.length;
    final meta = StringBuffer(
      '${formatBytes(group.bytesEach)} each · $copies ${copies == 1 ? 'copy' : 'copies'}',
    );
    if (!group.isResolved) {
      meta.write(' · ${formatBytes(group.reclaimableBytes)} to reclaim');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          group.name,
          key: const ValueKey('compare.title'),
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 26.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.26,
            color: palette.text,
          ),
        ),
        SizedBox(height: 6.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 6.h,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              height: 24.h,
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              decoration: BoxDecoration(
                color: palette.okSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 12.r, color: palette.ok),
                  SizedBox(width: 6.w),
                  Text(
                    AppStrings.cmpIdentical,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: palette.ok,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              meta.toString(),
              style: TextStyle(fontSize: 13.sp, color: palette.muted),
            ),
          ],
        ),
      ],
    );
  }
}

class _ResolvedBanner extends StatelessWidget {
  const _ResolvedBanner({required this.hasNext, required this.onPressed});

  final bool hasNext;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      key: const ValueKey('compare.resolved'),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: palette.okSoft,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: palette.okLine),
      ),
      child: Row(
        children: [
          Icon(Icons.check, size: 18.r, color: palette.ok),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              AppStrings.cmpSorted,
              style: TextStyle(fontSize: 14.sp, color: palette.text),
            ),
          ),
          FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppPalette.brand,
              minimumSize: Size(0, 38.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            child: Text(hasNext ? AppStrings.cmpNext : AppStrings.cmpBackToList),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.keepFolder,
    required this.otherCount,
    required this.freedBytes,
    required this.busy,
    required this.onSkip,
    required this.onKeepOthers,
  });

  final String keepFolder;
  final int otherCount;
  final int freedBytes;
  final bool busy;
  final VoidCallback onSkip;
  final VoidCallback onKeepOthers;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final trash = context.select<AppSettingsCubit, bool>(
      (c) => c.state.removalMode == RemovalMode.trash,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Keeping 1 copy in $keepFolder · removing $otherCount frees ${formatBytes(freedBytes)}'
              '${trash ? ' · goes to Trash' : ' · deleted permanently'}',
              key: const ValueKey('compare.footerLine'),
              style: TextStyle(fontSize: 13.sp, color: palette.muted),
            ),
          ),
          SizedBox(width: 12.w),
          OutlinedButton(
            key: const ValueKey('compare.skip'),
            onPressed: onSkip,
            style: OutlinedButton.styleFrom(
              foregroundColor: palette.text,
              backgroundColor: palette.panelStrong,
              side: BorderSide(color: palette.line),
              minimumSize: Size(0, 42.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            child: const Text(AppStrings.cmpSkip),
          ),
          SizedBox(width: 12.w),
          FilledButton(
            key: const ValueKey('compare.keepOthers'),
            onPressed: busy || otherCount == 0 ? null : onKeepOthers,
            style: FilledButton.styleFrom(
              backgroundColor: AppPalette.brand,
              minimumSize: Size(0, 42.h),
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            child: Text(
              'Keep selected, remove $otherCount ${otherCount == 1 ? 'other' : 'others'}',
            ),
          ),
        ],
      ),
    );
  }
}
