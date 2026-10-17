import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../model/demo_notes.dart';
import '../model/note.dart';
import '../model/tag_calendar.dart';
import '../model/tags.dart';
import '../state/notes_controller.dart';
import 'period_notes_screen.dart';
import 'theme.dart';

/// Come mostrare il calendario: una casella per giorno o per mese.
enum CalendarMode { days, months }

const _monthNames = [
  'gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno', //
  'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre',
];

const _weekdayInitials = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

String _capitalized(String s) => '${s[0].toUpperCase()}${s.substring(1)}';

/// Calendario a caselle: in ogni giorno (o mese) i tag più usati, con
/// accanto quante note li usano. Si scorre in su verso il passato e in giù
/// verso il futuro; si apre sul periodo corrente.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.notes});

  final NotesController notes;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarMode _mode = CalendarMode.days;

  /// Solo nelle build di sviluppo: mostra note finte al posto di quelle vere.
  bool _demo = kDebugMode;
  late final List<Note> _demoNotes = demoNotes(DateTime.now().year);

  void _showDetail(String title, TagTally tally, DateTime from, DateTime to) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: context.palette.surface,
      builder: (sheetContext) => _TallySheet(
        title: title,
        tally: tally,
        onShowNotes: () {
          Navigator.pop(sheetContext);
          _openNotes(title, from, to);
        },
      ),
    );
  }

  void _openNotes(String title, DateTime from, DateTime to) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PeriodNotesScreen(
          title: title,
          from: from,
          to: to,
          notes: widget.notes,
          demoNotes: _demo ? _demoNotes : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.notes,
      builder: (context, _) {
        final notes = _demo ? _demoNotes : widget.notes.notes;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: context.palette.background,
            title: const Text('Calendario'),
            actions: [
              if (kDebugMode)
                IconButton(
                  key: const Key('demo-toggle'),
                  tooltip: _demo ? 'Mostra le note vere' : 'Dati di prova',
                  isSelected: _demo,
                  icon: const Icon(Icons.science_outlined),
                  selectedIcon: Icon(
                    Icons.science,
                    color: context.palette.accent,
                  ),
                  onPressed: () => setState(() => _demo = !_demo),
                ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  LeviathanSpacing.lg,
                  0,
                  LeviathanSpacing.lg,
                  LeviathanSpacing.sm,
                ),
                child: SegmentedButton<CalendarMode>(
                  key: const Key('calendar-mode'),
                  segments: const [
                    ButtonSegment(
                      value: CalendarMode.days,
                      icon: Icon(
                        Icons.calendar_view_month,
                        size: LeviathanIconSize.sm,
                      ),
                      label: Text('Giornaliero'),
                    ),
                    ButtonSegment(
                      value: CalendarMode.months,
                      icon: Icon(
                        Icons.calendar_today_outlined,
                        size: LeviathanIconSize.sm,
                      ),
                      label: Text('Mensile'),
                    ),
                  ],
                  selected: {_mode},
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onSelectionChanged: (s) => setState(() => _mode = s.first),
                ),
              ),
              if (_demo)
                Padding(
                  padding: const EdgeInsets.only(bottom: LeviathanSpacing.xs),
                  child: Text(
                    'Dati di prova: non sono le tue note',
                    textAlign: TextAlign.center,
                    style: LeviathanText.meta.copyWith(
                      color: context.palette.accent,
                    ),
                  ),
                ),
              Expanded(
                child: notes.isEmpty
                    ? const _Empty(
                        'Nessuna nota ancora: il calendario si riempie man '
                        'mano che scrivi.',
                      )
                    : switch (_mode) {
                        CalendarMode.days => _DaysView(
                          key: ValueKey('days-$_demo'),
                          tallies: tallyByDay(notes),
                          onTap: _showDetail,
                        ),
                        CalendarMode.months => _MonthsView(
                          key: ValueKey('months-$_demo'),
                          tallies: tallyByMonth(notes),
                          onTap: _showDetail,
                        ),
                      },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// [from] incluso, [to] escluso: il periodo della casella toccata.
typedef _OnTapTally = void Function(
  String title,
  TagTally tally,
  DateTime from,
  DateTime to,
);

/// Lista che si apre su [current]: sopra i [past] elementi precedenti,
/// sotto [current] e i [future] successivi. [itemAt] riceve lo scarto da
/// [current] (negativo = passato).
class _CenteredList extends StatelessWidget {
  const _CenteredList({
    required this.past,
    required this.future,
    required this.itemAt,
  });

  final int past;
  final int future;
  final Widget Function(int offset) itemAt;

  static const _centerKey = ValueKey('current');

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      center: _centerKey,
      slivers: [
        SliverList.builder(
          itemCount: past,
          itemBuilder: (context, i) => itemAt(-(i + 1)),
        ),
        SliverList.builder(
          key: _centerKey,
          itemCount: future + 1,
          itemBuilder: (context, i) => itemAt(i),
        ),
        const SliverPadding(
          padding: EdgeInsets.only(bottom: LeviathanSpacing.xl),
        ),
      ],
    );
  }
}

/// Un mese per sezione, una casella per giorno.
class _DaysView extends StatelessWidget {
  const _DaysView({super.key, required this.tallies, required this.onTap});

  final Map<DateTime, TagTally> tallies;
  final _OnTapTally onTap;

  int _index(DateTime d) => d.year * 12 + d.month - 1;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final current = _index(now);
    final indexes = tallies.keys.map(_index);
    final first = indexes.fold(current, (a, b) => a < b ? a : b);
    final last = indexes.fold(current, (a, b) => a > b ? a : b);
    final today = DateTime(now.year, now.month, now.day);
    return _CenteredList(
      past: current - first,
      future: last - current,
      itemAt: (offset) {
        final month = DateTime(now.year, now.month + offset);
        return _MonthSection(
          month: month,
          today: today,
          tallies: tallies,
          onTap: onTap,
        );
      },
    );
  }
}

