import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulang/l10n/app_localizations.dart';
import 'package:pulang/l10n/locale_resolver.dart';

Map<String, dynamic> _arb(String code) =>
    jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _keys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

void main() {
  test('ARB id dan en punya key yang sama', () {
    expect(_keys(_arb('en')), _keys(_arb('id')));
  });

  group('resolveLanguageCode', () {
    test('system + perangkat fr -> id', () {
      expect(resolveLanguageCode('system', const Locale('fr')), 'id');
    });
    test('system + perangkat en_US -> en', () {
      expect(resolveLanguageCode('system', const Locale('en', 'US')), 'en');
    });
    test('override en menang atas perangkat id', () {
      expect(resolveLanguageCode('en', const Locale('id')), 'en');
    });
  });

  test('teks notifikasi English memakai transliterasi', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final name = l10n.prayerName('subuh');
    expect(name, 'Fajr');
    expect(l10n.notificationPrayerTitle(name), 'Fajr time');
  });
}
