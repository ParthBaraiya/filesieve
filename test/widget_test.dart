import 'package:filesieve/main.dart';
import 'package:filesieve/models/app_settings_model.dart';
import 'package:filesieve/modules/app_settings/app_settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/results_fakes.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AppSettingsCubit(
          repository: MemorySettings(),
          initial: const AppSettingsModel(),
        ),
        child: const DedupeApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