class _MonthSection extends StatelessWidget {
  const _MonthSection({
    required this.month,
    required this.today,
    required this.tallies,
    required this.onTap,
  });

  final DateTime month;
  final DateTime today;
  final Map<DateTime, TagTally> tallies;
  final _OnTapTally onTap;

  @override
  Widget build(BuildContext context) {
    final leading = month.weekday - DateTime.monday;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final weeks = ((leading + days) / 7).ceil();
    final name = '${_capitalized(_monthNames[month.month - 1])} ${month.year}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LeviathanSpacing.sm,
        LeviathanSpacing.lg,
        LeviathanSpacing.sm,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LeviathanSpacing.xs,
              vertical: LeviathanSpacing.xs,
            ),
            child: Text(name, style: LeviathanText.title),
          ),
          Row(
            children: [
              for (final initial in _weekdayInitials)
                Expanded(
                  child: Text(
                    initial,
                    textAlign: TextAlign.center,
                    style: LeviathanText.tiny.copyWith(
                      color: context.palette.muted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: LeviathanSpacing.xs),
          for (var week = 0; week < weeks; week++)
            Row(
              children: [
                for (var weekday = 0; weekday < 7; weekday++)
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: LeviathanSizes.calendarDayAspect,
                      child: _dayCell(
                        context,
                        week * 7 + weekday - leading + 1,
                        days,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _dayCell(BuildContext context, int day, int days) {
    if (day < 1 || day > days) return const SizedBox.shrink();
    final date = DateTime(month.year, month.month, day);
    final tally = tallies[date];
    final isToday = date == today;
    final palette = context.palette;
    return _Cell(
      highlighted: isToday,
      filled: tally != null,
      onTap: tally == null
          ? null
          : () => onTap(
              '$day ${_monthNames[month.month - 1]} ${month.year}',
              tally,
              date,
              DateTime(date.year, date.month, date.day + 1),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$day',
            style: LeviathanText.meta.copyWith(
              fontWeight: FontWeight.w600,
              color: isToday
                  ? palette.accent
                  : (tally == null ? palette.muted : palette.text),
            ),
          ),
          if (tally != null) Expanded(child: _TagLines(tally: tally)),
        ],
      ),
    );
  }
}

/// Un anno per sezione, una casella per mese.
class _MonthsView extends StatelessWidget {
  const _MonthsView({super.key, required this.tallies, required this.onTap});

  final Map<DateTime, TagTally> tallies;
  final _OnTapTally onTap;

  static const _columns = 3;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = tallies.keys.map((d) => d.year);
    final first = years.fold(now.year, (a, b) => a < b ? a : b);
    final last = years.fold(now.year, (a, b) => a > b ? a : b);
    return _CenteredList(
      past: now.year - first,
      future: last - now.year,
      itemAt: (offset) => _yearSection(context, now, now.year + offset),
    );
  }

  Widget _yearSection(BuildContext context, DateTime now, int year) {
    final total = [
      for (var m = 1; m <= 12; m++) tallies[DateTime(year, m)]?.notes ?? 0,
    ].fold(0, (a, b) => a + b);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LeviathanSpacing.sm,
        LeviathanSpacing.lg,
        LeviathanSpacing.sm,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(LeviathanSpacing.xs),
            child: Row(
              children: [
                Expanded(child: Text('$year', style: LeviathanText.title)),
                Text(
                  total == 1 ? '1 nota' : '$total note',
                  style: LeviathanText.meta.copyWith(
                    color: context.palette.muted,
                  ),
                ),
              ],
            ),
          ),
          for (var row = 0; row < 12 ~/ _columns; row++)
            Row(
              children: [
                for (var col = 0; col < _columns; col++)
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: LeviathanSizes.calendarMonthAspect,
                      child: _monthCell(
                        context,
                        now,
                        DateTime(year, row * _columns + col + 1),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _monthCell(BuildContext context, DateTime now, DateTime month) {
    final tally = tallies[month];
    final isCurrent = month.year == now.year && month.month == now.month;
    final palette = context.palette;
    final name = _capitalized(_monthNames[month.month - 1]);
    return _Cell(
      highlighted: isCurrent,
      filled: tally != null,
      onTap: tally == null
          ? null
          : () => onTap(
              '$name ${month.year}',
              tally,
              month,
              DateTime(month.year, month.month + 1),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LeviathanText.meta.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isCurrent
                        ? palette.accent
                        : (tally == null ? palette.muted : palette.text),
                  ),
                ),
              ),
              if (tally != null)
                Text(
                  '${tally.notes}',
                  style: LeviathanText.tiny.copyWith(color: palette.muted),
                ),
            ],
          ),
          const SizedBox(height: LeviathanSpacing.xxs),
          if (tally != null) Expanded(child: _TagLines(tally: tally)),
        ],
      ),
    );
  }
}

