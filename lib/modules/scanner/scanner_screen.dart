import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../models/duplicate_group_model.dart';
import '../../models/scan_progress_model.dart';
import '../../repository/duplicate_finder_repository_impl.dart';
import 'scanner_screen_cubit.dart';
import 'scanner_screen_state.dart';
import 'widgets/scan_progress_widget.dart';
import 'widgets/scan_stage_indicator_widget.dart';

/// Scanner screen — lets the user select directories, run a duplicate scan,
/// and view a summary of the results.
///
/// Mounts a [BlocProvider] that owns a [ScannerScreenCubit] backed by a
/// [DuplicateFinderRepositoryImpl] instance.
///
/// [storePath] is the ObjectBox store directory opened by the main isolate.
/// It is forwarded to [DuplicateFinderRepositoryImpl] so the worker isolate
/// can attach to the same store via `Store.attach`.
class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key, this.storePath = ''});

  final String storePath;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ScannerScreenCubit(
        repository: DuplicateFinderRepositoryImpl(storePath: storePath),
      ),
      child: const _ScannerScreenBody(),
    );
  }
}

// ---------------------------------------------------------------------------
// Body — dispatches to section widgets based on cubit state
// ---------------------------------------------------------------------------

class _ScannerScreenBody extends StatelessWidget {
  const _ScannerScreenBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScannerScreenCubit, ScannerScreenState>(
      builder: (context, state) => switch (state) {
        ScannerInitial(:final selectedPaths, :final byteByByteCompare) =>
          _FolderPickerSection(
            selectedPaths: selectedPaths,
            byteByByteCompare: byteByByteCompare,
          ),
        ScannerScanning(:final progress) => _ScanningSection(
            progress: progress,
          ),
        ScannerDone(:final groups) => _ResultsSummarySection(groups: groups),
        ScannerError(:final message) => _ErrorSection(message: message),
        ScannerCancelled(:final groups) => _CancelledSection(groups: groups),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _FolderPickerSection — initial state: pick folders, start scan
// ---------------------------------------------------------------------------

class _FolderPickerSection extends StatelessWidget {
  const _FolderPickerSection({
    required this.selectedPaths,
    required this.byteByByteCompare,
  });

  final List<String> selectedPaths;
  final bool byteByByteCompare;

  Future<void> _pickFolder(BuildContext context) async {
    final path = await getDirectoryPath();
    if (path != null && context.mounted) {
      context.read<ScannerScreenCubit>().addFolder(path);
    }
  }

  /// Collects [File] objects from all selected directories (recursive),
  /// silently skipping any entries that throw a [FileSystemException], then
  /// delegates to [ScannerScreenCubit.startScan].
  Future<void> _startScan(BuildContext context) async {
    final files = <File>[];
    for (final dirPath in selectedPaths) {
      try {
        await for (final entity
            in Directory(dirPath).list(recursive: true)) {
          if (entity is File) files.add(entity);
        }
      } on FileSystemException {
        // silently skip permission-denied or inaccessible entries
      }
    }
    if (context.mounted) {
      context.read<ScannerScreenCubit>().startScan(files);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Folders to Scan', style: theme.textTheme.headlineSmall),
          SizedBox(height: 16.h),
          OutlinedButton.icon(
            onPressed: () => _pickFolder(context),
            icon: const Icon(Icons.folder_open),
            label: const Text('Add Folder'),
          ),
          SizedBox(height: 16.h),
          if (selectedPaths.isNotEmpty) ...[
            Text(
              'Selected Folders (${selectedPaths.length})',
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: 8.h),
            ...selectedPaths.map(
              (path) => ListTile(
                dense: true,
                leading: const Icon(Icons.folder),
                title: Text(path, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Remove folder',
                  onPressed: () =>
                      context.read<ScannerScreenCubit>().removeFolder(path),
                ),
              ),
            ),
            SizedBox(height: 24.h),
          ],
          FilledButton.icon(
            onPressed:
                selectedPaths.isEmpty ? null : () => _startScan(context),
            icon: const Icon(Icons.search),
            label: const Text('Start Scan'),
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: byteByByteCompare,
                onChanged: (v) =>
                    context.read<ScannerScreenCubit>().setByteCompare(v),
              ),
              SizedBox(width: 8.w),
              const Text('Byte-by-byte verification'),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ScanningSection — shown while the worker isolate is running
// ---------------------------------------------------------------------------

class _ScanningSection extends StatelessWidget {
  const _ScanningSection({required this.progress});

  final ScanProgress progress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 48.w, vertical: 32.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScanStageIndicatorWidget(stage: progress.stage),
            SizedBox(height: 16.h),
            ScanProgressWidget(progress: progress),
            SizedBox(height: 24.h),
            Align(
              alignment: Alignment.center,
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.read<ScannerScreenCubit>().cancelScan(),
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Cancel Scan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CancelledSection — shown after the user cancels a scan
// ---------------------------------------------------------------------------

class _CancelledSection extends StatelessWidget {
  const _CancelledSection({required this.groups});

  final List<DuplicateGroup> groups;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel_outlined, size: 48.r, color: Colors.orange),
            SizedBox(height: 16.h),
            Text(
              'Scan Cancelled',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8.h),
            Text(
              groups.isEmpty
                  ? 'No duplicates found before cancellation.'
                  : 'Found ${groups.length} group${groups.length == 1 ? '' : 's'} '
                      'before cancellation.',
            ),
            SizedBox(height: 24.h),
            OutlinedButton.icon(
              onPressed: () => context.read<ScannerScreenCubit>().reset(),
              icon: const Icon(Icons.refresh),
              label: const Text('Scan Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ResultsSummarySection — shown on successful scan completion
// ---------------------------------------------------------------------------

class _ResultsSummarySection extends StatelessWidget {
  const _ResultsSummarySection({required this.groups});

  final List<DuplicateGroup> groups;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalFiles = groups.fold(0, (sum, g) => sum + g.paths.length);

    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Scan Complete', style: theme.textTheme.headlineSmall),
          SizedBox(height: 8.h),
          Text(
            groups.isEmpty
                ? 'No duplicate files found.'
                : 'Found ${groups.length} duplicate '
                    'group${groups.length == 1 ? '' : 's'} '
                    '($totalFiles files total)',
            style: theme.textTheme.bodyLarge,
          ),
          SizedBox(height: 24.h),
          if (groups.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 8.h),
                    child: ListTile(
                      leading: const Icon(Icons.copy_all),
                      title: Text(
                        'Group ${index + 1} — ${group.paths.length} copies',
                      ),
                      subtitle: Text(
                        group.paths.join('\n'),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                },
              ),
            ),
          SizedBox(height: 16.h),
          OutlinedButton.icon(
            onPressed: () => context.read<ScannerScreenCubit>().reset(),
            icon: const Icon(Icons.refresh),
            label: const Text('Scan Again'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ErrorSection — shown when the scan fails or is cancelled
// ---------------------------------------------------------------------------

class _ErrorSection extends StatelessWidget {
  const _ErrorSection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.r, color: Colors.red),
            SizedBox(height: 16.h),
            Text(
              'Scan Failed',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8.h),
            Text(message, textAlign: TextAlign.center),
            SizedBox(height: 24.h),
            OutlinedButton.icon(
              onPressed: () => context.read<ScannerScreenCubit>().reset(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
