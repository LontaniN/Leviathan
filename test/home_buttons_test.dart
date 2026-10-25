import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:leviathan/model/home_buttons.dart';
import 'package:leviathan/state/settings.dart';

void main() {
  test('senza scelta salvata ci sono tutti, in ordine', () {
    expect(HomeButton.parse(null), HomeButton.values);
    expect(HomeButton.parse('rotto'), HomeButton.values);
  });

  test('la scelta salvata tiene ordine, salta sconosciuti e doppioni', () {
    expect(HomeButton.parse(['diary', 'futuro', 'pinned', 'diary']), [
      HomeButton.diary,
      HomeButton.pinned,
    ]);
    // Una lista vuota è una scelta: nessun pulsante oltre alle impostazioni.
    expect(HomeButton.parse([]), isEmpty);
  });

  test('nelle impostazioni i nascosti vengono dopo i visibili', () {
    expect(HomeButton.withHidden([HomeButton.diary, HomeButton.graph]), [
      HomeButton.diary,
      HomeButton.graph,
      HomeButton.pinned,
      HomeButton.lists,
      HomeButton.calendar,
      HomeButton.taskManager,
    ]);
  });

  test('la scelta si scrive nelle preferenze, solo se cambiata', () {
    final dir = Directory.systemTemp.createTempSync('leviathan_buttons');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/preferences.json');
    final settings = Settings(file: file);

    settings.setHomeButtons([HomeButton.taskManager, HomeButton.diary]);
    final json = jsonDecode(file.readAsStringSync()) as Map;
    expect(json['homeButtons'], ['taskManager', 'diary']);
    expect(HomeButton.parse(json['homeButtons']), settings.homeButtons);

    settings.setHomeButtons(HomeButton.defaults);
    expect(
      (jsonDecode(file.readAsStringSync()) as Map).containsKey('homeButtons'),
      isFalse,
    );
  });
}
