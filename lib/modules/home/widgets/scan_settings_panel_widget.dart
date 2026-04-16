import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../values/app_strings.dart';

class ScanSettingsPanelWidget extends StatefulWidget {
  const ScanSettingsPanelWidget({super.key});

  @override
  State<ScanSettingsPanelWidget> createState() =>
      _ScanSettingsPanelWidgetState();
}

class _ScanSettingsPanelWidgetState extends State<ScanSettingsPanelWidget> {
  bool _imagesChecked = true;
  bool _videosChecked = true;
  bool _documentsChecked = true;
  bool _archivesChecked = false;

  double _sizeThreshold = 0;

  bool _deepMetadata = false;
  bool _includeSubdirectories = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest.withAlpha(200),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colorScheme.onSurface.withAlpha(25)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.tune,
                  size: 18.r,
                  color: colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 8.w),
                Text(
                  AppStrings.scanSettings.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Include File Types
            Text(
              AppStrings.includeFileTypes,
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: _FileTypeCheckbox(
                    label: AppStrings.images,
                    value: _imagesChecked,
                    highlighted: _imagesChecked,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    onChanged: (v) =>
                        setState(() => _imagesChecked = v ?? false),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _FileTypeCheckbox(
                    label: AppStrings.videos,
                    value: _videosChecked,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    onChanged: (v) =>
                        setState(() => _videosChecked = v ?? false),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: _FileTypeCheckbox(
                    label: AppStrings.documents,
                    value: _documentsChecked,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    onChanged: (v) =>
                        setState(() => _documentsChecked = v ?? false),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _FileTypeCheckbox(
                    label: AppStrings.archives,
                    value: _archivesChecked,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    onChanged: (v) =>
                        setState(() => _archivesChecked = v ?? false),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // File Size Threshold
            Text(
              AppStrings.fileSizeThreshold,
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_sizeThreshold.round()} MB',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '1000 MB',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Slider(
              value: _sizeThreshold,
              min: 0,
              max: 1000,
              divisions: 100,
              onChanged: (v) => setState(() => _sizeThreshold = v),
            ),
            SizedBox(height: 20.h),

            // Deep Metadata Analysis
            _ToggleRow(
              title: AppStrings.deepMetadataAnalysis,
              description: AppStrings.deepMetadataDesc,
              value: _deepMetadata,
              colorScheme: colorScheme,
              textTheme: textTheme,
              onChanged: (v) => setState(() => _deepMetadata = v),
            ),
            SizedBox(height: 12.h),

            // Include Subdirectories
            _ToggleRow(
              title: AppStrings.includeSubdirectories,
              description: AppStrings.includeSubdirectoriesDesc,
              value: _includeSubdirectories,
              colorScheme: colorScheme,
              textTheme: textTheme,
              onChanged: (v) => setState(() => _includeSubdirectories = v),
            ),
            SizedBox(height: 24.h),

            // Execute Scan Sequence button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  AppStrings.executeScanSequence.toUpperCase(),
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileTypeCheckbox extends StatelessWidget {
  const _FileTypeCheckbox({
    required this.label,
    required this.value,
    required this.colorScheme,
    required this.textTheme,
    required this.onChanged,
    this.highlighted = false,
  });

  final String label;
  final bool value;
  final bool highlighted;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: highlighted
            ? colorScheme.primaryContainer.withAlpha(80)
            : colorScheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: highlighted
              ? colorScheme.primary.withAlpha(60)
              : colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.r),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
          child: Row(
            children: [
              SizedBox(
                width: 20.r,
                height: 20.r,
                child: Checkbox(
                  value: value,
                  onChanged: onChanged,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.description,
    required this.value,
    required this.colorScheme,
    required this.textTheme,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool value;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                description,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
