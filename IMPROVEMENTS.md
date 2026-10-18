# Improvements: data safety and search speed

This round of work came out of a review of the app: what it does, how it
compares with similar note apps, and what current documentation recommends.
It covers six changes, each in its own commit on the `improvements` branch.
No feature was removed and the UI is unchanged.

## What changed and why

### 1. Atomic writes (`4f6d5fd`)

**Problem.** Notes, drafts, graph layout and settings were written with
`File.writeAsStringSync`, which truncates the file and then writes the new
content. If Android killed the app or storage filled up halfway, the note
was left truncated. A code comment claimed synchronous writes prevented
this, but they don't. The Dart docs make no atomicity promise.

**Change.** A new `writeFileAtomic` (`lib/data/atomic_write.dart`) writes
to a hidden `.<name>.tmp` file in the same folder, flushes it, then renames
it over the target. A reader always sees either the old file or the new
one. Temp files are ignored when loading notes or listing workspaces. All
five write sites use the helper.

**Tests.** `test/atomic_write_test.dart` checks creation, replacement,
cleanup after a failed rename, and that a leftover temp file isn't loaded
as a note.

### 2. Obsidian-compatible frontmatter (`40b7877`)

**Problem (reproduced).** Obsidian writes list properties as YAML block
lists:

```yaml
tags:
  - analisi
  - esame
```

Leviathan's line-based parser read this as `tags: []`. The first save from
Leviathan then **erased the tags from the file**. Properties Leviathan
doesn't know about (`aliases`, `cssclasses`, custom fields) were dropped on
save too. The README promised Obsidian compatibility, so this was a data
loss bug.

**Change.** The header parser groups each `key:` line with the indented or
`- ` lines below it. A known field with no inline value followed only by
`- item` lines becomes a list. Every line that belongs to an unknown
property, plus column-0 comments, is kept verbatim in
`Note.extraFrontmatter` and written back after the known fields. A
read-save-read round trip is stable. No new dependency was needed.

**Tests.** Block lists (indented and not), unquoted ISO dates, preservation
of unknown properties across edits, and preservation through `placed` and
`copyWith` on tasks.

### 3. Reload on resume, protect outside edits (`7f3b9fa`)

**Problem.** The README invites users to sync notes or edit them by hand,
but the app never re-read the folder while it was running. Edits made
elsewhere stayed invisible until a restart. Worse, saving a stale note from
Leviathan (editing it, checking a task, moving it in the task manager)
silently overwrote the outside edit.

**Change.**
- `NoteRepository` remembers the modification time of every file it read
  or wrote.
- `hasExternalChanges()` compares only names and modification times, so no
  file is read and the check is cheap.
- When the app returns to the foreground, the home reloads, but only if a
  file was added, removed or changed.
- If `save` finds that a file changed since Leviathan last saw it, it
  copies that version to the workspace trash before overwriting it, so
  nothing is lost.

**Tests.** Unit tests for change detection (modified, added and removed
files) and the trash copy. A widget test adds a note from "outside" while
the app is paused and checks it appears on resume. This test fails without
the change.

### 4. Continuous integration (`3cb6bca`)

**Problem.** The repository is public and has 160+ tests, but nothing ran
them automatically.

**Change.** `.github/workflows/ci.yml` runs `dart format` (check only),
`flutter analyze` and `flutter test` on every push to `master` and on every
pull request. It pins Flutter 3.47.7, the version used for development.
This is standard practice; I have no specific source to cite for it.

### 5. Faster search (`3f8369d`)

**Problem (measured).** Search runs inside `build()` on every keystroke,
and also on unrelated rebuilds such as a focus change. Each run lowercased
and de-accented the title, body and labels of every note. The old
`foldText` did this with `split('').map().join()`, one string per
character. It also built a snippet for every hit, even though the list only
shows a few rows.

**Change.**
- `foldText` makes a single pass over code units. Text with no accented
  letters is returned right after `toLowerCase()`.
- The folded fields of each note are cached in an `Expando` keyed on the
  `Note` object. Notes are immutable and every edit creates a new object,
  so an edited note can never be matched against stale text, and entries
  for deleted notes are garbage-collected.
- `SearchHit.snippet` is computed lazily, only when a row is shown.

Calendar search, the graph filter and the list searches also benefit,
because they share the same functions.

### 6. Cleanups (`3d7dfd5`)

- `foldText` now covers the common Latin accents beyond Italian (â ä å ç ê
  ë î ï ñ ô õ ö ø û ü ý ÿ). "Müller" is found by typing "muller", and the
  tag `Müller Façade` normalizes to `muller-facade` instead of
  `mller-faade`. Every mapping is one letter for one letter, so the
  highlight ranges still line up. Existing tags in files are not rewritten.
- The note file name slug reuses `foldText` instead of its own six-letter
  accent table.
- Removed `cupertino_icons`, which no code used.

## Before and after

All numbers come from a throwaway benchmark run with `flutter test` on the
development PC (Windows), not on the phone. The phone will be slower in
absolute terms, but the ratios should be similar. That last point is an
assumption, not a measurement.

