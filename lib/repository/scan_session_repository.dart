import '../models/scan_folder_model.dart';
import '../models/scan_session_model.dart';

/// ScanSessionRepository — abstract interface for session persistence.
///
/// Both query methods are used by LoadingScreen on app launch (T039) to
/// perform 3-branch routing per FR-001:
///   1. [hasCompletedResults] — checked first; routes to /results if true.
///   2. [hasActiveSession]    — checked second; routes to /scanner if true
///      and no completed results exist.
abstract class ScanSessionRepository {
  /// Returns true if there is an in-progress or pending scan session.
  /// Used on app launch: routes to `/scanner` if true and no completed
  /// results (checked second).
  Future<bool> hasActiveSession();

  /// Returns true if there are completed scan results available to review.
  /// Used on app launch: routes to `/results` if true (checked first —
  /// takes priority).
  Future<bool> hasCompletedResults();

  /// Creates a new pending scan session with the provided folders.
  /// Returns the created session (used by Scanner module to begin scanning).
  Future<ScanSessionModel> createSession(List<ScanFolderModel> folders);
}
