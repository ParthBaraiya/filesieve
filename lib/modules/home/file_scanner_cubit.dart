import 'dart:collection';
import 'dart:io';

import 'package:filesieve/models/duplicate_group_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repository/duplicate_finder/duplicate_finder_repository_base.dart';
import '../../utils/cancel_token.dart';
import 'file_scanner_state.dart';

class FileScannerCubit extends Cubit<FileScannerState> {
  FileScannerCubit({required DuplicateFinderRepositoryBase repo})
    : _scanRepository = repo,
      super(.initial());

  final DuplicateFinderRepositoryBase _scanRepository;

  Future<void> startScan(Iterable<String> folders) async {
    if (state is FileScannerStateScanningStarted) return;

    final cancelToken = CancelToken();
    emit(
      .scanning(
        cancelToken: cancelToken,
        progress: .zero,
        groups: UnmodifiableListView([]),
      ),
    );

    try {
      // TODO(copilot): when a scan starts, an entry of the scan should be
      // stored in the database.
      //
      // As scan progresses, the progress should be updated in the database
      final groups = <DuplicateGroup>[];
      await _scanRepository.find(
        folders: folders.map((f) => Directory(f)).toList(),
        onProgress: (progress) {
          emit(
            FileScannerState.scanning(
              progress: progress,
              cancelToken: cancelToken,
              groups: UnmodifiableListView(groups),
            ),
          );
        },
        onGroupFound: (group) {
          if (state is FileScannerStateScanningStarted) {
            groups.add(group);
            emit(
              (state as FileScannerStateScanningStarted).copyWith(
                groups: UnmodifiableListView(groups),
              ),
            );
          }
        },
        cancelToken: cancelToken,
      );
      // TODO(future): navigate to results screen
    } on ScanCancelledException {
      emit(.error(error: .scanningCancelled));
    } catch (e, stack) {
      emit(
        .error(
          error: .unknown(
            title: 'Scanning Failed!',
            description:
                'Something went wrong while scanning for duplicates. Please try again after some time.',
            stackTrace: stack,
            metadata: e,
          ),
        ),
      );
    }
  }

  void cancelScan() {
    if (state is! FileScannerStateScanningStarted) return;
    (state as FileScannerStateScanningStarted).cancelToken?.cancel();
  }

  // NOTE: We might not need this right now. But we might need this in future.
  // Remove this once scanner screen if fully completed.
  // double _computeOverallPercent(ScanProgress sp, double currentOverallPercent) {
  //   final ratio = sp.stageTotal == 0
  //       ? 0.0
  //       : (sp.stageProcessed / sp.stageTotal).clamp(0.0, 1.0);
  //   switch (sp.stage) {
  //     case ScanProgressStage.scanningFile: // 5
  //       return ratio * 5;
  //     case ScanProgressStage.extractMetadata: // 10
  //       return 5 + ratio * 5;
  //     case ScanProgressStage.groupingBySize: // 15
  //       return 10 + ratio * 5;
  //     case ScanProgressStage.calcPartialHash: // 30
  //       return 15 + ratio * 15;
  //     case ScanProgressStage.groupingByPartialHash: // 35
  //       return 30 + ratio * 5;
  //     case ScanProgressStage.calcFullHash: // 55
  //       return 35 + ratio * 20;
  //     case ScanProgressStage.groupingByFullHash: // 70
  //       return 55 + ratio * 15;
  //     case ScanProgressStage.byteByByteCompare: // 99
  //       return 60 + ratio * 39;
  //     case ScanProgressStage.completed: // 100
  //       return 100;
  //   }
  // }
}
