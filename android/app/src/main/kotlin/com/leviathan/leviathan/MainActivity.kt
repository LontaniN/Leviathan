package com.leviathan.leviathan

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Riceve il testo condiviso da altre app ("Condividi" → Leviathan).
 *
 * Il testo resta qui finché Dart non lo chiede con `takeShared`: all'avvio
 * a freddo Dart lo prende appena è pronto, con l'app già aperta riceve
 * `shared` e lo chiede subito. Ogni condivisione si consegna una volta sola.
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var pending: Map<String, String?>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // Ricreata dopo una rotazione o dopo che Android l'ha chiusa:
        // l'intent è quello vecchio, già consegnato.
        if (savedInstanceState == null) pending = sharedText(intent)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "takeShared" -> {
                        result.success(pending)
                        pending = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        pending = sharedText(intent) ?: return
        channel?.invokeMethod("shared", null)
    }

    /** Oggetto e testo di una condivisione `text/…`, o null se non lo è. */
    private fun sharedText(intent: Intent?): Map<String, String?>? {
        if (intent?.action != Intent.ACTION_SEND) return null
        if (intent.type?.startsWith("text/") != true) return null
        // Riaperta dalle app recenti: l'intent è quello della prima volta.
        if (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) return null
        val text = intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()
        val subject = intent.getCharSequenceExtra(Intent.EXTRA_SUBJECT)?.toString()
        if (text.isNullOrBlank() && subject.isNullOrBlank()) return null
        // Un'altra app può mandare testi enormi: ci si ferma prima.
        return mapOf(
            "text" to text?.take(MAX_TEXT),
            "subject" to subject?.take(MAX_SUBJECT),
        )
    }

    private companion object {
        const val CHANNEL = "leviathan/share"
        const val MAX_TEXT = 100_000
        const val MAX_SUBJECT = 500
    }
}
