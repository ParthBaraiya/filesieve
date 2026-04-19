import 'package:uuid/uuid.dart';
import '../../models/scan_folder_model.dart';
import '../../models/scan_session_model.dart';
import 'scan_session_repository_base.dart';

/// ScanSessionRepositoryImpl — stub implementation of [ScanSessionRepository].
///
/// For the onboarding feature scope, both query methods always return false
/// (no existing sessions). ObjectBox persistence will be wired up in a future
/// feature.
class ScanSessionRepository implements ScanSessionRepositoryBase {
  const ScanSessionRepository();

  static const _uuid = Uuid();

  @override
  Future<bool> hasActiveSession() async => false;

  @override
  Future<bool> hasCompletedResults() async => false;

  @override
  Future<ScanSessionModel> createSession(List<ScanFolderModel> folders) async {
    return ScanSessionModel(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
      folders: folders,
    );
  }
}