| Metric | Before | After |
|---|---|---|
| Search, 3000 notes, no match (`perche amet zzz`) | ~180 ms | ~21 ms |
| Search, 3000 notes, every note matches (`citta`) | ~240 ms | ~1.8 ms |
| Search, tag filter only | ~8.7 ms | ~0.2 ms |
| First search (fills the cache) | ~235 ms | ~130 ms |
| Saving a note (2 KB) | 2.07 ms | 2.13 ms (temp file + flush) |
| Obsidian block-list tags read | `[]` (lost on save) | read and kept |
| Unknown frontmatter properties | dropped on save | kept verbatim |
| Outside edits while running | invisible; overwritten on save | reloaded on resume; overwritten version copied to trash |
| Tests | 153 | 167 |
| CI | none | format + analyze + test |

Loading 3000 notes took ~680 ms on the same PC and was not changed in this
round (see below).

## Sources

- Obsidian Help, [Properties](https://obsidian.md/help/properties):
  properties are YAML, lists are written as `- item` lines, custom
  properties are allowed, and JSON is accepted but saved back as YAML.
- Dart API,
  [`File.writeAsStringSync`](https://api.dart.dev/dart-io/File/writeAsStringSync.html):
  documents the `flush` option and gives no atomicity guarantee.
- Atomic write pattern (temp file in the same directory, flush, rename):
  [a3s-box-core `fs_atomic.rs`](https://docs.rs/crate/a3s-box-core/3.1.0/source/src/fs_atomic.rs)
  and [warlock.js "Write atomically"](https://warlock.js.org/v/latest/fs/guides/write-atomically/).
  I read these through search summaries only.
- Syncthing forum,
  [Obsidian notes modified on Android … destructively overwritten](https://forum.syncthing.net/t/obsidian-notes-modified-on-android-sometimes-not-updated-to-desktop-and-can-get-destructively-overwritten/21350):
  a real-world report of the overwrite problem that change 3 guards
  against.
- Flutter performance advice, mostly secondary sources: avoid expensive
  work in `build()` and profile before reaching for isolates.
  [Foresight Mobile](https://foresightmobile.com/blog/how-to-optimise-your-flutter-app),
  [Dev Genius](https://blog.devgenius.io/flutter-jank-you-cant-fix-with-isolates-and-what-actually-fixes-it-f636b3b0fe12).
- Android, [Receiving simple data](https://developer.android.com/training/sharing/receive)
  and [Manage all files](https://developer.android.com/training/data-storage/manage-all-files):
  used for the share-sheet plan and the storage decision below.
- Flutter, [Accessibility](https://docs.flutter.dev/ui/accessibility):
  48×48 tap targets, 4.5:1 contrast, `meetsGuideline` checks.
- Dependencies: [flutter_markdown_plus](https://pub.dev/packages/flutter_markdown_plus)
  is maintained and continues the discontinued `flutter_markdown`.
  [permission_handler](https://pub.dev/packages/permission_handler) 13.0.2
  is the latest version.
- Comparable apps: [Markor](https://f-droid.org/en/packages/net.gsantner.markor/),
  [Notesnook](https://f-droid.org/en/packages/com.streetwriters.notesnook/),
  [Google Keep trash](https://support.google.com/keep/answer/6262765) (7
  days), [Joplin trash](https://joplinapp.org/help/apps/trash/), and
  Obsidian File recovery (snapshots every 5 minutes, kept 7 days;
  [mirror of the official help page](https://huggingface.co/spaces/anpigon/obsidian-qa-bot/blob/e272fa2f2c33a981360ec7e29f42e93f75fd504f/docs/obsidian-help/Plugins/File%20recovery.md)).

## Not done yet, and ideas

- **Receive from the Android share sheet** (roadmap #2). This is the main
  missing capture path. The plan is an `ACTION_SEND` `text/plain` intent
  filter plus a small MethodChannel in `MainActivity`, with no package. The
  shared text opens in the editor for the user to confirm, as Android's
  guidance recommends.
- **Load notes off the UI thread.** Loading 3000 notes took ~680 ms
  synchronously on the PC. That isn't noticeable at today's note counts,
  but it will grow. The fix is `Isolate.run` plus a loading state in
  `NotesController`.
- **Accessibility checks.** Add `meetsGuideline` widget tests (tap targets,
  labels, contrast) for the main screens and fix what they find.
- **Conflict notice.** Change 3 keeps the overwritten outside edit in the
  trash, but it doesn't tell the user. One case is still uncovered: a note
  open in edit mode while the file changes outside and the app reloads. A
  snackbar, or comparing against the version the editor started from,
  would close the gap.
- **Trash screen with automatic emptying** (roadmap #5). Keep uses 7 days,
  Google's other apps 30.
- **Backup / export as zip** (roadmap #4).
- **Storage access.** I'm deliberately staying on "All files access".
  Google recommends the Storage Access Framework, but the app is
  sideloaded rather than on the Play Store, SAF is reported to be slow on
  large folders, and switching would mean rewriting the whole data layer
  around `dart:io`.
- **CI** hasn't run yet. It will on the first push of this branch.
