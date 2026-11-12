import 'dart:ui';

import 'package:filesieve/utils/extensions.dart';
import 'package:filesieve/utils/format_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../values/app_palette.dart';
import '../../../values/app_routes.dart';
import '../../../values/app_strings.dart';
import '../../../values/enums.dart';
import '../../app_settings/app_settings_cubit.dart';
import '../results_screen_cubit.dart';
import '../results_screen_state.dart';

/// ResultsOverlaysWidget — the confirm dialog and the toast, drawn above the
/// whole window. Renders nothing while neither is active.
class ResultsOverlaysWidget extends StatelessWidget {
  const ResultsOverlaysWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResultsScreenCubit, ResultsScreenState>(
      buildWhen: (a, b) =>
          a.dialog != b.dialog ||
          a.toast != b.toast ||
          a.keepRule != b.keepRule ||
          a.busy != b.busy,
      builder: (context, state) {
        return Stack(
          children: [
            if (state.dialog != null)
              Positioned.fill(child: _ConfirmDialog(state: state, dialog: state.dialog!)),
            if (state.toast != null)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 24.h),
                    child: _Toast(toast: state.toast!),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({required this.state, required this.dialog});

  final ResultsScreenState state;
  final ResultsDialog dialog;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final cubit = context.read<ResultsScreenCubit>();
    final trash = context.select<AppSettingsCubit, bool>(
      (c) => c.state.removalMode == RemovalMode.trash,
    );
    final isAll = dialog.kind == ResultsDialogKind.removeAll;
    final extra = state.extraCopies;
    final groupCount = state.activeGroups.length;

    final title = isAll
        ? AppStrings.dlgRemoveAllTitle
        : trash
        ? AppStrings.dlgTrashTitle
        : AppStrings.dlgDeleteTitle;
    final body = isAll
        ? 'One copy of every file is kept. The other $extra ${extra == 1 ? 'copy' : 'copies'} '
              'across $groupCount ${groupCount == 1 ? 'group' : 'groups'} are removed, '
              'freeing ${formatBytes(state.reclaimableBytes)}.'
        : '${trash ? 'This moves' : 'This permanently deletes'} ${dialog.label}.'
              '${trash ? '' : ' It can’t be recovered.'}';
    final cta = isAll
        ? 'Remove $extra ${extra == 1 ? 'copy' : 'copies'}'
        : trash
        ? AppStrings.dlgMoveToTrash
        : AppStrings.dlgDeletePermanently;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: cubit.cancelDialog,
            child: ColoredBox(color: palette.overlay),
          ),
        ),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 480.w.clamp(420, 560)),
            child: Semantics(
              scopesRoute: true,
              explicitChildNodes: true,
              label: title,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18.r),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                  child: Container(
                    key: const ValueKey('results.dialog'),
                    padding: EdgeInsets.all(24.r),
                    decoration: BoxDecoration(
                      color: palette.dialog,
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(color: palette.glassBorder),
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40.r,
                                height: 40.r,
                                decoration: BoxDecoration(
                                  color: palette.dangerSoft,
                                  borderRadius: BorderRadius.circular(11.r),
                                ),
                                child: Icon(Icons.delete_outline, size: 20.r, color: palette.danger),
                              ),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontFamily: 'Space Grotesk',
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.w600,
                                        color: palette.text,
                                      ),
                                    ),
                                    SizedBox(height: 6.h),
                                    Text(
                                      body,
                                      key: const ValueKey('results.dialog.body'),
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        height: 1.55,
                                        color: palette.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (isAll) ...[
                            SizedBox(height: 18.h),
                            _KeepRules(selected: state.keepRule, onSelected: cubit.setKeepRule),
                          ],
                          SizedBox(height: 18.h),
                          _Note(trash: trash),
                          SizedBox(height: 18.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                key: const ValueKey('results.dialog.cancel'),
                                onPressed: cubit.cancelDialog,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: palette.text,
                                  backgroundColor: palette.panelStrong,
                                  side: BorderSide(color: palette.line),
                                  minimumSize: Size(0, 42.h),
                                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                ),
                                child: const Text(AppStrings.dlgCancel),
                              ),
                              SizedBox(width: 8.w),
                              FilledButton(
                                key: const ValueKey('results.dialog.confirm'),
                                onPressed: state.busy ? null : cubit.confirmDialog,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppPalette.destructive,
                                  minimumSize: Size(0, 42.h),
                                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                ),
                                child: Text(cta),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _KeepRules extends StatelessWidget {
  const _KeepRules({required this.selected, required this.onSelected});

  final KeepRule selected;
  final ValueChanged<KeepRule> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.dlgKeepRuleLegend,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: palette.muted,
          ),
        ),
        SizedBox(height: 8.h),
        for (final rule in KeepRule.values)
          Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Semantics(
              inMutuallyExclusiveGroup: true,
              checked: rule == selected,
              child: Material(
                key: ValueKey('results.keepRule.${rule.name}'),
                color: rule == selected ? palette.accentSoft : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  side: BorderSide(
                    color: rule == selected ? palette.accentLine : palette.line,
                  ),
                ),
                child: InkWell(
                  onTap: () => onSelected(rule),
                  borderRadius: BorderRadius.circular(10.r),
                  child: SizedBox(
                    height: 40.h,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Row(
                        children: [
                          Icon(
                            rule == selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            size: 18.r,
                            color: rule == selected ? AppPalette.brand : palette.muted,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            rule.label,
                            style: TextStyle(fontSize: 14.sp, color: palette.text),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.trash});

  final bool trash;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = trash ? palette.muted : palette.danger;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: trash ? palette.panel : palette.dangerSoft,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16.r, color: color),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              trash ? AppStrings.dlgTrashNote : AppStrings.dlgDeleteNote,
              style: TextStyle(fontSize: 13.sp, color: color),
            ),
          ),
          TextButton(
            key: const ValueKey('results.dialog.change'),
            onPressed: () {
              context.read<ResultsScreenCubit>().cancelDialog();
              context.go(AppRoutes.settings);
            },
            style: TextButton.styleFrom(foregroundColor: palette.accentText),
            child: const Text(AppStrings.dlgChange),
          ),
        ],
      ),
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast({required this.toast});

  final ResultsToast toast;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final cubit = context.read<ResultsScreenCubit>();

    return Semantics(
      liveRegion: true,
      child: Material(
        key: const ValueKey('results.toast'),
        color: palette.toast,
        elevation: 12,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 10.w, 10.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  toast.text,
                  style: TextStyle(fontSize: 14.sp, color: palette.toastText),
                ),
              ),
              if (toast.undoPaths.isNotEmpty) ...[
                SizedBox(width: 14.w),
                TextButton(
                  key: const ValueKey('results.toast.undo'),
                  onPressed: () => cubit.restore(toast.undoPaths),
                  style: TextButton.styleFrom(
                    foregroundColor: palette.toastText,
                    backgroundColor: const Color(0x387F8CFF),
                    minimumSize: Size(0, 32.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  child: const Text(AppStrings.toastUndo),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
