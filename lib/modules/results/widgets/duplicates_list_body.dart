import 'package:filesieve/utils/extensions.dart';
import 'package:filesieve/utils/format_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../values/app_palette.dart';
import '../../../values/app_routes.dart';
import '../../../values/app_strings.dart';
import '../results_screen_cubit.dart';
import '../results_screen_state.dart';
import 'duplicate_filter_chips_widget.dart';
import 'duplicate_group_row_widget.dart';
import 'results_empty_state_widget.dart';

/// DuplicatesListBody — header, type filter and the table of duplicate groups.
class DuplicatesListBody extends StatelessWidget {
  const DuplicatesListBody({super.key, required this.state});

  final ResultsScreenState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ResultsScreenCubit>();
    final active = state.activeGroups;
    final groupWord = active.length == 1 ? 'group' : 'groups';
    final copyWord = state.extraCopies == 1 ? 'extra copy' : 'extra copies';

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 28.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            summary: active.isEmpty
                ? AppStrings.dupTidy
                : '${active.length} $groupWord · ${state.extraCopies} $copyWord · all 100% identical',
            removeAllLabel:
                'Remove all identical copies · ${formatBytes(state.reclaimableBytes)}',
            showRemoveAll: active.isNotEmpty,
            busy: state.busy,
            onRemoveAll: cubit.openRemoveAll,
          ),
          SizedBox(height: 18.h),
          if (active.isNotEmpty) ...[
            DuplicateFilterChipsWidget(
              selected: state.filter,
              countFor: state.countFor,
              onSelected: cubit.setFilter,
            ),
            SizedBox(height: 18.h),
            _Table(state: state),
          ] else
            ResultsEmptyStateWidget(
              hasScanned: state.hasScanned,
              freedBytes: state.freedBytes,
              freedCount: state.freedCount,
              onAction: () => context.go(AppRoutes.home),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.summary,
    required this.removeAllLabel,
    required this.showRemoveAll,
    required this.busy,
    required this.onRemoveAll,
  });

  final String summary;
  final String removeAllLabel;
  final bool showRemoveAll;
  final bool busy;
  final VoidCallback onRemoveAll;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 16.w,
      runSpacing: 12.h,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.dupTitle,
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 28.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.56,
                color: palette.text,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              summary,
              key: const ValueKey('results.summary'),
              style: TextStyle(fontSize: 14.sp, color: palette.muted),
            ),
          ],
        ),
        if (showRemoveAll)
          FilledButton.icon(
            key: const ValueKey('results.removeAll'),
            onPressed: busy ? null : onRemoveAll,
            icon: Icon(Icons.delete_outline, size: 16.r),
            label: Text(removeAllLabel),
            style: FilledButton.styleFrom(
              backgroundColor: AppPalette.destructive,
              minimumSize: Size(0, 44.h),
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11.r)),
            ),
          ),
      ],
    );
  }
}

class _Table extends StatelessWidget {
  const _Table({required this.state});

  final ResultsScreenState state;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final cubit = context.read<ResultsScreenCubit>();
    final groups = state.visibleGroups;
    final headStyle = TextStyle(
      fontSize: 12.sp,
      fontWeight: FontWeight.w600,
      color: palette.muted,
    );
    final gap = SizedBox(width: DuplicateTableColumns.gap);

    return Container(
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: palette.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Row(
              children: [
                Expanded(child: Text(AppStrings.dupColFile, style: headStyle)),
                gap,
                SizedBox(
                  width: DuplicateTableColumns.copies,
                  child: Text(AppStrings.dupColCopies, style: headStyle),
                ),
                gap,
                SizedBox(
                  width: DuplicateTableColumns.size,
                  child: Text(AppStrings.dupColSizeEach, style: headStyle),
                ),
                gap,
                SizedBox(
                  width: DuplicateTableColumns.reclaimable,
                  child: Text(
                    AppStrings.dupColReclaimable,
                    textAlign: TextAlign.right,
                    style: headStyle,
                  ),
                ),
                gap,
                SizedBox(width: DuplicateTableColumns.chevron),
              ],
            ),
          ),
          Divider(color: palette.line),
          for (final g in groups)
            DuplicateGroupRowWidget(
              key: ValueKey('results.row.${g.key}'),
              group: g,
              onOpen: () => cubit.openGroup(g.key),
            ),
          if (groups.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 16.w),
              child: Center(
                child: Text(
                  AppStrings.dupFilterEmpty,
                  style: TextStyle(fontSize: 13.sp, color: palette.muted),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
