import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @closeSearch.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get closeSearch;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @errorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorMessage(String message);

  /// No description provided for @noteCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 note} other{{count} notes}}'**
  String noteCount(int count);

  /// No description provided for @openCount.
  ///
  /// In en, this message translates to:
  /// **'{count} to do'**
  String openCount(int count);

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get languageTitle;

  /// No description provided for @languageBody.
  ///
  /// In en, this message translates to:
  /// **'You can change it later in the settings.'**
  String get languageBody;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @onboardingTagline.
  ///
  /// In en, this message translates to:
  /// **'Face the outside world through bytes.'**
  String get onboardingTagline;

  /// No description provided for @onboardingBody.
  ///
  /// In en, this message translates to:
  /// **'Name your first workspace. Each workspace holds its own notes: you can create more at any time.'**
  String get onboardingBody;

  /// No description provided for @createWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Create workspace'**
  String get createWorkspace;

  /// No description provided for @workspaceNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Work, Photography, Study…'**
  String get workspaceNameHint;

  /// No description provided for @workspaceNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get workspaceNameEmpty;

  /// No description provided for @workspaceNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Name too long (max {max} characters)'**
  String workspaceNameTooLong(int max);

  /// No description provided for @workspaceNameLeadingDot.
  ///
  /// In en, this message translates to:
  /// **'The name can\'t start with a dot'**
  String get workspaceNameLeadingDot;

  /// No description provided for @workspaceNameTrailingDot.
  ///
  /// In en, this message translates to:
  /// **'The name can\'t end with a dot'**
  String get workspaceNameTrailingDot;

  /// No description provided for @workspaceNameInvalidChars.
  ///
  /// In en, this message translates to:
  /// **'Characters not allowed: {chars}'**
  String workspaceNameInvalidChars(String chars);

  /// No description provided for @workspaceNameTaken.
  ///
  /// In en, this message translates to:
  /// **'A workspace with this name already exists'**
  String get workspaceNameTaken;

  /// No description provided for @permissionTitle.
  ///
  /// In en, this message translates to:
  /// **'File access'**
  String get permissionTitle;

  /// No description provided for @permissionBody.
  ///
  /// In en, this message translates to:
  /// **'Notes are saved as files in the Documents/LeviathanNotes folder on your phone, so they stay yours even if you uninstall the app. To write there, Android asks for the \"All files access\" permission.'**
  String get permissionBody;

  /// No description provided for @permissionGrant.
  ///
  /// In en, this message translates to:
  /// **'Grant access'**
  String get permissionGrant;

  /// No description provided for @pinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get pinned;

  /// No description provided for @graph.
  ///
  /// In en, this message translates to:
  /// **'Graph'**
  String get graph;

  /// No description provided for @tasksAndNotes.
  ///
  /// In en, this message translates to:
  /// **'Tasks and notes'**
  String get tasksAndNotes;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @searchNotes.
  ///
  /// In en, this message translates to:
  /// **'Search notes'**
  String get searchNotes;

  /// No description provided for @loadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the notes: {message}'**
  String loadError(String message);

  /// No description provided for @allNotes.
  ///
  /// In en, this message translates to:
  /// **'All notes ({count})'**
  String allNotes(int count);

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @noNotesYet.
  ///
  /// In en, this message translates to:
  /// **'No notes. The ones you save show up here.'**
  String get noNotesYet;

  /// No description provided for @workspace.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get workspace;

  /// No description provided for @renameWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Rename workspace'**
  String get renameWorkspace;

  /// No description provided for @deleteWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Delete workspace'**
  String get deleteWorkspace;

  /// No description provided for @newWorkspace.
  ///
  /// In en, this message translates to:
  /// **'New workspace'**
  String get newWorkspace;

  /// No description provided for @deleteWorkspaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String deleteWorkspaceTitle(String name);

  /// No description provided for @deleteWorkspaceBody.
  ///
  /// In en, this message translates to:
  /// **'The workspace, with its notes and its trash, is moved to .leviathan/deleted, not erased.'**
  String get deleteWorkspaceBody;

  /// No description provided for @deleteWorkspaceLast.
  ///
  /// In en, this message translates to:
  /// **'It\'s the only workspace: you\'ll have to create a new one.'**
  String get deleteWorkspaceLast;

  /// No description provided for @workspaceDeleted.
  ///
  /// In en, this message translates to:
  /// **'“{name}” moved to .leviathan/deleted'**
  String workspaceDeleted(String name);

  /// No description provided for @cannotDelete.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete: {message}'**
  String cannotDelete(String message);

  /// No description provided for @cannotRename.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t rename: {message}'**
  String cannotRename(String message);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @movedToTrash.
  ///
  /// In en, this message translates to:
  /// **'“{title}” moved to the trash'**
  String movedToTrash(String title);

  /// No description provided for @pinToTop.
  ///
  /// In en, this message translates to:
  /// **'Pin to top'**
  String get pinToTop;

  /// No description provided for @unpinFromTop.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpinFromTop;

  /// No description provided for @markDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as done'**
  String get markDone;

  /// No description provided for @markUndone.
  ///
  /// In en, this message translates to:
  /// **'Mark as to do'**
  String get markUndone;

  /// No description provided for @moveToTrash.
  ///
  /// In en, this message translates to:
  /// **'Move to trash'**
  String get moveToTrash;

  /// No description provided for @unpinned.
  ///
  /// In en, this message translates to:
  /// **'“{title}” unpinned'**
  String unpinned(String title);

  /// No description provided for @pinnedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pinned note} other{{count} pinned notes}}'**
  String pinnedCount(int count);

  /// No description provided for @pinnedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pinned notes.\nLong-press a note in the recent list, or tap the pin on a note or in the Tasks and notes lists.'**
  String get pinnedEmpty;

  /// No description provided for @periodEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notes in this period.'**
  String get periodEmpty;

  /// No description provided for @periodNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No note from this period contains \"{query}\".'**
  String periodNoMatch(String query);

  /// No description provided for @sampleDataShort.
  ///
  /// In en, this message translates to:
  /// **'sample data'**
  String get sampleDataShort;

  /// No description provided for @textCopied.
  ///
  /// In en, this message translates to:
  /// **'Text copied'**
  String get textCopied;

  /// No description provided for @copyText.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get copyText;

  /// No description provided for @convertToTask.
  ///
  /// In en, this message translates to:
  /// **'Convert to task'**
  String get convertToTask;

  /// No description provided for @convertToNote.
  ///
  /// In en, this message translates to:
  /// **'Convert to note'**
  String get convertToNote;

  /// No description provided for @editedOn.
  ///
  /// In en, this message translates to:
  /// **'edited {date}'**
  String editedOn(String date);

  /// No description provided for @wordCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word} other{{count} words}}'**
  String wordCount(int count);

  /// No description provided for @noText.
  ///
  /// In en, this message translates to:
  /// **'No text.'**
  String get noText;

  /// No description provided for @taskToDo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get taskToDo;

  /// No description provided for @taskDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get taskDone;

  /// No description provided for @taskDoneOn.
  ///
  /// In en, this message translates to:
  /// **'Done on {date}'**
  String taskDoneOn(String date);

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get editNote;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @saveNote.
  ///
  /// In en, this message translates to:
  /// **'Save note'**
  String get saveNote;

  /// No description provided for @saveTask.
  ///
  /// In en, this message translates to:
  /// **'Save task'**
  String get saveTask;

  /// No description provided for @noteDateToday.
  ///
  /// In en, this message translates to:
  /// **'Date: today'**
  String get noteDateToday;

  /// No description provided for @noteDateOn.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String noteDateOn(String date);

  /// No description provided for @noteDateTitle.
  ///
  /// In en, this message translates to:
  /// **'When was it written?'**
  String get noteDateTitle;

  /// No description provided for @savedOnDate.
  ///
  /// In en, this message translates to:
  /// **'Saved on {date}'**
  String savedOnDate(String date);

  /// No description provided for @writeSomething.
  ///
  /// In en, this message translates to:
  /// **'Write at least a title or some text'**
  String get writeSomething;

  /// No description provided for @taskTitleHint.
  ///
  /// In en, this message translates to:
  /// **'What needs doing?'**
  String get taskTitleHint;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleHint;

  /// No description provided for @bodyHint.
  ///
  /// In en, this message translates to:
  /// **'Write your note…'**
  String get bodyHint;

  /// No description provided for @kindNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get kindNote;

  /// No description provided for @kindTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get kindTask;

  /// No description provided for @knowledge.
  ///
  /// In en, this message translates to:
  /// **'Knowledge'**
  String get knowledge;

  /// No description provided for @knowledgeTitleHint.
  ///
  /// In en, this message translates to:
  /// **'What do you know?'**
  String get knowledgeTitleHint;

  /// No description provided for @formatBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get formatBold;

  /// No description provided for @formatItalic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get formatItalic;

  /// No description provided for @formatHeading.
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get formatHeading;

  /// No description provided for @formatBullets.
  ///
  /// In en, this message translates to:
  /// **'Bulleted list'**
  String get formatBullets;

  /// No description provided for @formatNumbered.
  ///
  /// In en, this message translates to:
  /// **'Numbered list'**
  String get formatNumbered;

  /// No description provided for @formatChecklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get formatChecklist;

  /// No description provided for @formatQuote.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get formatQuote;

  /// No description provided for @formatCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get formatCode;

  /// No description provided for @addTags.
  ///
  /// In en, this message translates to:
  /// **'Add tags'**
  String get addTags;

  /// No description provided for @addSources.
  ///
  /// In en, this message translates to:
  /// **'Add sources (e.g. people)'**
  String get addSources;

  /// No description provided for @savedAs.
  ///
  /// In en, this message translates to:
  /// **'Will be saved as: {value}'**
  String savedAs(String value);

  /// No description provided for @sourceMarker.
  ///
  /// In en, this message translates to:
  /// **'from:'**
  String get sourceMarker;

  /// No description provided for @statusMarker.
  ///
  /// In en, this message translates to:
  /// **'status:'**
  String get statusMarker;

  /// No description provided for @searchFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Search, or tag: / from:'**
  String get searchFieldHint;

  /// No description provided for @frequentTags.
  ///
  /// In en, this message translates to:
  /// **'Frequent tags'**
  String get frequentTags;

  /// No description provided for @frequentSources.
  ///
  /// In en, this message translates to:
  /// **'Frequent sources'**
  String get frequentSources;

  /// No description provided for @searchFilters.
  ///
  /// In en, this message translates to:
  /// **'Search filters'**
  String get searchFilters;

  /// No description provided for @filterTagHelp.
  ///
  /// In en, this message translates to:
  /// **'notes with a tag'**
  String get filterTagHelp;

  /// No description provided for @filterSourceHelp.
  ///
  /// In en, this message translates to:
  /// **'notes from a source (person)'**
  String get filterSourceHelp;

  /// No description provided for @filterStatusHelp.
  ///
  /// In en, this message translates to:
  /// **'tasks to do or done'**
  String get filterStatusHelp;

  /// No description provided for @shortcut.
  ///
  /// In en, this message translates to:
  /// **'shortcut: {key}'**
  String shortcut(String key);

  /// No description provided for @searchExample.
  ///
  /// In en, this message translates to:
  /// **'Text and filters combine: for example \"exposure tag:photography from:Mario Rossi\" or \"status:open tag:university\".'**
  String get searchExample;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @sources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get sources;

  /// No description provided for @taskStatus.
  ///
  /// In en, this message translates to:
  /// **'Task status'**
  String get taskStatus;

  /// No description provided for @noMatchingTag.
  ///
  /// In en, this message translates to:
  /// **'No matching tag'**
  String get noMatchingTag;

  /// No description provided for @noMatchingSource.
  ///
  /// In en, this message translates to:
  /// **'No matching source'**
  String get noMatchingSource;

  /// No description provided for @statusTypeHelp.
  ///
  /// In en, this message translates to:
  /// **'Type open, done or task'**
  String get statusTypeHelp;

  /// No description provided for @noNotesFound.
  ///
  /// In en, this message translates to:
  /// **'No notes found'**
  String get noNotesFound;

  /// No description provided for @resultCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 result} other{{count} results}}'**
  String resultCount(int count);

  /// No description provided for @statusTask.
  ///
  /// In en, this message translates to:
  /// **'task'**
  String get statusTask;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get statusOpen;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get statusDone;

  /// No description provided for @statusTaskHelp.
  ///
  /// In en, this message translates to:
  /// **'all tasks'**
  String get statusTaskHelp;

  /// No description provided for @statusOpenHelp.
  ///
  /// In en, this message translates to:
  /// **'tasks to do'**
  String get statusOpenHelp;

  /// No description provided for @statusDoneHelp.
  ///
  /// In en, this message translates to:
  /// **'completed tasks'**
  String get statusDoneHelp;

  /// No description provided for @byTag.
  ///
  /// In en, this message translates to:
  /// **'By tag'**
  String get byTag;

  /// No description provided for @bySource.
  ///
  /// In en, this message translates to:
  /// **'By source'**
  String get bySource;

  /// No description provided for @listsNoNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes yet: write one from the home screen.'**
  String get listsNoNotes;

  /// No description provided for @listsNoKnowledge.
  ///
  /// In en, this message translates to:
  /// **'No knowledge notes yet: mark a note with the light bulb in the editor.'**
  String get listsNoKnowledge;

  /// No description provided for @listsNoTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet: write one by choosing \"Task\" in the editor.'**
  String get listsNoTasks;

  /// No description provided for @noTag.
  ///
  /// In en, this message translates to:
  /// **'No tag'**
  String get noTag;

  /// No description provided for @noSource.
  ///
  /// In en, this message translates to:
  /// **'No source'**
  String get noSource;

  /// No description provided for @doneCount.
  ///
  /// In en, this message translates to:
  /// **'{count} done'**
  String doneCount(int count);

  /// No description provided for @allDone.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get allDone;

  /// No description provided for @whereUntagged.
  ///
  /// In en, this message translates to:
  /// **'among notes without tags'**
  String get whereUntagged;

  /// No description provided for @whereTag.
  ///
  /// In en, this message translates to:
  /// **'in this tag'**
  String get whereTag;

  /// No description provided for @whereUnsourced.
  ///
  /// In en, this message translates to:
  /// **'among notes without sources'**
  String get whereUnsourced;

  /// No description provided for @whereSource.
  ///
  /// In en, this message translates to:
  /// **'in this source'**
  String get whereSource;

  /// No description provided for @whereTasks.
  ///
  /// In en, this message translates to:
  /// **'among tasks'**
  String get whereTasks;

  /// No description provided for @whereNotes.
  ///
  /// In en, this message translates to:
  /// **'among notes'**
  String get whereNotes;

  /// No description provided for @whereKnowledge.
  ///
  /// In en, this message translates to:
  /// **'in knowledge'**
  String get whereKnowledge;

  /// No description provided for @searchWhere.
  ///
  /// In en, this message translates to:
  /// **'Search {where}'**
  String searchWhere(String where);

  /// No description provided for @noResultsWhere.
  ///
  /// In en, this message translates to:
  /// **'No results {where}.'**
  String noResultsWhere(String where);

  /// No description provided for @noNotesHere.
  ///
  /// In en, this message translates to:
  /// **'No notes here.'**
  String get noNotesHere;

  /// No description provided for @noTasksHere.
  ///
  /// In en, this message translates to:
  /// **'No tasks here.'**
  String get noTasksHere;

  /// No description provided for @noKnowledgeHere.
  ///
  /// In en, this message translates to:
  /// **'No knowledge notes here.'**
  String get noKnowledgeHere;

  /// No description provided for @taskSummary.
  ///
  /// In en, this message translates to:
  /// **'{total, plural, =1{1 task} other{{total} tasks}} · {open} to do'**
  String taskSummary(int total, int open);

  /// No description provided for @openTaskCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 task to do} other{{count} tasks to do}}'**
  String openTaskCount(int count);

  /// No description provided for @doneTaskCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 task done} other{{count} tasks done}}'**
  String doneTaskCount(int count);

  /// No description provided for @noTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks.'**
  String get noTasks;

  /// No description provided for @noOpenTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks to do.'**
  String get noOpenTasks;

  /// No description provided for @noDoneTasks.
  ///
  /// In en, this message translates to:
  /// **'No completed tasks.'**
  String get noDoneTasks;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterOpen.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get filterOpen;

  /// No description provided for @filterDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get filterDone;

  /// No description provided for @viewTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get viewTasks;

  /// No description provided for @viewNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get viewNotes;

  /// No description provided for @viewKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Knowledge'**
  String get viewKnowledge;

  /// No description provided for @searchCalendar.
  ///
  /// In en, this message translates to:
  /// **'Search the calendar'**
  String get searchCalendar;

  /// No description provided for @showRealNotes.
  ///
  /// In en, this message translates to:
  /// **'Show real notes'**
  String get showRealNotes;

  /// No description provided for @sampleData.
  ///
  /// In en, this message translates to:
  /// **'Sample data'**
  String get sampleData;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @sampleDataBanner.
  ///
  /// In en, this message translates to:
  /// **'Sample data: these aren\'t your notes'**
  String get sampleDataBanner;

  /// No description provided for @calendarEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notes yet: the calendar fills up as you write.'**
  String get calendarEmpty;

  /// No description provided for @periodNoTags.
  ///
  /// In en, this message translates to:
  /// **'This period\'s notes have no tags.'**
  String get periodNoTags;

  /// No description provided for @timesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{once} other{{count} times}}'**
  String timesCount(int count);

  /// No description provided for @showNotes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{See the note} other{See the {count} notes}}'**
  String showNotes(int count);

  /// No description provided for @calendarNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No notes contain these words.'**
  String get calendarNoMatch;

  /// No description provided for @dayCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String dayCount(int count);

  /// No description provided for @monthCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month} other{{count} months}}'**
  String monthCount(int count);

  /// No description provided for @notesIn.
  ///
  /// In en, this message translates to:
  /// **'{notes} in {where}'**
  String notesIn(String notes, String where);

  /// No description provided for @linkCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 link} other{{count} links}}'**
  String linkCount(int count);

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @center.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get center;

  /// No description provided for @graphEmpty.
  ///
  /// In en, this message translates to:
  /// **'Write a few notes to see the graph'**
  String get graphEmpty;

  /// No description provided for @linkedNotes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 linked note} other{{count} linked notes}}'**
  String linkedNotes(int count);

  /// No description provided for @noTags.
  ///
  /// In en, this message translates to:
  /// **'No tags'**
  String get noTags;

  /// No description provided for @noSources.
  ///
  /// In en, this message translates to:
  /// **'No sources'**
  String get noSources;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @palette.
  ///
  /// In en, this message translates to:
  /// **'Palette'**
  String get palette;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @paletteInchiostro.
  ///
  /// In en, this message translates to:
  /// **'Ink'**
  String get paletteInchiostro;

  /// No description provided for @paletteSeppia.
  ///
  /// In en, this message translates to:
  /// **'Sepia'**
  String get paletteSeppia;

  /// No description provided for @paletteLavagna.
  ///
  /// In en, this message translates to:
  /// **'Slate'**
  String get paletteLavagna;

  /// No description provided for @paletteGrafite.
  ///
  /// In en, this message translates to:
  /// **'Graphite'**
  String get paletteGrafite;

  /// No description provided for @paletteAbisso.
  ///
  /// In en, this message translates to:
  /// **'Abyss'**
  String get paletteAbisso;

  /// No description provided for @paletteBrace.
  ///
  /// In en, this message translates to:
  /// **'Ember'**
  String get paletteBrace;

  /// No description provided for @paletteMuschio.
  ///
  /// In en, this message translates to:
  /// **'Moss'**
  String get paletteMuschio;

  /// No description provided for @paletteAmetista.
  ///
  /// In en, this message translates to:
  /// **'Amethyst'**
  String get paletteAmetista;

  /// No description provided for @paletteCarta.
  ///
  /// In en, this message translates to:
  /// **'Paper'**
  String get paletteCarta;

  /// No description provided for @tourWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'{workspace} is ready'**
  String tourWelcomeTitle(String workspace);

  /// No description provided for @tourWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Want a quick tour of the main features? It takes six steps.'**
  String get tourWelcomeBody;

  /// No description provided for @tourStart.
  ///
  /// In en, this message translates to:
  /// **'Start the tour'**
  String get tourStart;

  /// No description provided for @tourSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tourSkip;

  /// No description provided for @tourBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get tourBack;

  /// No description provided for @tourNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tourNext;

  /// No description provided for @tourDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tourDone;

  /// No description provided for @tourProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String tourProgress(int current, int total);

  /// No description provided for @tourEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Write a note'**
  String get tourEditorTitle;

  /// No description provided for @tourEditorBody.
  ///
  /// In en, this message translates to:
  /// **'Give it a title and write the text in Markdown. At the top, choose whether it\'s a note or a task to check off.'**
  String get tourEditorBody;

  /// No description provided for @tourTagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tags connect everything'**
  String get tourTagsTitle;

  /// No description provided for @tourTagsBody.
  ///
  /// In en, this message translates to:
  /// **'Add as many as you like: the ones you already use are suggested as you type. The first tag gives the note its color. Below, note where the idea came from.'**
  String get tourTagsBody;

  /// No description provided for @tourListTitle.
  ///
  /// In en, this message translates to:
  /// **'Your notes'**
  String get tourListTitle;

  /// No description provided for @tourListBody.
  ///
  /// In en, this message translates to:
  /// **'This button opens all your notes, newest first. Tap one to read and edit it; press and hold to pin, check off or delete it.'**
  String get tourListBody;

  /// No description provided for @tourSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Find anything'**
  String get tourSearchTitle;

  /// No description provided for @tourSearchBody.
  ///
  /// In en, this message translates to:
  /// **'Search titles, text, tags and sources. Type # to filter by tag and @ by source.'**
  String get tourSearchBody;

  /// No description provided for @tourTaskManagerTitle.
  ///
  /// In en, this message translates to:
  /// **'Put tasks in order'**
  String get tourTaskManagerTitle;

  /// No description provided for @tourTaskManagerBody.
  ///
  /// In en, this message translates to:
  /// **'The task manager sorts open tasks into Now, Next and Later: their position is their priority. Press and hold a task and drag it to move it. New tasks wait in To sort: answer a few \"Which comes first?\" to place them. Ticked tasks end up in Completed.'**
  String get tourTaskManagerBody;

  /// No description provided for @tourViewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Other views'**
  String get tourViewsTitle;

  /// No description provided for @tourViewsBody.
  ///
  /// In en, this message translates to:
  /// **'Pinned notes, the graph of notes linked by tags, task and note lists, the calendar, the diary and the settings, where you can replay this tour.'**
  String get tourViewsBody;

  /// No description provided for @guide.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get guide;

  /// No description provided for @replayTour.
  ///
  /// In en, this message translates to:
  /// **'Replay the tour'**
  String get replayTour;

  /// No description provided for @taskManager.
  ///
  /// In en, this message translates to:
  /// **'Task manager'**
  String get taskManager;

  /// No description provided for @taskManagerOpenTab.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get taskManagerOpenTab;

  /// No description provided for @taskManagerDoneTab.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get taskManagerDoneTab;

  /// No description provided for @bandUnsorted.
  ///
  /// In en, this message translates to:
  /// **'To sort'**
  String get bandUnsorted;

  /// No description provided for @bandNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get bandNow;

  /// No description provided for @bandNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get bandNext;

  /// No description provided for @bandLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get bandLater;

  /// No description provided for @bandLoad.
  ///
  /// In en, this message translates to:
  /// **'{count}/{limit}'**
  String bandLoad(int count, int limit);

  /// No description provided for @nowOverLimit.
  ///
  /// In en, this message translates to:
  /// **'More than {limit} at once: is it all really for now?'**
  String nowOverLimit(int limit);

  /// No description provided for @bandEmpty.
  ///
  /// In en, this message translates to:
  /// **'Drag a task here'**
  String get bandEmpty;

  /// No description provided for @taskManagerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tasks to do.\nWrite one from the home screen by choosing \"Task\" in the editor.'**
  String get taskManagerEmpty;

  /// No description provided for @taskManagerDoneEmpty.
  ///
  /// In en, this message translates to:
  /// **'No completed tasks yet.\nTick a task and it shows up here.'**
  String get taskManagerDoneEmpty;

  /// No description provided for @taskFilterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter by tags or sources'**
  String get taskFilterTooltip;

  /// No description provided for @taskFilterReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read only: clear the filter to move tasks.'**
  String get taskFilterReadOnly;

  /// No description provided for @taskFilterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get taskFilterClear;

  /// No description provided for @taskFilterNoGroups.
  ///
  /// In en, this message translates to:
  /// **'No tags or sources on your tasks yet.'**
  String get taskFilterNoGroups;

  /// No description provided for @taskManagerFilteredEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tasks to do here.'**
  String get taskManagerFilteredEmpty;

  /// No description provided for @taskManagerFilteredDoneEmpty.
  ///
  /// In en, this message translates to:
  /// **'No completed tasks here.'**
  String get taskManagerFilteredDoneEmpty;

  /// No description provided for @bandEmptyFiltered.
  ///
  /// In en, this message translates to:
  /// **'None here'**
  String get bandEmptyFiltered;

  /// No description provided for @dragToReorder.
  ///
  /// In en, this message translates to:
  /// **'Drag to move'**
  String get dragToReorder;

  /// No description provided for @sortByComparing.
  ///
  /// In en, this message translates to:
  /// **'Sort by comparing'**
  String get sortByComparing;

  /// No description provided for @sortAll.
  ///
  /// In en, this message translates to:
  /// **'Sort all'**
  String get sortAll;

  /// No description provided for @compareChooseBand.
  ///
  /// In en, this message translates to:
  /// **'Which band does it go in?'**
  String get compareChooseBand;

  /// No description provided for @compareQuestion.
  ///
  /// In en, this message translates to:
  /// **'Which comes first?'**
  String get compareQuestion;

  /// No description provided for @compareQuestionsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{At most 1 question left} other{At most {count} questions left}}'**
  String compareQuestionsLeft(int count);

  /// No description provided for @compareNewTask.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get compareNewTask;

  /// No description provided for @compareSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get compareSkip;

  /// No description provided for @taskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Done: {title}'**
  String taskCompleted(String title);

  /// No description provided for @shareToWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Save shared text to'**
  String get shareToWorkspace;

  /// No description provided for @sharedAppended.
  ///
  /// In en, this message translates to:
  /// **'Shared text added to the end of your draft'**
  String get sharedAppended;

  /// No description provided for @sharedSavedToDraft.
  ///
  /// In en, this message translates to:
  /// **'Shared text added to the draft in “{workspace}”'**
  String sharedSavedToDraft(String workspace);

  /// No description provided for @tagColorTitle.
  ///
  /// In en, this message translates to:
  /// **'Color of {tag}'**
  String tagColorTitle(String tag);

  /// No description provided for @tagColorAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic color'**
  String get tagColorAuto;

  /// No description provided for @renameTagTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename {tag}'**
  String renameTagTitle(String tag);

  /// No description provided for @renameSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename {source}'**
  String renameSourceTitle(String source);

  /// No description provided for @renameMerges.
  ///
  /// In en, this message translates to:
  /// **'Already exists: notes will be merged into {name}'**
  String renameMerges(String name);

  /// No description provided for @brainDump.
  ///
  /// In en, this message translates to:
  /// **'Empty your head'**
  String get brainDump;

  /// No description provided for @brainDumpHelp.
  ///
  /// In en, this message translates to:
  /// **'Write down everything on your mind, one thing per line. Each line becomes a task in To sort: you\'ll put them in order later.'**
  String get brainDumpHelp;

  /// No description provided for @brainDumpHint.
  ///
  /// In en, this message translates to:
  /// **'Call the dentist\nReturn the book\nAsk Anna about the exam'**
  String get brainDumpHint;

  /// No description provided for @brainDumpAddCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Add} =1{Add 1} other{Add {count}}}'**
  String brainDumpAddCount(int count);

  /// No description provided for @brainDumpAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 task added to To sort} other{{count} tasks added to To sort}}'**
  String brainDumpAdded(int count);

  /// No description provided for @brainDumpDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard what you wrote?'**
  String get brainDumpDiscardTitle;

  /// No description provided for @brainDumpDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get brainDumpDiscard;

  /// No description provided for @resumeEditing.
  ///
  /// In en, this message translates to:
  /// **'You were editing “{title}”'**
  String resumeEditing(String title);

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @discardEdit.
  ///
  /// In en, this message translates to:
  /// **'Discard the changes'**
  String get discardEdit;

  /// No description provided for @recentlyOpened.
  ///
  /// In en, this message translates to:
  /// **'Recently opened'**
  String get recentlyOpened;

  /// No description provided for @tagsAndSources.
  ///
  /// In en, this message translates to:
  /// **'Tags and sources'**
  String get tagsAndSources;

  /// No description provided for @alphabeticalGroups.
  ///
  /// In en, this message translates to:
  /// **'Always in alphabetical order'**
  String get alphabeticalGroups;

  /// No description provided for @alphabeticalGroupsHelp.
  ///
  /// In en, this message translates to:
  /// **'In search, Tasks and notes and the task manager filter, tags and sources stay in the same place instead of following how much you use them.'**
  String get alphabeticalGroupsHelp;

  /// No description provided for @linkNote.
  ///
  /// In en, this message translates to:
  /// **'Link note'**
  String get linkNote;

  /// No description provided for @pickNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Search the note to link'**
  String get pickNoteHint;

  /// No description provided for @noNotesToLink.
  ///
  /// In en, this message translates to:
  /// **'There are no other notes to link yet'**
  String get noNotesToLink;

  /// No description provided for @linkedNoteMissing.
  ///
  /// In en, this message translates to:
  /// **'This note no longer exists: it may be in the trash'**
  String get linkedNoteMissing;

  /// No description provided for @diary.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get diary;

  /// No description provided for @diaryTodayHint.
  ///
  /// In en, this message translates to:
  /// **'What happened today?'**
  String get diaryTodayHint;

  /// No description provided for @diaryCreateNote.
  ///
  /// In en, this message translates to:
  /// **'Create note'**
  String get diaryCreateNote;

  /// No description provided for @diaryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the diary: {message}'**
  String diaryLoadError(String message);

  /// No description provided for @diarySaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the diary: {message}'**
  String diarySaveError(String message);

  /// No description provided for @noteCreated.
  ///
  /// In en, this message translates to:
  /// **'Note created'**
  String get noteCreated;

  /// No description provided for @diaryNothingWritten.
  ///
  /// In en, this message translates to:
  /// **'Nothing written'**
  String get diaryNothingWritten;

  /// No description provided for @diaryExpandAll.
  ///
  /// In en, this message translates to:
  /// **'Expand all days'**
  String get diaryExpandAll;

  /// No description provided for @diaryCollapseAll.
  ///
  /// In en, this message translates to:
  /// **'Collapse all days'**
  String get diaryCollapseAll;

  /// No description provided for @diaryExpandDay.
  ///
  /// In en, this message translates to:
  /// **'Expand this day'**
  String get diaryExpandDay;

  /// No description provided for @diaryCollapseDay.
  ///
  /// In en, this message translates to:
  /// **'Collapse this day'**
  String get diaryCollapseDay;

  /// No description provided for @diaryOpenNote.
  ///
  /// In en, this message translates to:
  /// **'Open note'**
  String get diaryOpenNote;

  /// No description provided for @diaryExtractRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove color'**
  String get diaryExtractRemove;

  /// No description provided for @diaryExtractRemoved.
  ///
  /// In en, this message translates to:
  /// **'Color removed: the note stays'**
  String get diaryExtractRemoved;

  /// No description provided for @diaryCreateTask.
  ///
  /// In en, this message translates to:
  /// **'Create task'**
  String get diaryCreateTask;

  /// No description provided for @diarySearch.
  ///
  /// In en, this message translates to:
  /// **'Search the diary'**
  String get diarySearch;

  /// No description provided for @diaryCloseSearch.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get diaryCloseSearch;

  /// No description provided for @diaryNoDaysFound.
  ///
  /// In en, this message translates to:
  /// **'No day contains these words'**
  String get diaryNoDaysFound;

  /// No description provided for @diaryDayCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String diaryDayCount(int count);

  /// No description provided for @taskCreated.
  ///
  /// In en, this message translates to:
  /// **'Task created'**
  String get taskCreated;

  /// No description provided for @dueDateAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a due date'**
  String get dueDateAdd;

  /// No description provided for @dueOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String dueOn(String date);

  /// No description provided for @dueDateClear.
  ///
  /// In en, this message translates to:
  /// **'Remove due date'**
  String get dueDateClear;

  /// No description provided for @dueDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Task due date'**
  String get dueDateTitle;

  /// No description provided for @taskManagerDueTab.
  ///
  /// In en, this message translates to:
  /// **'Due dates'**
  String get taskManagerDueTab;

  /// No description provided for @dueSectionOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get dueSectionOverdue;

  /// No description provided for @dueSectionTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get dueSectionTomorrow;

  /// No description provided for @dueSectionWeek.
  ///
  /// In en, this message translates to:
  /// **'Next 7 days'**
  String get dueSectionWeek;

  /// No description provided for @dueSectionLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get dueSectionLater;

  /// No description provided for @dueIn.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{today} =1{tomorrow} other{in {count} days}}'**
  String dueIn(int count);

  /// No description provided for @dueOverdueBy.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{overdue since yesterday} other{overdue by {count} days}}'**
  String dueOverdueBy(int count);

  /// No description provided for @taskManagerDueEmpty.
  ///
  /// In en, this message translates to:
  /// **'No task has a due date. Add one under the title of a task.'**
  String get taskManagerDueEmpty;

  /// No description provided for @taskManagerFilteredDueEmpty.
  ///
  /// In en, this message translates to:
  /// **'No task of these lists has a due date.'**
  String get taskManagerFilteredDueEmpty;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @homeButtons.
  ///
  /// In en, this message translates to:
  /// **'Buttons at the top'**
  String get homeButtons;

  /// No description provided for @homeButtonsCount.
  ///
  /// In en, this message translates to:
  /// **'{shown} of {total} shown'**
  String homeButtonsCount(int shown, int total);

  /// No description provided for @homeButtonsHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose which buttons stay at the top of the home and drag them by the handle to change their order.'**
  String get homeButtonsHelp;

  /// No description provided for @homeButtonsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get homeButtonsReset;

  /// No description provided for @homeButtonPinnedHelp.
  ///
  /// In en, this message translates to:
  /// **'The notes pinned at the top, always within reach.'**
  String get homeButtonPinnedHelp;

  /// No description provided for @homeButtonGraphHelp.
  ///
  /// In en, this message translates to:
  /// **'Your notes as a map: notes sharing tags sit close together.'**
  String get homeButtonGraphHelp;

  /// No description provided for @homeButtonListsHelp.
  ///
  /// In en, this message translates to:
  /// **'Tasks and notes grouped by tag and by source.'**
  String get homeButtonListsHelp;

  /// No description provided for @homeButtonCalendarHelp.
  ///
  /// In en, this message translates to:
  /// **'Notes day by day, to find what happened and when.'**
  String get homeButtonCalendarHelp;

  /// No description provided for @homeButtonDiaryHelp.
  ///
  /// In en, this message translates to:
  /// **'One box per day to write about your day and turn it into notes.'**
  String get homeButtonDiaryHelp;

  /// No description provided for @homeButtonTaskManagerHelp.
  ///
  /// In en, this message translates to:
  /// **'Open tasks in order of priority, with their due dates.'**
  String get homeButtonTaskManagerHelp;

  /// No description provided for @homeButtonSettingsHelp.
  ///
  /// In en, this message translates to:
  /// **'Always last, so you can always come back here.'**
  String get homeButtonSettingsHelp;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
