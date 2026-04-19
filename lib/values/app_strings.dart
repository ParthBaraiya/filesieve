/// AppStrings — all UI copy as static const String constants.
/// Verbatim values sourced from spec FR-009/FR-010 and US1–US3.
class AppStrings {
  AppStrings._();

  static const String appName = 'FileSieve';

  // Home screen headline / subtitle
  static const String homeHeadline = 'Clean up your workspace.';
  static const String homeSubtitle =
      'FileSieve uses clinical-grade checksum algorithms to find identical files '
      'across your local and network drives.';

  // Feature cards
  static const String featureCard1Title = 'High-Speed Analysis';
  static const String featureCard1Body =
      'Optimized multi-threaded scanning processes millions of files in seconds '
      'without system lag.';

  static const String featureCard2Title = 'Byte-Perfect Accuracy';
  static const String featureCard2Body =
      "We don't just look at names. We compare the DNA of your files to ensure "
      '100% accurate identification.';

  // Step-flow labels and descriptions
  static const String stepFlowStep1Number = '01';
  static const String stepFlowStep1Label = 'Step One';
  static const String stepFlowStep1Desc = 'Select source directories';

  static const String stepFlowStep2Number = '02';
  static const String stepFlowStep2Label = 'Step Two';
  static const String stepFlowStep2Desc = 'Configure file exclusions';

  static const String stepFlowStep3Number = '03';
  static const String stepFlowStep3Label = 'Step Three';
  static const String stepFlowStep3Desc = 'Review and resolve duplicates';

  // Footer
  static const String scanningEngineVersion = 'v2.4-STABLE';

  // Drop zone
  static const String dropZonePrompt = 'Drop folders here to sieve';
  static const String dropZoneSecondary = 'or click to browse your file system';
  static const String dropZoneFormats = 'SUPPORTS: APFS, NTFS, EXFAT';

  // Rejection messages
  static const String dropRejectionNotFolder =
      'Only folders can be dropped here.';
  static const String dropRejectionNoAccess =
      'This folder could not be read. Check your permissions.';

  // Scan configuration
  static const String scanConfigTitle = 'Scan Configuration';
  static const String scanConfigSubtitle =
      'Define target directories and file parameters...';
  static const String deleteSelected = 'Delete Selected';
  static const String startScan = 'Start Scan';
  static const String activeScanTargets = 'Active Scan Targets';
  static const String foldersQueued = 'Folders queued for processing';
  static const String addNewTarget = 'Add New Target';
  static const String scanSettings = 'Scan Settings';
  static const String includeFileTypes = 'Include File Types';
  static const String fileSizeThreshold = 'File Size Threshold';
  static const String deepMetadataAnalysis = 'Deep Metadata Analysis';
  static const String deepMetadataDesc =
      'Analyze headers and file signatures';
  static const String includeSubdirectories = 'Include Subdirectories';
  static const String includeSubdirectoriesDesc =
      'Recursive scan for all nested paths';
  static const String executeScanSequence = 'Execute Scan Sequence';
  static const String estimatedScanTime = 'Estimated Scan Time';
  static const String images = 'Images';
  static const String videos = 'Videos';
  static const String documents = 'Documents';
  static const String archives = 'Archives';

  // Scan progress UI
  static const String scanProgressAnalysing = 'Analysing files…';
  static const String scanProgressCancelButton = 'Cancel Scan';
  static const String scanLiveFeedTitle = 'Recently Found Duplicates';
  static const String scanLiveFeedLiveLabel = 'LIVE';
  static const String scanLiveFeedEmpty = 'No duplicates found yet…';
  static const String scanStatsFiles = 'Files Analysed';
  static const String scanStatsDuplicates = 'Duplicates Found';
  static const String scanStatsSavings = 'Potential Savings';
}

/// stepFlowData — Dart 3 record list for the three-step workflow guide.
/// Used by StepFlowWidget (T026).
const List<({String number, String label, String desc})> stepFlowData = [
  (
    number: AppStrings.stepFlowStep1Number,
    label: AppStrings.stepFlowStep1Label,
    desc: AppStrings.stepFlowStep1Desc,
  ),
  (
    number: AppStrings.stepFlowStep2Number,
    label: AppStrings.stepFlowStep2Label,
    desc: AppStrings.stepFlowStep2Desc,
  ),
  (
    number: AppStrings.stepFlowStep3Number,
    label: AppStrings.stepFlowStep3Label,
    desc: AppStrings.stepFlowStep3Desc,
  ),
];
