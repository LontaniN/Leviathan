# Piano di sviluppo

Funzionalità scelte a partire da come viene usata l'app: idee, appunti di
studio e cose da fare; cattura scrivendo nell'app o condividendo da altre app;
si ritrova cercando; collegamenti solo tramite tag; solo telefono più backup.

Escluse di proposito: AI, note vocali e OCR, `[[link]]` e backlink,
sincronizzazione col PC, flashcard e riaffioramento delle note, template.

Ordine consigliato: 1 → 3 → 2 → 4/5.

## Priorità alta

1. **Note di tipo task.** *(fatto)* Un interruttore nell'editor rende la
   nota un task (`type: task`, `done`, `done_at` nel frontmatter); tag e
   fonte restano. Casella da spuntare nella lista, task fatti attenuati e
   barrati, filtro `stato:aperto` / `stato:fatto` / `stato:task` nella
   ricerca, task fatti sbiaditi nel grafo. Schermata Task (icona accanto alle
   fonti) con i task raggruppati per tag o per fonte.
2. **Ricevere dal tasto Condividi.** Testo condiviso da un'altra app → editor
   precompilato, pronto per tag e fonte; scelta del workspace se ce n'è più
   d'uno (`receive_sharing_intent`).
3. **Markdown con anteprima.** *(fatto)* Corpo formattato nella lettura (titoli,
   grassetto, elenchi, citazioni, codice), barra di formattazione sopra la
   tastiera, checklist `- [ ]` spuntabili.
4. **Backup ed esportazione.** Zip del workspace da condividere, importazione
   da zip, backup automatico periodico in una cartella scelta.
5. **Cestino e annulla.** Le note eliminate finiscono già in
   `.leviathan/trash`; mancano l'avviso con "Annulla", una schermata per
   recuperarle e lo svuotamento dopo 30 giorni.

## Priorità media

6. **Ricerca potenziata.** Filtri per data, ordinamento (pertinenza, data,
   titolo), ricerche salvate, cronologia delle ricerche.
7. **Gestione dei tag.** Elenco con conteggio, rinomina e unione su tutte le
   note, colore scelto a mano.
8. **Scorciatoie di cattura.** "Nuova nota" / "Nuovo task" tenendo premuta
   l'icona, tile nelle Impostazioni rapide, poi un widget per la home.
9. **Note fissate e archivio.** In cima le note usate spesso; archivio per
   nascondere senza eliminare (utile per i task fatti).
10. **Salvataggio automatico delle bozze.** Il testo sopravvive se Android
    chiude l'app.

## Da valutare

11. Cronologia delle versioni di una nota.
12. Blocco con impronta digitale (app o singolo workspace).
13. Statistiche leggere: note per tag, task completati nella settimana.
