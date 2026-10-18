# Leviathan

App Flutter (second brain) per Android, testata su un Pixel 9a. Codice e
commenti in italiano.

## Lingue

- Tutto ciò che si pubblica è in inglese: messaggi di commit, titoli e
  descrizioni delle PR, note delle release, README.
- L'interfaccia è in inglese e in italiano. Nessun testo visibile scritto nei
  widget: ogni stringa va in `lib/l10n/app_en.arb` (il modello, con i
  segnaposto descritti) e in `lib/l10n/app_it.arb`, e si legge con
  `context.l10n.<chiave>`. Le classi in `lib/l10n/app_localizations*.dart`
  sono generate da `flutter gen-l10n`: non modificarle a mano.
- Plurali con la sintassi ICU (`{count, plural, =1{…} other{…}}`).
- Il modello non conosce la lingua: date e titoli ricevono gli
  `AppLocalizations` o il testo già tradotto (es. `displayTitle(l.untitled)`).
- I widget test girano in italiano (`_app` in `test/widget_test.dart`); per
  tornare indietro usare `find.byType(BackButton)`, non `pageBack()`, che
  cerca il tooltip inglese.

## Stile della UI

Tutti i valori visivi stanno in `lib/ui/theme.dart`; non introdurre colori,
dimensioni di testo, spaziature o raggi sparsi nei widget.

- Colori: `LeviathanPalette`, letta con `context.palette`. Predefinita
  Inchiostro (nero pieno, accento bianco), con le varianti scure Seppia e
  Lavagna; le altre palette si scelgono dalle impostazioni.
- Spaziature: `LeviathanSpacing` (scala da 4: xs 4, sm 8, md 12, lg 16,
  xl 24, xxl 32).
- Raggi: `LeviathanRadii`.
- Testo: `LeviathanText` (`title`, `body`, `meta`, `tiny`) o il `TextTheme`
  di Material.

Se serve un valore nuovo, aggiungilo a `theme.dart` invece di scriverlo nel
widget. Il codice esistente ha ancora numeri sparsi: quando tocchi una
schermata, portala sui token.

Ogni schermata deve gestire gli stati vuoto, caricamento ed errore.

## Ciclo di lavoro sulla UI

L'utente tiene `flutter run` aperto e preme `r` per l'hot reload; il giudizio
estetico è suo.

1. Modifica il codice e lancia `flutter analyze`.
2. Chiedi all'utente di fare hot reload e di portare l'app sulla schermata
   giusta.
3. Lancia `bash tool/screenshot.sh [nome]` (da Git Bash, non PowerShell):
   salva il PNG in `.screenshots/` e ne stampa il percorso. Aprilo con Read e
   controlla il risultato prima di dichiarare finito il lavoro.
4. Raccogli il feedback dell'utente e ripeti.

Lo script cattura solo se Leviathan è in primo piano, così non finiscono
nelle immagini altre app o dati personali. Se si rifiuta (schermo spento,
dispositivo assente, un'altra app aperta), chiedi all'utente di sistemare e
riprova; non aggirare il controllo.
