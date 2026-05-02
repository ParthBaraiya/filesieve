import 'package:filesieve/modules/home/home_screen_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/duplicate_group_model.dart';
import '../home_screen_state.dart';

class DuplicateFilePreviewWidget extends StatefulWidget {
  const DuplicateFilePreviewWidget({super.key, required this.state});

  final HomeScreenFilePreview state;

  @override
  State<DuplicateFilePreviewWidget> createState() =>
      _DuplicateFilePreviewWidgetState();
}

class _DuplicateFilePreviewWidgetState
    extends State<DuplicateFilePreviewWidget> {
  @override
  Widget build(BuildContext context) {
    // TODO(parth): show file preview screen.
    final group = widget.state.currentFile;

    return Column(
      crossAxisAlignment: .start,
      children: [
        TextButton(
          onPressed: () => context.read<HomeScreenCubit>().backToPreview(),
          child: Row(
            mainAxisSize: .min,
            children: [Icon(Icons.chevron_left), Text('Duplicates')],
          ),
        ),
        FutureBuilder(
          future: group.largestFile,
          builder: (_, snapshot) {
            return Text(snapshot.data?.name ?? 'unknown');
          },
        ),
      ],
    );
  }
}
