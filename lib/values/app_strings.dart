/// AppStrings — all UI copy as static const String constants.
/// Verbatim values sourced from spec FR-009/FR-010 and US1–US3.
class AppStrings {
  AppStrings._();

  static const String appName = 'FileSieve';

  // Home screen headline / subtitle
  static const String homeHeadline = 'Clean up your workspace.';
  static const String homeSubtitle =
      'FileSieve uses checksum-based detection to find exact duplicate files '
      'across your drives \u2014 fast, accurate, and completely offline.';

  // Feature cards
  static const String featureCard1Title = 'High-Speed Analysis';
  static const String featureCard1Body =
      'Multi-threaded scanning processes thousands of files per second using '
      'parallel hash computation.';

  static const String featureCard2Title = 'Byte-Perfect Accuracy';
  static const String featureCard2Body =
      'SHA-256 checksums guarantee zero false positives. Every flagged '
      'duplicate is an exact byte-for-byte match.';

  // Step-flow labels and descriptions
  static const String stepFlowStep1Label = 'Add Folders';
  static const String stepFlowStep1Desc =
      'Select the source directories you want to deduplicate.';

  static const String stepFlowStep2Label = 'Set Filters';
  static const String stepFlowStep2Desc =
      'Configure file type exclusions and minimum file size.';

  static const String stepFlowStep3Label = 'Review \u0026 Resolve';
  static const String stepFlowStep3Desc =
      'Inspect flagged duplicates and choose what to delete.';

  // Header context label
  static const String headerContextLabel = 'Initialize New Scan';

  // Drop zone
  static const String dropZonePrompt = 'Drop folders here to sieve';

  // Rejection messages
  static const String dropRejectionNotFolder =
      'Only folders can be dropped here.';
  static const String dropRejectionNoAccess =
      'This folder could not be read. Check your permissions.';
}

/// stepFlowData — Dart 3 record list for the three-step workflow guide.
/// Used by StepFlowWidget (T026).
const List<({String number, String label, String desc})> stepFlowData = [
  (
    number: '01',
    label: AppStrings.stepFlowStep1Label,
    desc: AppStrings.stepFlowStep1Desc,
  ),
  (
    number: '02',
    label: AppStrings.stepFlowStep2Label,
    desc: AppStrings.stepFlowStep2Desc,
  ),
  (
    number: '03',
    label: AppStrings.stepFlowStep3Label,
    desc: AppStrings.stepFlowStep3Desc,
  ),
];
