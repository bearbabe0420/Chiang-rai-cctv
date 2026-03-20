import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

extension BuildContextI18n on BuildContext {
  String tr(
    String key, {
    Map<String, String>? params,
    String? fallback,
  }) {
    final translated = FlutterI18n.translate(this, key, translationParams: params);
    if (translated.isEmpty || translated == key) {
      return fallback ?? key;
    }
    return translated;
  }
}
