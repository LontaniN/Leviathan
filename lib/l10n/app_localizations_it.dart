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
  String get onboardingTagline => 'Il tuo secondo cervello.';

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
}
