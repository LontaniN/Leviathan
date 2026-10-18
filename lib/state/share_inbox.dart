import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../model/shared_text.dart';

/// Le condivisioni arrivate da altre app e non ancora messe in una bozza.
///
/// Su Android le consegna `MainActivity` (canale `leviathan/share`); la home
/// le prende una alla volta con [take] appena può mostrarle. Restano qui
/// anche mentre l'app è ancora alla scelta della lingua o all'onboarding.
class ShareInbox extends ChangeNotifier {
  final _queue = <SharedText>[];

  bool get hasPending => _queue.isNotEmpty;

  void receive(SharedText share) {
    _queue.add(share);
    notifyListeners();
  }

  /// La prima condivisione in attesa, tolta dalla coda; null se non ce ne
  /// sono.
  SharedText? take() => _queue.isEmpty ? null : _queue.removeAt(0);

  static const _channel = MethodChannel('leviathan/share');

  /// Collega la coda ad Android: prende la condivisione con cui l'app è
  /// stata aperta e ascolta quelle che arrivano con l'app già aperta.
  Future<void> listenToPlatform() async {
    if (!Platform.isAndroid) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'shared') await _fetch();
    });
    await _fetch();
  }

  Future<void> _fetch() async {
    try {
      final raw = await _channel.invokeMapMethod<String, String?>('takeShared');
      if (raw == null) return;
      receive((subject: raw['subject'] ?? '', text: raw['text'] ?? ''));
    } on PlatformException {
      // Nessuna condivisione leggibile: l'app si apre normalmente.
    } on MissingPluginException {
      // Lato Android senza il canale (es. una build vecchia): come sopra.
    }
  }
}
