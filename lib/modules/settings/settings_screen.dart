import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'settings_screen_cubit.dart';
import 'settings_screen_state.dart';
import 'widgets/storage_cache_section_widget.dart';

/// SettingsScreen — displays Storage & Cache section using a pre-provided
/// `SettingsScreenCubit` (injected by the route builder).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsScreenCubit, SettingsScreenState>(
      listener: (context, state) {
        if (state is SettingsScreenOpenFolderError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: BlocBuilder<SettingsScreenCubit, SettingsScreenState>(
        builder: (context, state) {
          final entries = state.entries;
          final copiedId = state is SettingsScreenPathCopied
              ? state.copiedEntryId
              : null;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: StorageCacheSectionWidget(
              entries: List.unmodifiable(entries),
              copiedEntryId: copiedId,
                onOpenFolder: (entry) =>
                  context.read<SettingsScreenCubit>().openFolder(entry),
                onCopyPath: (entry) =>
                  context.read<SettingsScreenCubit>().copyPath(entry),
            ),
          );
        },
      ),
    );
  }
}