/// La casella: piena se nel periodo ci sono note, bordata se è oggi (o il
/// mese corrente).
class _Cell extends StatelessWidget {
  const _Cell({
    required this.highlighted,
    required this.filled,
    required this.onTap,
    required this.child,
  });

  final bool highlighted;
  final bool filled;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(LeviathanRadii.cell);
    return Padding(
      padding: const EdgeInsets.all(LeviathanSpacing.xxs),
      child: Material(
        color: filled ? palette.surface : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: highlighted
              ? BorderSide(color: palette.accent, width: LeviathanSizes.outline)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(LeviathanSpacing.xs),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// I tag più usati, uno per riga, quanti ne stanno nello spazio dato.
class _TagLines extends StatelessWidget {
  const _TagLines({required this.tally});

  final TagTally tally;

  @override
  Widget build(BuildContext context) {
    // Come fa Text: lo stile eredita quello di default (interlinea compresa),
    // altrimenti la riga misurata è più bassa di quella disegnata.
    final style = DefaultTextStyle.of(context).style.merge(LeviathanText.tiny);
    final painter = TextPainter(
      text: TextSpan(text: 'Ag', style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final lineHeight = painter.height;
    painter.dispose();
    return LayoutBuilder(
      builder: (context, constraints) {
        final fits = (constraints.maxHeight / lineHeight).floor();
        final tags = tally.ranked().take(fits);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final entry in tags)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: style.copyWith(color: Tags.colorOf(entry.key)),
                    ),
                  ),
                  const SizedBox(width: LeviathanSpacing.xxs),
                  Text(
                    '${entry.value}',
                    style: style.copyWith(color: context.palette.muted),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

/// Tutti i tag di un giorno o di un mese, toccandone la casella.
class _TallySheet extends StatelessWidget {
  const _TallySheet({
    required this.title,
    required this.tally,
    required this.onShowNotes,
  });

  final String title;
  final TagTally tally;
  final VoidCallback onShowNotes;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final ranked = tally.ranked();
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LeviathanSpacing.xl,
              ),
              child: Row(
                children: [
                  Expanded(child: Text(title, style: LeviathanText.title)),
                  Text(
                    tally.notes == 1 ? '1 nota' : '${tally.notes} note',
                    style: LeviathanText.meta.copyWith(color: palette.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: LeviathanSpacing.sm),
            Flexible(
              child: ranked.isEmpty
                  ? const _Empty('Le note di questo periodo non hanno tag.')
                  : ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(
                        bottom: LeviathanSpacing.lg,
                      ),
                      children: [
                        for (final entry in ranked)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: LeviathanSpacing.xl,
                              vertical: LeviathanSpacing.sm,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Tags.colorOf(entry.key),
                                  radius: LeviathanSpacing.xs,
                                ),
                                const SizedBox(width: LeviathanSpacing.md),
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge,
                                  ),
                                ),
                                Text(
                                  entry.value == 1
                                      ? '1 volta'
                                      : '${entry.value} volte',
                                  style: LeviathanText.meta.copyWith(
                                    color: palette.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LeviathanSpacing.xl,
                0,
                LeviathanSpacing.xl,
                LeviathanSpacing.lg,
              ),
              child: FilledButton.tonalIcon(
                key: const Key('show-period-notes'),
                onPressed: onShowNotes,
                icon: const Icon(Icons.notes),
                label: Text(
                  tally.notes == 1
                      ? 'Vedi la nota'
                      : 'Vedi le ${tally.notes} note',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LeviathanSpacing.xxl),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.palette.muted),
        ),
      ),
    );
  }
}
