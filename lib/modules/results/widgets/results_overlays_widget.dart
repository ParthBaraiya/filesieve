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
import '../../../models/duplicate_group_view_model.dart';
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
          a.folderChoices != b.folderChoices ||
          a.removeStep != b.removeStep ||
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

    final combos = state.choiceCombos;
    final onChoiceStep = isAll && state.removeStep < combos.length;
    final combo = onChoiceStep ? combos[state.removeStep] : null;
    final hasSingleFolderGroups = state.folderCombos.any((c) => !c.needsChoice);

    final title = onChoiceStep
        ? AppStrings.dlgChooseFolderTitle
        : isAll
        ? AppStrings.dlgRemoveAllTitle
        : trash
        ? AppStrings.dlgTrashTitle
        : AppStrings.dlgDeleteTitle;
    final body = onChoiceStep
        ? 'Step ${state.removeStep + 1} of ${combos.length} · '
              '${combo!.fileCount} ${combo.fileCount == 1 ? 'file is' : 'files are'} '
              'in all ${combo.folders.length} of these folders. '
              'Copies in the folders you don’t pick are removed.'
        : isAll
        ? 'In each group, one copy is kept: the oldest one in the folder you chose. '
              'The other $extra ${extra == 1 ? 'copy' : 'copies'} '
              'across $groupCount ${groupCount == 1 ? 'group' : 'groups'} are removed, '
              'freeing ${formatBytes(state.reclaimableBytes)}.'
              '${hasSingleFolderGroups ? ' Groups whose copies are all in one folder keep their oldest copy.' : ''}'
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
            constraints: BoxConstraints(
              maxWidth: 480.w.clamp(420, 560),
              maxHeight: MediaQuery.sizeOf(context).height - 48,
            ),
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
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
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
                          SizedBox(height: 18.h),
                          if (combo != null)
                            _FolderChoices(
                              folders: combo.folders,
                              selected: state.folderChoices[combo.key],
                              onSelected: (f) => cubit.chooseFolder(combo.key, f),
                            )
                          else
                            _Note(trash: trash),
                          SizedBox(height: 18.h),
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 8.w,
                            runSpacing: 8.h,
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
                              if (isAll && state.removeStep > 0)
                                OutlinedButton(
                                  key: const ValueKey('results.dialog.back'),
                                  onPressed: cubit.previousRemoveStep,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: palette.text,
                                    side: BorderSide(color: palette.line),
                                    minimumSize: Size(0, 42.h),
                                    padding: EdgeInsets.symmetric(horizontal: 18.w),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                  ),
                                  child: const Text(AppStrings.dlgBack),
                                ),
                              if (onChoiceStep)
                                FilledButton(
                                  key: const ValueKey('results.dialog.next'),
                                  onPressed: state.folderChoices.containsKey(combo!.key)
                                      ? cubit.nextRemoveStep
                                      : null,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppPalette.brand,
                                    minimumSize: Size(0, 42.h),
                                    padding: EdgeInsets.symmetric(horizontal: 18.w),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                  ),
                                  child: const Text(AppStrings.dlgNext),
                                )
                              else
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

/// One radio row per folder; the picked folder keeps its copies.
class _FolderChoices extends StatelessWidget {
  const _FolderChoices({
    required this.folders,
    required this.selected,
    required this.onSelected,
  });

  final List<String> folders;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Keep the copies in',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: palette.muted,
          ),
        ),
        SizedBox(height: 8.h),
        for (var i = 0; i < folders.length; i++)
          _FolderChoiceRow(
            key: ValueKey('results.folderChoice.$i'),
            folder: folders[i],
            isSelected: selected != null && isSameFolder(selected!, folders[i]),
            onTap: () => onSelected(folders[i]),
          ),
      ],
    );
  }
}

class _FolderChoiceRow extends StatelessWidget {
  const _FolderChoiceRow({
    super.key,
    required this.folder,
    required this.isSelected,
    required this.onTap,
  });

  final String folder;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        checked: isSelected,
        child: Material(
          color: isSelected ? palette.accentSoft : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
            side: BorderSide(
              color: isSelected ? palette.accentLine : palette.line,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10.r),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: 40.h),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 18.r,
                      color: isSelected ? AppPalette.brand : palette.muted,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        folder,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14.sp, color: palette.text),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
