import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'results_screen_cubit.dart';
import 'results_screen_state.dart';
import 'widgets/compare_body.dart';
import 'widgets/duplicates_list_body.dart';

/// ResultsScreen — the Duplicates destination: the list of duplicate groups,
/// or the compare view when a group is open.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResultsScreenCubit, ResultsScreenState>(
      builder: (context, state) {
        final open = state.openGroup;
        if (open != null) return CompareBody(state: state, group: open);
        return DuplicatesListBody(state: state);
      },
    );
  }
}
