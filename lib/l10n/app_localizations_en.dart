// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cancel => 'Cancel';

  @override
  String get undo => 'Undo';

  @override
  String get delete => 'Delete';

  @override
  String get rename => 'Rename';

  @override
  String get create => 'Create';

  @override
  String get retry => 'Retry';

  @override
  String get apply => 'Apply';

  @override
  String get search => 'Search';

  @override
  String get closeSearch => 'Close search';

  @override
  String get clear => 'Clear';

  @override
  String get edit => 'Edit';

  @override
  String get more => 'More';

  @override
  String get untitled => 'Untitled';

  @override
  String errorMessage(String message) {
    return 'Error: $message';
  }

  @override
  String noteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$_temp0';
  }

  @override
  String openCount(int count) {
    return '$count to do';
  }

  @override
  String get languageTitle => 'Choose your language';

  @override
  String get languageBody => 'You can change it later in the settings.';

  @override
  String get language => 'Language';

  @override
  String get continueButton => 'Continue';

  @override
  String get onboardingTagline => 'Your second brain.';

  @override
  String get onboardingBody =>
      'Name your first workspace. Each workspace holds its own notes: you can create more at any time.';

  @override
  String get createWorkspace => 'Create workspace';

  @override
  String get workspaceNameHint => 'e.g. Work, Photography, Study…';

  @override
  String get workspaceNameEmpty => 'Enter a name';

  @override
  String workspaceNameTooLong(int max) {
    return 'Name too long (max $max characters)';
  }

  @override
  String get workspaceNameLeadingDot => 'The name can\'t start with a dot';

  @override
  String get workspaceNameTrailingDot => 'The name can\'t end with a dot';

  @override
  String workspaceNameInvalidChars(String chars) {
    return 'Characters not allowed: $chars';
  }

  @override
  String get workspaceNameTaken => 'A workspace with this name already exists';

  @override
  String get permissionTitle => 'File access';

  @override
  String get permissionBody =>
      'Notes are saved as files in the Documents/LeviathanNotes folder on your phone, so they stay yours even if you uninstall the app. To write there, Android asks for the \"All files access\" permission.';

  @override
  String get permissionGrant => 'Grant access';

  @override
  String get pinned => 'Pinned';

  @override
  String get graph => 'Graph';

  @override
  String get tasksAndNotes => 'Tasks and notes';

  @override
  String get calendar => 'Calendar';

  @override
  String get settings => 'Settings';

  @override
  String get searchNotes => 'Search notes';

  @override
  String loadError(String message) {
    return 'Couldn\'t read the notes: $message';
  }

  @override
  String allNotes(int count) {
    return 'All notes ($count)';
  }

  @override
  String get recent => 'Recent';

  @override
  String get noNotesYet => 'No notes. The ones you save show up here.';

  @override
  String get workspace => 'Workspace';

  @override
  String get renameWorkspace => 'Rename workspace';

  @override
  String get deleteWorkspace => 'Delete workspace';

  @override
  String get newWorkspace => 'New workspace';

  @override
  String deleteWorkspaceTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get deleteWorkspaceBody =>
      'The workspace, with its notes and its trash, is moved to .leviathan/deleted, not erased.';

  @override
  String get deleteWorkspaceLast =>
      'It\'s the only workspace: you\'ll have to create a new one.';

  @override
  String workspaceDeleted(String name) {
    return '“$name” moved to .leviathan/deleted';
  }

  @override
  String cannotDelete(String message) {
    return 'Couldn\'t delete: $message';
  }

  @override
  String cannotRename(String message) {
    return 'Couldn\'t rename: $message';
  }

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get thisWeek => 'This week';

  @override
  String movedToTrash(String title) {
    return '“$title” moved to the trash';
  }

  @override
  String get pinToTop => 'Pin to top';

  @override
  String get unpinFromTop => 'Unpin';

  @override
  String get markDone => 'Mark as done';

  @override
  String get markUndone => 'Mark as to do';

  @override
  String get moveToTrash => 'Move to trash';

  @override
  String unpinned(String title) {
    return '“$title” unpinned';
  }

  @override
  String pinnedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pinned notes',
      one: '1 pinned note',
    );
    return '$_temp0';
  }

  @override
  String get pinnedEmpty =>
      'No pinned notes.\nLong-press a note in the recent list, or tap the pin on a note or in the Tasks and notes lists.';

  @override
  String get periodEmpty => 'No notes in this period.';

  @override
  String periodNoMatch(String query) {
    return 'No note from this period contains \"$query\".';
  }

  @override
  String get sampleDataShort => 'sample data';

  @override
  String get textCopied => 'Text copied';

  @override
  String get copyText => 'Copy text';

  @override
  String editedOn(String date) {
    return 'edited $date';
  }

  @override
  String wordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String get noText => 'No text.';

  @override
  String get taskToDo => 'To do';

  @override
  String get taskDone => 'Done';

  @override
  String taskDoneOn(String date) {
    return 'Done on $date';
  }

  @override
  String get editNote => 'Edit note';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get saveNote => 'Save note';

  @override
  String get saveTask => 'Save task';

  @override
  String get noteDateToday => 'Date: today';

  @override
  String noteDateOn(String date) {
    return 'Date: $date';
  }

  @override
  String get noteDateTitle => 'When was it written?';

  @override
  String savedOnDate(String date) {
    return 'Saved on $date';
  }

  @override
  String get writeSomething => 'Write at least a title or some text';

  @override
  String get taskTitleHint => 'What needs doing?';

  @override
  String get titleHint => 'Title';

  @override
  String get bodyHint => 'Write your note…';

  @override
  String get kindNote => 'Note';

  @override
  String get kindTask => 'Task';

  @override
  String get knowledge => 'Knowledge';

  @override
  String get knowledgeTitleHint => 'What do you know?';

  @override
  String get formatBold => 'Bold';

  @override
  String get formatItalic => 'Italic';

  @override
  String get formatHeading => 'Heading';

  @override
  String get formatBullets => 'Bulleted list';

  @override
  String get formatNumbered => 'Numbered list';

  @override
  String get formatChecklist => 'Checklist';

  @override
  String get formatQuote => 'Quote';

  @override
  String get formatCode => 'Code';

  @override
  String get addTags => 'Add tags';

  @override
  String get addSources => 'Add sources (e.g. people)';

  @override
  String savedAs(String value) {
    return 'Will be saved as: $value';
  }

  @override
  String get sourceMarker => 'from:';

  @override
  String get statusMarker => 'status:';

  @override
  String get searchFieldHint => 'Search, or tag: / from:';

  @override
  String get frequentTags => 'Frequent tags';

  @override
  String get frequentSources => 'Frequent sources';

  @override
  String get searchFilters => 'Search filters';

  @override
  String get filterTagHelp => 'notes with a tag';

  @override
  String get filterSourceHelp => 'notes from a source (person)';

  @override
  String get filterStatusHelp => 'tasks to do or done';

  @override
  String shortcut(String key) {
    return 'shortcut: $key';
  }

  @override
  String get searchExample =>
      'Text and filters combine: for example \"exposure tag:photography from:Mario Rossi\" or \"status:open tag:university\".';

  @override
  String get tags => 'Tags';

  @override
  String get sources => 'Sources';

  @override
  String get taskStatus => 'Task status';

  @override
  String get noMatchingTag => 'No matching tag';

  @override
  String get noMatchingSource => 'No matching source';

  @override
  String get statusTypeHelp => 'Type open, done or task';

  @override
  String get noNotesFound => 'No notes found';

  @override
  String resultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String get statusTask => 'task';

  @override
  String get statusOpen => 'open';

  @override
  String get statusDone => 'done';

  @override
  String get statusTaskHelp => 'all tasks';

  @override
  String get statusOpenHelp => 'tasks to do';

  @override
  String get statusDoneHelp => 'completed tasks';

  @override
  String get byTag => 'By tag';

  @override
  String get bySource => 'By source';

  @override
  String get listsNoNotes => 'No notes yet: write one from the home screen.';

  @override
  String get listsNoKnowledge =>
      'No knowledge notes yet: mark a note with the light bulb in the editor.';

  @override
  String get listsNoTasks =>
      'No tasks yet: write one by choosing \"Task\" in the editor.';

  @override
  String get noTag => 'No tag';

  @override
  String get noSource => 'No source';

  @override
  String doneCount(int count) {
    return '$count done';
  }

  @override
  String get allDone => 'done';

  @override
  String get whereUntagged => 'among notes without tags';

  @override
  String get whereTag => 'in this tag';

  @override
  String get whereUnsourced => 'among notes without sources';

  @override
  String get whereSource => 'in this source';

  @override
  String get whereTasks => 'among tasks';

  @override
  String get whereNotes => 'among notes';

  @override
  String get whereKnowledge => 'in knowledge';

  @override
  String searchWhere(String where) {
    return 'Search $where';
  }

  @override
  String noResultsWhere(String where) {
    return 'No results $where.';
  }

  @override
  String get noNotesHere => 'No notes here.';

  @override
  String get noTasksHere => 'No tasks here.';

  @override
  String get noKnowledgeHere => 'No knowledge notes here.';

  @override
  String taskSummary(int total, int open) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total tasks',
      one: '1 task',
    );
    return '$_temp0 · $open to do';
  }

  @override
  String openTaskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks to do',
      one: '1 task to do',
    );
    return '$_temp0';
  }

  @override
  String doneTaskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks done',
      one: '1 task done',
    );
    return '$_temp0';
  }

  @override
  String get noTasks => 'No tasks.';

  @override
  String get noOpenTasks => 'No tasks to do.';

  @override
  String get noDoneTasks => 'No completed tasks.';

  @override
  String get filterAll => 'All';

  @override
  String get filterOpen => 'To do';

  @override
  String get filterDone => 'Done';

  @override
  String get viewTasks => 'Tasks';

  @override
  String get viewNotes => 'Notes';

  @override
  String get viewKnowledge => 'Knowledge';

  @override
  String get searchCalendar => 'Search the calendar';

  @override
  String get showRealNotes => 'Show real notes';

  @override
  String get sampleData => 'Sample data';

  @override
  String get daily => 'Daily';

  @override
  String get monthly => 'Monthly';

  @override
  String get sampleDataBanner => 'Sample data: these aren\'t your notes';

  @override
  String get calendarEmpty =>
      'No notes yet: the calendar fills up as you write.';

  @override
  String get periodNoTags => 'This period\'s notes have no tags.';

  @override
  String timesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: 'once',
    );
    return '$_temp0';
  }

  @override
  String showNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'See the $count notes',
      one: 'See the note',
    );
    return '$_temp0';
  }

  @override
  String get calendarNoMatch => 'No notes contain these words.';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String monthCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
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
      other: '$count links',
      one: '1 link',
    );
    return '$_temp0';
  }

  @override
  String get filter => 'Filter';

  @override
  String get center => 'Center';

  @override
  String get graphEmpty => 'Write a few notes to see the graph';

  @override
  String linkedNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count linked notes',
      one: '1 linked note',
    );
    return '$_temp0';
  }

  @override
  String get noTags => 'No tags';

  @override
  String get noSources => 'No sources';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get palette => 'Palette';

  @override
  String get dark => 'Dark';

  @override
  String get light => 'Light';

  @override
  String get paletteInchiostro => 'Ink';

  @override
  String get paletteSeppia => 'Sepia';

  @override
  String get paletteLavagna => 'Slate';

  @override
  String get paletteGrafite => 'Graphite';

  @override
  String get paletteAbisso => 'Abyss';

  @override
  String get paletteBrace => 'Ember';

  @override
  String get paletteMuschio => 'Moss';

  @override
  String get paletteAmetista => 'Amethyst';

  @override
  String get paletteCarta => 'Paper';

  @override
  String tourWelcomeTitle(String workspace) {
    return '$workspace is ready';
  }

  @override
  String get tourWelcomeBody =>
      'Want a quick tour of the main features? It takes five steps.';

  @override
  String get tourStart => 'Start the tour';

  @override
  String get tourSkip => 'Skip';

  @override
  String get tourBack => 'Back';

  @override
  String get tourNext => 'Next';

  @override
  String get tourDone => 'Done';

  @override
  String tourProgress(int current, int total) {
    return '$current of $total';
  }

  @override
  String get tourEditorTitle => 'Write a note';

  @override
  String get tourEditorBody =>
      'Give it a title and write the text in Markdown. At the top, choose whether it\'s a note or a task to check off.';

  @override
  String get tourTagsTitle => 'Tags connect everything';

  @override
  String get tourTagsBody =>
      'Add as many as you like: the ones you already use are suggested as you type. The first tag gives the note its color. Below, note where the idea came from.';

  @override
  String get tourListTitle => 'Your notes';

  @override
  String get tourListBody =>
      'The latest ones, newest first. Tap to read and edit; press and hold to pin, check off or delete. The arrow widens the list.';

  @override
  String get tourSearchTitle => 'Find anything';

  @override
  String get tourSearchBody =>
      'Search titles, text, tags and sources. Type # to filter by tag and @ by source.';

  @override
  String get tourViewsTitle => 'Other views';

  @override
  String get tourViewsBody =>
      'Pinned notes, the graph of notes linked by tags, task and note lists, the calendar, and the settings, where you can replay this tour.';

  @override
  String get guide => 'Guide';

  @override
  String get replayTour => 'Replay the tour';
}
