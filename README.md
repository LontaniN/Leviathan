# Leviathan

A personal "second brain" for Android: notes, tasks and study notes
organized with tags, stored as plain Markdown files on the phone.

Leviathan is meant to be simple and predictable: no AI, no cloud, no
accounts. Notes are `.md` files in a folder on the phone, readable by any
editor (Obsidian included).

Built with Flutter, developed and tested on a Pixel 9a. The interface is
available in English and Italian.

---

## Features

### Workspaces

- Each **workspace** is a separate collection of notes (e.g. "University",
  "Personal"). On first launch you name the first one.
- The app reopens the last workspace you used.
- Tapping the workspace name at the top lets you switch to another one,
  create a new one, rename or delete it.
- Deleting a workspace never erases anything: notes, trash and drafts are
  moved to `.leviathan/deleted/`.

### Home: writing and finding recent notes

- **Recent notes on the left**, newest first, grouped by day or month. Each
  note has a small bar in the color of its first tag.
- The **arrow** at the top of the column expands it to full width, showing
  a preview, tags and date for each note.
- **The editor on the right** for a new note: large title and body, with
  tags and sources below. While typing with the keyboard open, the secondary
  fields slide away to leave room for the text.
- The note you just saved briefly glows in the list instead of showing a
  toast.
- **Automatic draft**: whatever you're writing is kept aside; if Android
  kills the app, the text is still there when you reopen it.
- **Resume where you left off**: changes to a saved note are kept aside
  too, with the cursor position, until you save or leave the page. If
  Android closes the app halfway through, the home shows "You were editing
  …": *Resume* reopens the editor with your changes and the cursor where it
  was, ✕ discards them. Getting back into an interrupted task is costly;
  a cue to where you were makes it quicker.
- **Share from other apps**: pick Leviathan in Android's *Share* menu and the
  text lands in the editor as a **quote** (`> `), with the cursor on an empty
  line above it: write what it means to you in your own words, which you'll
  remember better than a copy. Blank lines left above the quote are dropped
  when you save. The subject (e.g. a page title) becomes the title; if you
  were halfway through a note, the quote is added at the end instead and the
  cursor stays after your text. With more than one workspace you choose
  where it goes.
- Long-pressing a note in the list: pin it to the top, check off the task,
  move it to the trash.
- The first time you open a workspace, a short **guided tour** walks you
  through the editor, tags, the note list, search, the task manager and the
  other views. You can skip it at any time and replay it from the settings.

### Tags and sources

- **Tags** are the main way to organize notes. Unlimited per note, with
  **autocomplete** on tags already in use (tolerant of case, accents and
  small typos). They are normalized: `Machine Learning` → `machine-learning`.
- Each tag has a **stable color**; a note takes the color of its first tag,
  everywhere in the app and in the graph.
