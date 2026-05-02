import 'dart:io';

import 'package:flutter/foundation.dart';

String formatFileSize(int bytes, {int decimalPlaces = 1}) {
  if (bytes < 0) {
    throw ArgumentError('File size cannot be negative');
  }

  final kilos = Platform.isWindows ? 1024 : 1000;

  final kb = kilos;
  final mb = kb * kilos;
  final gb = mb * kilos;

  if (bytes < kb) {
    return '$bytes b';
  } else if (bytes < mb) {
    return '${(bytes / kb).toStringAsFixed(decimalPlaces)} KB';
  } else if (bytes < gb) {
    return '${(bytes / mb).toStringAsFixed(decimalPlaces)} MB';
  } else {
    return '${(bytes / gb).toStringAsFixed(decimalPlaces)} GB';
  }
}

Future<T?> safeRun<T>(
  AsyncValueGetter<T> callback, {
  AsyncValueSetter<dynamic>? onError,
}) async {
  try {
    return await callback();
  } catch (e) {
    onError?.call(e);
  }

  return null;
}
