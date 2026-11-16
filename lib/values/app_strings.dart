/// AppStrings — all UI copy as static const String constants.
/// Verbatim values sourced from spec FR-009/FR-010 and US1–US3.
class AppStrings {
  AppStrings._();

  static const String appName = 'Dedupe';

  // Home screen headline / subtitle
  static const String homeHeadline = 'Clean up your workspace.';
  static const String homeSubtitle =
      'Dedupe uses clinical-grade checksum algorithms to find identical files '
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
  
  // Scan setup (onboarding)
  static const String setupStepAddFolders = 'Add folders';
  static const String setupStepScan = 'Scan';
  static const String setupStepReview = 'Review';
  static const String setupHeadline = 'Where should we look for duplicates?';
  static const String setupSubtitle =
      'Add every folder you want checked. Files are compared byte for byte, '
      'so only 100% identical copies are reported.';
  static const String setupDropTitle = 'Drop folders here';
  static const String setupDropSubtitle =
      'or pick them from your computer. External drives work too.';
  static const String setupChooseFolders = 'Choose folders…';
  static const String setupSuggested = 'Suggested';
  static const String setupFoldersToScan = 'Folders to scan';
  static const String setupNoFolders =
      'No folders yet. Add at least one to start scanning.';
  static const String setupIncludeSubfolders = 'Include subfolders';
  static const String setupSkipHidden = 'Skip hidden and system files';
  static const String setupSettingsHint =
      'You can change this list any time in Settings.';
  static const String setupStartScan = 'Start scan';
  static const String setupRemoveFolder = 'Remove folder';

  // Scan progress screen
  static const String scanComplete = 'Scan complete';
  static const String scanCancel = 'Cancel';
  static const String scanReviewDuplicates = 'Review duplicates';
  static const String scanUsuallyTakes = 'This usually takes a few minutes';
  static const String scanAllChecked = 'All files checked';
  static const String scanFinished = 'Finished';
  static const String scanFilesTitle = 'Scanned files';
  static const String setupCountingFiles = 'Counting…';
  static const String scanStageListFiles = 'List files';
  static const String scanStageMatchBySize = 'Match by size';
  static const String scanStageVerify = 'Verify contents';
  static const String scanStageWaiting = 'Waiting';
  static const String scanStageDone = 'Done';
  static const String scanStatGroups = 'Duplicate groups';
  static const String scanStatCopies = 'Extra copies';
  static const String scanStatSpace = 'Space to reclaim';
  static const String scanFailedBack = 'Back to folders';

  // Duplicates list
  static const String dupTitle = 'Duplicates';
  static const String dupTidy = 'Everything is tidy';
  static const String dupColFile = 'File';
  static const String dupColCopies = 'Copies';
  static const String dupColSizeEach = 'Size each';
  static const String dupColReclaimable = 'Reclaimable';
  static const String dupFilterAll = 'All';
  static const String dupFilterEmpty = 'No duplicates of this type left.';
  static const String dupCleanTitle = 'No duplicates left';
  static const String dupCleanNone = 'No identical files were found in your folders.';
  static const String dupScanAgain = 'Scan again';
  static const String dupNotScannedTitle = 'Nothing scanned yet';
  static const String dupNotScannedBody =
      'Add folders and run a scan to find identical files.';
  static const String dupGoToScan = 'Go to scan';

  // Compare
  static const String cmpBack = 'All duplicates';
  static const String cmpPrevious = 'Previous group';
  static const String cmpNext = 'Next group';
  static const String cmpIdentical = '100% identical';
  static const String cmpSorted = 'Sorted. One copy kept, the duplicates are gone.';
  static const String cmpBackToList = 'Back to list';
  static const String cmpType = 'Type';
  static const String cmpSize = 'Size';
  static const String cmpMatch = 'Match';
  static const String cmpByteForByte = 'Byte for byte';
  static const String cmpOldest = 'Oldest';
  static const String cmpKeeping = 'Keeping';
  static const String cmpKeepThis = 'Keep this one';
  static const String cmpRemove = 'Remove';
  static const String cmpShowInFolder = 'Show in folder';
  static const String cmpRestore = 'Restore';
  static const String cmpMovedToTrash = 'Moved to Trash';
  static const String cmpDeleted = 'Permanently deleted';
  static const String cmpSkip = 'Skip';

  // Confirm dialog and toast
  static const String dlgRemoveAllTitle = 'Remove all identical copies?';
  static const String dlgKeepRuleLegend = 'In each group, keep the copy that is';
  static const String dlgTrashTitle = 'Move to Trash?';
  static const String dlgDeleteTitle = 'Delete permanently?';
  static const String dlgTrashNote = 'Files go to the Trash, so you can restore them.';
  static const String dlgDeleteNote =
      'Files are deleted permanently and can’t be restored.';
  static const String dlgChange = 'Change';
  static const String dlgCancel = 'Cancel';
  static const String dlgMoveToTrash = 'Move to Trash';
  static const String dlgDeletePermanently = 'Delete permanently';
  static const String toastUndo = 'Undo';

  // Settings
  static const String settingsTitle = 'Settings';
  static const String settingsRemovalTitle = 'When removing files';
  static const String settingsTrashLabel = 'Move to Trash';
  static const String settingsTrashSub =
      'Recommended. You can restore files until the Trash is emptied.';
  static const String settingsPermanentLabel = 'Delete permanently';
  static const String settingsPermanentSub =
      'Frees space right away. Files can’t be recovered.';
  static const String settingsConfirmTitle = 'Confirm before every removal';
  static const String settingsConfirmSub = 'Permanent deletes always ask first.';
  static const String settingsFoldersTitle = 'Watched folders';
  static const String settingsFoldersSub = 'The folders that are scanned.';
  static const String settingsAddFolder = 'Add folder';
  static const String settingsStopWatching = 'Stop watching folder';
  static const String settingsNoFolders = 'No folders yet.';
  static const String settingsAppearanceTitle = 'Appearance';
  static const String settingsResetTitle = 'Start over';
  static const String settingsResetSub =
      'Clear the folder list and results, and restore default settings.';
  static const String settingsResetButton = 'Reset app';

  // Settings — Storage & Cache (Phase 1 constants)
  static const String settingsSectionStorageTitle = 'Storage & Cache';
  static const String settingsCacheEntryObjectBoxLabel = 'ObjectBox Store';
  static const String settingsCacheEntryNotCreated = 'Not yet created';
  static const String settingsCacheActionOpenFolder = 'Open Folder';
  static const String settingsCacheActionCopyPath = 'Copy Path';
  static const String settingsCacheCopiedConfirmation = 'Path copied';
  static const String settingsCacheOpenFolderError = 'Unable to open folder';
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