- **Sources** are a second way to categorize, usually people ("who told me
  this"). They keep capitalization and spaces (`Mario Rossi`) and have no
  color.
- Tags and sources sit in a horizontally scrolling row: the chosen ones
  first, then suggestions (the most used, or the closest to what you type).

### Notes and tasks

- A toggle in the editor turns a note into a **task** to check off; tags and
  sources stay. In the reading view a single button turns a note into a task
  and back.
- A task can have a **next step**: one concrete line under the title on
  when, where and how to start ("after lunch, at the library: read chapter
  3"). Writing down when and where you'll do something makes it more likely
  to happen and stops it nagging at you. It shows in the task manager and in
  the reading view, where a tap changes it, and search finds it too.
- The **light bulb** next to the Note/Task switch marks a note as
  **knowledge**: what you know, not what happened. Knowledge notes have their
  own view in Tasks and notes.
- The **calendar button** next to *Save note* dates a note to any day, handy
  for notes copied from elsewhere; editing a note can move it to another day.
- Completed tasks are shown struck through and dimmed, with the date they
  were done.
- **Full-screen reading**: tapping a note opens it with its first tag as a
  kicker above the title; from there you can edit, pin, copy the text or
  move it to the trash. Tapping a tag or source opens its own screen.

### Markdown

- The body is Markdown: headings, bold, italic, lists, quotes, code.
- A **formatting bar** above the keyboard inserts the syntax; pressing enter
  in a list continues it.
- **Checklists** `- [ ]` can be checked directly while reading.

### Search

- Discord-style search: free text plus filters, combined with AND.
  - `tag:` or `#` → filter by tag
  - `from:` or `@` → filter by source (may contain spaces:
    `from:Mario Rossi`)
  - `status:open` / `status:done` / `status:task` → open tasks / done tasks /
    all tasks
  - Typing `tag:` or `from:` lists every matching tag or source, most used
    first.
  - The Italian keywords (`da:`, `stato:aperto`, `stato:fatto`) work too,
    whatever the interface language.
- Searches title, body, tags and sources, ignoring case and accents. Title
  matches rank higher; ties go to the most recent note.
- Matching words are highlighted in the snippet.
- With an empty query it shows the notes you **opened recently** (often
  the very ones you're looking for, one tap away), then the most used tags
  and sources, which become filters with a tap.

### Tasks and notes by tag or source

- One screen with all **tasks**, all **notes** or all **knowledge notes**,
  grouped **by tag** or **by source**: one tile per group, with a count and
  the most recent titles.
- For tasks you can show all of them, only open ones or only completed ones;
  the view opens on "To do".
- Tapping a tile opens the list for that tag or source. Its search bar
  searches only the open list, respecting the current filter.

### Task manager

- Opened from the button to the right of the calendar on the home screen, it
  orders all open tasks **by priority**, regardless of tags and sources.
- Three bands, **Now**, **Next** and **Later**, ordered with drag and drop:
  priority is the position, not a label. Now suggests a limit of 3.
- New tasks land in **To sort**: answer a few "Which comes first?" questions
  and they slot into the right place.
- **Empty your head**: the button at the top opens a page where you write
  everything on your mind, one thing per line (list dashes and checkboxes
  are ignored). Each line becomes a task in To sort, with the tags you pick
  below; you order them later. Unfinished things keep coming back to mind
  until they have a place, so getting them all down at once frees your
  attention.
- Completed tasks have their own tab, newest first. Each row shows the color
  of its first tag, and open tasks show their next step under the title.
- The app bar filters by tag or source, showing how many open tasks each one
  has. The filtered view keeps the same bands and order but is read-only; a
  banner shows the active filter and lets you clear it.

### Calendar

- One cell per day (or per month) showing the **most used tags** in that
  period and how many notes use them.
- Scrolls toward the past and the future; tapping a cell shows all its tags
  and the notes written in that period.
- The magnifier searches the calendar: only days with matching notes remain,
  each with a preview of the matching text.

### Graph

- Each **note is a node**, colored by its first tag; notes sharing tags are
  linked and cluster together (the more tags in common, the stronger the
  pull). Tags are not nodes and sources don't create links.
- Pinch to zoom, drag to pan or move a node. One tap selects a note, a
  second tap opens it.
- Filters by tag and source; completed tasks are faded.
- Node positions are saved. The simulation (d3-force style, with
  Barnes-Hut) stops on its own once the graph settles, to save battery.

### Pinned notes

- Frequently used notes can be pinned to the top of the recent list.
- A dedicated screen collects them all, with "Undo" if you unpin one by
  mistake.

### Trash

- Deleted notes are never erased: they go to
  `.leviathan/trash/<workspace>/`, and the snackbar lets you undo.

### Language and appearance

- **English or Italian**: chosen from a drop-down menu on first launch
  (pre-selected from the phone's language) and changeable any time in the
  settings.
- Several **palettes** to choose from in the settings, each with a preview
  of the home screen: Ink (the default, pure black for OLED screens), Sepia,
  Slate, Graphite, Abyss, Ember, Moss, Amethyst and the light Paper.

---

## Workflow

### 1. Capture

On first launch, pick the language and name your first workspace. Then open
the app and write straight into the home editor: a title (or just the
body), then **tags** and, if useful, a **source**. If it's something to do,
pick **Task** at the top of the editor. Hit *Save* and the note appears at
the top of the recent list.

If you get interrupted, the draft is still there when you come back.

From another app (a browser, a chat, a PDF reader) use **Share →
Leviathan**: the text opens in the editor as a quote; add a line of your
own above it, then tags.

### 2. Organize

There are no folders and no links between notes: **everything goes through
tags**. Reusing the tags suggested by autocomplete keeps similar notes in the
same group, with the same color and close together in the graph. Sources
help you remember who or where a piece of information came from.

Notes you come back to often can be **pinned** to the top.

### 3. Find

The main way in is **search**: a few words, optionally with `#tag`,
`@source` or `status:open` to narrow it down. Alternatively:

- **Tasks and notes** to browse a whole tag, or everything from one person;
- the **calendar** to find a note by remembering *when* you wrote it;
- the **graph** to see how topics cluster.

### 4. Prioritize and complete tasks

The **task manager** is where you decide what comes next: sort new tasks
with a few quick comparisons, then drag them between Now, Next and Later.
Tasks can be checked off from there, the list, the reading view or search
results. The Tasks screen shows how many are still open for each tag;
`status:done` finds what you've already done.

### 5. Your data

Each workspace is a folder and each note a Markdown file with a frontmatter
header:

```
Documents/LeviathanNotes/
├── University/
│   ├── 20261017-140512-limiti-notevoli.md
│   └── …
├── Personal/
└── .leviathan/          ← trash, drafts, graph layout, recent notes, settings
```

```markdown
---
title: "Limiti notevoli"
tags: ["analisi", "esame"]
sources: ["Prof. Rossi"]
created: "2026-10-17T14:05:12.000"
updated: "2026-10-17T14:05:12.000"
---
Note body in **Markdown**…
```

Tasks also have `type: "task"`, `done` and `done_at`, plus `priority`
(`now`, `next` or `later`) and `rank` once placed in the task manager, and
`next_step` when they have one;
knowledge notes have `knowledge: true` and pinned notes `pinned: true`. Files can be copied, synced or edited by hand: Leviathan
also reads files written without a header, understands the YAML lists
Obsidian writes (`tags:` followed by `  - tag` lines) and keeps any property
it doesn't use (`aliases`, custom fields) untouched when it saves a note.

---

## Building and development

Requires [Flutter](https://docs.flutter.dev/get-started/install) (Dart SDK
`^3.13`).

```bash
flutter pub get
flutter run
```

On Android the app asks for the **"All files access"** permission: it's
needed to store notes in `Documents/LeviathanNotes`, where they survive
uninstalling the app. On Windows notes live in `Documents/LeviathanNotes`
and no permission is needed.

```bash
flutter test
```

Code comments are in Italian. Interface text lives in ARB files, one per
language (`lib/l10n/app_en.arb` is the template); the Dart classes are
generated by `flutter gen-l10n`, which also runs on `flutter pub get`. To add
a language, add `app_<code>.arb` with the same keys and list it in
`appLanguages` in `lib/l10n/l10n.dart`.

Project layout:

| Folder        | Contents                                                   |
|---------------|------------------------------------------------------------|
| `lib/l10n`    | Interface text: `app_en.arb`, `app_it.arb` (gen-l10n)       |
| `lib/model`   | Notes, tags, search, Markdown, calendar, graph, task order (pure logic) |
| `lib/data`    | Reading and writing notes, workspaces, drafts, graph layout |
| `lib/state`   | App state and preferences                                  |
| `lib/graph`   | Physics simulation and graph rendering                     |
| `lib/ui`      | Screens and widgets; all visual values live in `theme.dart` |
| `test`        | Unit and widget tests                                      |

Planned features (backup and export, tag management, …) are listed in
[ROADMAP.md](ROADMAP.md) (in Italian).
