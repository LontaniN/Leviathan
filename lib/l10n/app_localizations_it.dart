// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get cancel => 'Annulla';

  @override
  String get undo => 'Annulla';

  @override
  String get delete => 'Elimina';

  @override
  String get rename => 'Rinomina';

  @override
  String get create => 'Crea';

  @override
  String get retry => 'Riprova';

  @override
  String get apply => 'Applica';

  @override
  String get search => 'Cerca';

  @override
  String get closeSearch => 'Chiudi la ricerca';

  @override
  String get clear => 'Svuota';

  @override
  String get edit => 'Modifica';

  @override
  String get more => 'Altro';

  @override
  String get untitled => 'Senza titolo';

  @override
  String errorMessage(String message) {
    return 'Errore: $message';
  }

  @override
  String noteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count note',
      one: '1 nota',
    );
    return '$_temp0';
  }

  @override
  String openCount(int count) {
    return '$count da fare';
  }

  @override
  String get languageTitle => 'Scegli la lingua';

  @override
  String get languageBody => 'Potrai cambiarla in seguito dalle impostazioni.';

  @override
  String get language => 'Lingua';

  @override
  String get continueButton => 'Continua';

  @override
  String get onboardingTagline => 'Affronta il mondo esterno tramite byte.';

  @override
  String get onboardingBody =>
      'Dai un nome al tuo primo workspace. Ogni workspace raccoglie le sue note: puoi crearne altri in qualsiasi momento.';

  @override
  String get createWorkspace => 'Crea workspace';

  @override
  String get workspaceNameHint => 'es. Lavoro, Fotografia, Studio…';

  @override
  String get workspaceNameEmpty => 'Inserisci un nome';

  @override
  String workspaceNameTooLong(int max) {
    return 'Nome troppo lungo (max $max caratteri)';
  }

  @override
  String get workspaceNameLeadingDot => 'Il nome non può iniziare con un punto';

  @override
  String get workspaceNameTrailingDot => 'Il nome non può finire con un punto';

  @override
  String workspaceNameInvalidChars(String chars) {
    return 'Caratteri non ammessi: $chars';
  }

  @override
  String get workspaceNameTaken => 'Esiste già un workspace con questo nome';

  @override
  String get permissionTitle => 'Accesso ai file';

  @override
  String get permissionBody =>
      'Le note vengono salvate come file nella cartella Documents/LeviathanNotes del telefono, così restano tue anche se disinstalli l\'app. Per scriverci, Android chiede il permesso \"Accesso a tutti i file\".';

  @override
  String get permissionGrant => 'Concedi accesso';

  @override
  String get pinned => 'Fissate';

  @override
  String get graph => 'Grafo';

  @override
  String get tasksAndNotes => 'Task e note';

  @override
  String get calendar => 'Calendario';

  @override
  String get settings => 'Impostazioni';

  @override
  String get searchNotes => 'Cerca nelle note';

  @override
  String loadError(String message) {
    return 'Impossibile leggere le note: $message';
  }

  @override
  String allNotes(int count) {
    return 'Tutte le note ($count)';
  }

  @override
  String get recent => 'Recenti';

  @override
  String get noNotesYet => 'Nessuna nota. Quelle che salvi compaiono qui.';

  @override
  String get workspace => 'Workspace';

  @override
  String get renameWorkspace => 'Rinomina workspace';

  @override
  String get deleteWorkspace => 'Elimina workspace';

  @override
  String get newWorkspace => 'Nuovo workspace';

  @override
  String deleteWorkspaceTitle(String name) {
    return 'Eliminare «$name»?';
  }

  @override
  String get deleteWorkspaceBody =>
      'Il workspace, con le sue note e il suo cestino, viene spostato in .leviathan/deleted, non cancellato.';

  @override
  String get deleteWorkspaceLast =>
      'È l\'unico workspace: dovrai crearne uno nuovo.';

  @override
  String workspaceDeleted(String name) {
    return '«$name» spostato in .leviathan/deleted';
  }

  @override
  String cannotDelete(String message) {
    return 'Impossibile eliminare: $message';
  }

  @override
  String cannotRename(String message) {
    return 'Impossibile rinominare: $message';
  }

  @override
  String get today => 'Oggi';

  @override
  String get yesterday => 'Ieri';

  @override
  String get thisWeek => 'Questa settimana';

  @override
  String movedToTrash(String title) {
    return '«$title» spostata nel cestino';
  }

  @override
  String get pinToTop => 'Fissa in cima';

  @override
  String get unpinFromTop => 'Stacca dalla cima';

  @override
  String get markDone => 'Segna come fatto';

  @override
  String get markUndone => 'Segna da fare';

  @override
  String get moveToTrash => 'Sposta nel cestino';

  @override
  String unpinned(String title) {
    return '«$title» staccata dalla cima';
  }

  @override
  String pinnedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count note fissate',
      one: '1 nota fissata',
    );
    return '$_temp0';
  }

  @override
  String get pinnedEmpty =>
      'Nessuna nota fissata.\nTieni premuta una nota nelle recenti, oppure tocca la puntina in una nota o negli elenchi di Task e note.';

  @override
  String get periodEmpty => 'Nessuna nota in questo periodo.';

  @override
  String periodNoMatch(String query) {
    return 'Nessuna nota di questo periodo contiene \"$query\".';
  }

  @override
  String get sampleDataShort => 'dati di prova';

  @override
  String get textCopied => 'Testo copiato';

  @override
  String get copyText => 'Copia il testo';

  @override
  String get convertToTask => 'Converti in task';

  @override
  String get convertToNote => 'Converti in nota';

  @override
  String editedOn(String date) {
    return 'modificata $date';
  }

  @override
  String wordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count parole',
      one: '1 parola',
    );
    return '$_temp0';
  }

  @override
  String get noText => 'Nessun testo.';

  @override
  String get taskToDo => 'Da fare';

  @override
  String get taskDone => 'Fatto';

  @override
  String taskDoneOn(String date) {
    return 'Fatto il $date';
  }

  @override
  String get editNote => 'Modifica nota';

  @override
  String get saveChanges => 'Salva modifiche';

  @override
  String get saveNote => 'Salva nota';

  @override
  String get saveTask => 'Salva task';

  @override
  String get noteDateToday => 'Data: oggi';

  @override
  String noteDateOn(String date) {
    return 'Data: $date';
  }

  @override
  String get noteDateTitle => 'Quando è stata scritta?';

  @override
  String savedOnDate(String date) {
    return 'Salvata al $date';
  }

  @override
  String get writeSomething => 'Scrivi almeno un titolo o un testo';

  @override
  String get taskTitleHint => 'Cosa c\'è da fare?';

  @override
  String get titleHint => 'Titolo';

  @override
  String get bodyHint => 'Scrivi la nota…';

  @override
  String get kindNote => 'Nota';

  @override
  String get kindTask => 'Task';

  @override
  String get knowledge => 'Conoscenza';

  @override
  String get knowledgeTitleHint => 'Cosa sai?';

  @override
  String get formatBold => 'Grassetto';

  @override
  String get formatItalic => 'Corsivo';

  @override
  String get formatHeading => 'Titolo';

  @override
  String get formatBullets => 'Elenco puntato';

  @override
  String get formatNumbered => 'Elenco numerato';

  @override
  String get formatChecklist => 'Checklist';

  @override
  String get formatQuote => 'Citazione';

  @override
  String get formatCode => 'Codice';

  @override
  String get addTags => 'Aggiungi tag';

  @override
  String get addSources => 'Aggiungi fonti (es. persone)';

  @override
  String savedAs(String value) {
    return 'Verrà salvato come: $value';
  }

  @override
  String get sourceMarker => 'da:';

  @override
  String get statusMarker => 'stato:';

  @override
  String get searchFieldHint => 'Cerca, oppure tag: / da:';

  @override
  String get frequentTags => 'Tag frequenti';

  @override
  String get frequentSources => 'Fonti frequenti';

  @override
  String get searchFilters => 'Filtri di ricerca';

  @override
  String get filterTagHelp => 'note con un tag';

  @override
  String get filterSourceHelp => 'note da una fonte (persona)';

  @override
  String get filterStatusHelp => 'task da fare o fatti';

  @override
  String shortcut(String key) {
    return 'scorciatoia: $key';
  }

  @override
  String get searchExample =>
      'Testo e filtri si combinano: per esempio \"esposizione tag:fotografia da:Mario Rossi\" oppure \"stato:aperto tag:università\".';

  @override
  String get tags => 'Tag';

  @override
  String get sources => 'Fonti';

  @override
  String get taskStatus => 'Stato dei task';

  @override
  String get noMatchingTag => 'Nessun tag corrispondente';

  @override
  String get noMatchingSource => 'Nessuna fonte corrispondente';

  @override
  String get statusTypeHelp => 'Scrivi aperto, fatto o task';

  @override
  String get noNotesFound => 'Nessuna nota trovata';

  @override
  String resultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count risultati',
      one: '1 risultato',
    );
    return '$_temp0';
  }

  @override
  String get statusTask => 'task';

  @override
  String get statusOpen => 'aperto';

  @override
  String get statusDone => 'fatto';

  @override
  String get statusTaskHelp => 'tutti i task';

  @override
  String get statusOpenHelp => 'task da fare';

  @override
  String get statusDoneHelp => 'task eseguiti';

  @override
  String get byTag => 'Per tag';

  @override
  String get bySource => 'Per fonte';

  @override
  String get listsNoNotes => 'Nessuna nota ancora: scrivine una dalla home.';

  @override
  String get listsNoKnowledge =>
      'Nessuna nota di conoscenza ancora: segnane una con la lampadina nell\'editor.';

  @override
  String get listsNoTasks =>
      'Nessun task ancora: scrivine uno scegliendo \"Task\" nell\'editor.';

  @override
  String get noTag => 'Senza tag';

  @override
  String get noSource => 'Senza fonte';

  @override
  String doneCount(int count) {
    return '$count fatti';
  }

  @override
  String get allDone => 'fatti';

  @override
  String get whereUntagged => 'fra le note senza tag';

  @override
  String get whereTag => 'in questo tag';

  @override
  String get whereUnsourced => 'fra le note senza fonte';

  @override
  String get whereSource => 'in questa fonte';

  @override
  String get whereTasks => 'fra i task';

  @override
  String get whereNotes => 'fra le note';

  @override
  String get whereKnowledge => 'nella conoscenza';

  @override
  String searchWhere(String where) {
    return 'Cerca $where';
  }

  @override
  String noResultsWhere(String where) {
    return 'Nessun risultato $where.';
  }

  @override
  String get noNotesHere => 'Nessuna nota qui.';

  @override
  String get noTasksHere => 'Nessun task qui.';

  @override
  String get noKnowledgeHere => 'Nessuna nota di conoscenza qui.';

  @override
  String taskSummary(int total, int open) {
    return '$total task · $open da fare';
  }

  @override
  String openTaskCount(int count) {
    return '$count task da fare';
  }

  @override
  String doneTaskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count task fatti',
      one: '1 task fatto',
    );
    return '$_temp0';
  }

  @override
  String get noTasks => 'Nessun task.';

  @override
  String get noOpenTasks => 'Nessun task da fare.';

  @override
  String get noDoneTasks => 'Nessun task fatto.';

  @override
  String get filterAll => 'Tutte';

  @override
  String get filterOpen => 'Da fare';

  @override
  String get filterDone => 'Fatte';

  @override
  String get viewTasks => 'Task';

  @override
  String get viewNotes => 'Note';

  @override
  String get viewKnowledge => 'Conoscenza';

  @override
  String get searchCalendar => 'Cerca nel calendario';

  @override
  String get showRealNotes => 'Mostra le note vere';

  @override
  String get sampleData => 'Dati di prova';

  @override
  String get daily => 'Giornaliero';

  @override
  String get monthly => 'Mensile';

  @override
  String get sampleDataBanner => 'Dati di prova: non sono le tue note';

  @override
  String get calendarEmpty =>
      'Nessuna nota ancora: il calendario si riempie man mano che scrivi.';

  @override
  String get periodNoTags => 'Le note di questo periodo non hanno tag.';

  @override
  String timesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count volte',
      one: '1 volta',
    );
    return '$_temp0';
  }

  @override
  String showNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vedi le $count note',
      one: 'Vedi la nota',
    );
    return '$_temp0';
  }

  @override
  String get calendarNoMatch => 'Nessuna nota contiene queste parole.';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni',
      one: '1 giorno',
    );
    return '$_temp0';
  }

  @override
  String monthCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mesi',
      one: '1 mese',
    );
    return '$_temp0';
  }

  @override
  String notesIn(String notes, String where) {
    return '$notes in $where';
  }

  @override
  String linkCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count collegamenti',
      one: '1 collegamento',
    );
    return '$_temp0';
  }

  @override
  String get filter => 'Filtra';

  @override
  String get center => 'Centra';

  @override
  String get graphEmpty => 'Scrivi qualche nota per vedere il grafo';

  @override
  String linkedNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count note collegate',
      one: '1 nota collegata',
    );
    return '$_temp0';
  }

  @override
  String get noTags => 'Nessun tag';

  @override
  String get noSources => 'Nessuna fonte';

  @override
  String get clearFilters => 'Togli filtri';

  @override
  String get palette => 'Palette';

  @override
  String get dark => 'Scura';

  @override
  String get light => 'Chiara';

  @override
  String get paletteInchiostro => 'Inchiostro';

  @override
  String get paletteSeppia => 'Seppia';

  @override
  String get paletteLavagna => 'Lavagna';

  @override
  String get paletteGrafite => 'Grafite';

  @override
  String get paletteAbisso => 'Abisso';

  @override
  String get paletteBrace => 'Brace';

  @override
  String get paletteMuschio => 'Muschio';

  @override
  String get paletteAmetista => 'Ametista';

  @override
  String get paletteCarta => 'Carta';

  @override
  String tourWelcomeTitle(String workspace) {
    return '$workspace è pronto';
  }

  @override
  String get tourWelcomeBody =>
      'Facciamo un giro veloce delle funzioni principali? Sono sei passi.';

  @override
  String get tourStart => 'Inizia il tour';

  @override
  String get tourSkip => 'Salta';

  @override
  String get tourBack => 'Indietro';

  @override
  String get tourNext => 'Avanti';

  @override
  String get tourDone => 'Fine';

  @override
  String tourProgress(int current, int total) {
    return '$current di $total';
  }

  @override
  String get tourEditorTitle => 'Scrivi una nota';

  @override
  String get tourEditorBody =>
      'Dalle un titolo e scrivi il testo in Markdown. In alto scegli se è una nota o un task da spuntare.';

  @override
  String get tourTagsTitle => 'I tag collegano tutto';

  @override
  String get tourTagsBody =>
      'Aggiungine quanti vuoi: mentre scrivi compaiono quelli che usi già. Il primo tag dà il colore alla nota. Sotto, scrivi da dove viene l\'idea.';

  @override
  String get tourListTitle => 'Le tue note';

  @override
  String get tourListBody =>
      'Le ultime, dalla più recente. Tocca per leggere e modificare, tieni premuto per fissare, spuntare o eliminare. La freccia allarga l\'elenco.';

  @override
  String get tourSearchTitle => 'Trova tutto';

  @override
  String get tourSearchBody =>
      'Cerca in titoli, testo, tag e fonti. Scrivi # per filtrare per tag e @ per fonte.';

  @override
  String get tourTaskManagerTitle => 'Metti in ordine i task';

  @override
  String get tourTaskManagerBody =>
      'Il task manager divide i task aperti in Ora, Prossimo e Più avanti: la loro posizione è la loro priorità. Tieni premuto un task e trascinalo per spostarlo. I task nuovi aspettano in Da ordinare: rispondi a qualche \"Quale viene prima?\" per sistemarli. Quelli spuntati finiscono in Completati.';

  @override
  String get tourViewsTitle => 'Le altre viste';

  @override
  String get tourViewsBody =>
      'Le note fissate, il grafo delle note unite dai tag, gli elenchi di task e note, il calendario, il diario e le impostazioni, dove puoi rivedere questo tour.';

  @override
  String get guide => 'Guida';

  @override
  String get replayTour => 'Rivedi il tour';

  @override
  String get taskManager => 'Task manager';

  @override
  String get taskManagerOpenTab => 'Da fare';

  @override
  String get taskManagerDoneTab => 'Completati';

  @override
  String get bandUnsorted => 'Da ordinare';

  @override
  String get bandNow => 'Ora';

  @override
  String get bandNext => 'Prossimo';

  @override
  String get bandLater => 'Più avanti';

  @override
  String bandLoad(int count, int limit) {
    return '$count/$limit';
  }

  @override
  String nowOverLimit(int limit) {
    return 'Più di $limit insieme: è davvero tutto per ora?';
  }

  @override
  String get bandEmpty => 'Trascina qui un task';

  @override
  String get taskManagerEmpty =>
      'Nessun task da fare.\nScrivine uno dalla home scegliendo \"Task\" nell\'editor.';

  @override
  String get taskManagerDoneEmpty =>
      'Nessun task completato.\nSpunta un task e lo ritrovi qui.';

  @override
  String get taskFilterTooltip => 'Filtra per tag o fonti';

  @override
  String get taskFilterReadOnly =>
      'Sola lettura: togli il filtro per spostare i task.';

  @override
  String get taskFilterClear => 'Togli il filtro';

  @override
  String get taskFilterNoGroups => 'I tuoi task non hanno ancora tag né fonti.';

  @override
  String get taskManagerFilteredEmpty => 'Nessun task da fare qui.';

  @override
  String get taskManagerFilteredDoneEmpty => 'Nessun task completato qui.';

  @override
  String get bandEmptyFiltered => 'Nessuno qui';

  @override
  String get dragToReorder => 'Trascina per spostare';

  @override
  String get sortByComparing => 'Ordina confrontando';

  @override
  String get sortAll => 'Ordina tutti';

  @override
  String get compareChooseBand => 'In quale fascia va?';

  @override
  String get compareQuestion => 'Quale viene prima?';

  @override
  String compareQuestionsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Al massimo $count domande',
      one: 'Al massimo 1 domanda',
    );
    return '$_temp0';
  }

  @override
  String get compareNewTask => 'Nuovo';

  @override
  String get compareSkip => 'Salta';

  @override
  String taskCompleted(String title) {
    return 'Fatto: $title';
  }

  @override
  String get shareToWorkspace => 'Dove salvare il testo condiviso';

  @override
  String get sharedAppended => 'Testo condiviso aggiunto in fondo alla bozza';

  @override
  String sharedSavedToDraft(String workspace) {
    return 'Testo condiviso aggiunto alla bozza di «$workspace»';
  }

  @override
  String tagColorTitle(String tag) {
    return 'Colore di $tag';
  }

  @override
  String get tagColorAuto => 'Colore automatico';

  @override
  String renameTagTitle(String tag) {
    return 'Rinomina $tag';
  }

  @override
  String renameSourceTitle(String source) {
    return 'Rinomina $source';
  }

  @override
  String renameMerges(String name) {
    return 'Esiste già: le note verranno unite a $name';
  }

  @override
  String get nextStepHint => 'Prossimo passo: quando, dove, da cosa parti';

  @override
  String get nextStep => 'Prossimo passo';

  @override
  String get addNextStep => 'Aggiungi il prossimo passo';

  @override
  String get nextStepHelp =>
      'Una riga concreta, es. “dopo pranzo, in biblioteca: leggo il cap. 3”.';

  @override
  String get brainDump => 'Svuota la testa';

  @override
  String get brainDumpHelp =>
      'Scrivi tutto quello che hai in testa, una cosa per riga. Ogni riga diventa un task in Da ordinare: l\'ordine lo decidi dopo.';

  @override
  String get brainDumpHint =>
      'Chiamare il dentista\nRestituire il libro\nChiedere ad Anna dell\'esame';

  @override
  String brainDumpAddCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aggiungi $count',
      one: 'Aggiungi 1',
      zero: 'Aggiungi',
    );
    return '$_temp0';
  }

  @override
  String brainDumpAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count task aggiunti a Da ordinare',
      one: '1 task aggiunto a Da ordinare',
    );
    return '$_temp0';
  }

  @override
  String get brainDumpDiscardTitle => 'Buttare quello che hai scritto?';

  @override
  String get brainDumpDiscard => 'Butta';

  @override
  String resumeEditing(String title) {
    return 'Stavi modificando «$title»';
  }

  @override
  String get resume => 'Riprendi';

  @override
  String get discardEdit => 'Butta le modifiche';

  @override
  String get recentlyOpened => 'Aperte di recente';

  @override
  String get tagsAndSources => 'Tag e fonti';

  @override
  String get alphabeticalGroups => 'Sempre in ordine alfabetico';

  @override
  String get alphabeticalGroupsHelp =>
      'Nella ricerca, in Task e note e nel filtro del task manager tag e fonti restano sempre nello stesso posto, invece di seguire quanto li usi.';

  @override
  String get linkNote => 'Connetti nota';

  @override
  String get pickNoteHint => 'Cerca la nota da collegare';

  @override
  String get noNotesToLink => 'Non ci sono ancora altre note da collegare';

  @override
  String get linkedNoteMissing =>
      'Questa nota non c\'è più: forse è nel cestino';

  @override
  String get diary => 'Diario';

  @override
  String get diaryTodayHint => 'Cosa è successo oggi?';

  @override
  String get diaryCreateNote => 'Crea nota';

  @override
  String diaryLoadError(String message) {
    return 'Impossibile leggere il diario: $message';
  }

  @override
  String diarySaveError(String message) {
    return 'Impossibile salvare il diario: $message';
  }

  @override
  String get noteCreated => 'Nota creata';

  @override
  String get diaryNothingWritten => 'Niente di scritto';

  @override
  String get diaryOpenNote => 'Apri nota';

  @override
  String get diaryExtractRemove => 'Togli colore';

  @override
  String get diaryExtractRemoved => 'Colore tolto: la nota resta';

  @override
  String get diaryCreateTask => 'Crea task';

  @override
  String get taskCreated => 'Task creato';
}
