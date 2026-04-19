import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

final serviceLocator = GetIt.instance;

extension BuildContextExtension on BuildContext {
    ThemeData get theme => Theme.of(this);
}