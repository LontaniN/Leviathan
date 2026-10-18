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
  /// **'Your second brain.'**
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
