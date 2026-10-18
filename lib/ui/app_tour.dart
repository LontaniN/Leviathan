import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'theme.dart';

/// Un passo del tour: l'elemento da illuminare e cosa dirne.
typedef TourStep = ({GlobalKey target, String title, String body});

/// Tour guidato sopra una schermata: oscura tutto tranne un elemento alla
/// volta e accanto ne spiega l'uso in una scheda.
///
/// Segue lo schema classico dei tour delle app: pochi passi sulle funzioni
/// principali, un solo elemento illuminato per volta, l'avanzamento ("2 di
/// 5"), Indietro e Avanti, e Salta sempre visibile. Con [welcome] parte da
/// una scheda di benvenuto che chiede se fare il giro.
///
/// Mentre è aperto blocca i tocchi sulla schermata sotto. [onDone] arriva
/// sia alla fine sia saltando.
class AppTour extends StatefulWidget {
  const AppTour({
    super.key,
    required this.steps,
    required this.onDone,
    this.welcome,
  });

  final List<TourStep> steps;
  final VoidCallback onDone;

  /// Titolo e testo della scheda iniziale; null per partire dal primo passo.
  final ({String title, String body})? welcome;

  @override
  State<AppTour> createState() => _AppTourState();
}

class _AppTourState extends State<AppTour>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  /// Il passo mostrato; -1 è la scheda di benvenuto.
  late int _index = widget.welcome == null ? 0 : -1;

  /// Il riquadro dell'elemento illuminato, nelle coordinate del tour.
  Rect? _hole;

  /// Da dove parte il riquadro che si sposta verso [_hole].
  Rect? _holeFrom;

  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: LeviathanDurations.tourMove,
    value: 1,
  );

  /// Il riquadro a questo punto dello spostamento.
  Rect? get _shownHole => _HoleTween(
    begin: _holeFrom,
    end: _hole,
  ).transform(Curves.easeInOutCubic.transform(_move.value));

  final _overlayKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _measureLater();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _move.dispose();
    super.dispose();
  }

  /// Rotazione o tastiera: l'elemento può essersi spostato.
  @override
  void didChangeMetrics() => _measureLater();

  /// Misura al prossimo frame e di nuovo a animazioni finite: la schermata
  /// sotto può ancora assestarsi (es. la tastiera dell'onboarding che si
  /// chiude e la barra di ricerca che ricompare).
  void _measureLater() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    Future<void>.delayed(LeviathanDurations.tourMove, _measure);
  }

  /// Misura l'elemento del passo attuale rispetto al tour. Se non c'è (passo
  /// di benvenuto, elemento non a schermo) la scheda va al centro.
  void _measure() {
    if (!mounted) return;
    Rect? hole;
    final target = _index < 0
        ? null
        : widget.steps[_index].target.currentContext?.findRenderObject();
    final overlay = _overlayKey.currentContext?.findRenderObject();
    if (target is RenderBox &&
        overlay is RenderBox &&
        target.attached &&
        target.hasSize) {
      final topLeft = target.localToGlobal(Offset.zero, ancestor: overlay);
      // L'anello resta dentro lo schermo anche per gli elementi sul bordo.
      hole = (topLeft & target.size)
          .inflate(LeviathanSpacing.xs)
          .intersect(
            (Offset.zero & overlay.size).deflate(LeviathanSizes.outline),
          );
    }
    if (hole == _hole) return;
    setState(() {
      _holeFrom = _shownHole;
      _hole = hole;
    });
    _move.forward(from: 0);
  }

  void _go(int index) {
    if (index >= widget.steps.length) {
      widget.onDone();
      return;
    }
    setState(() => _index = index);
    _measureLater();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final last = _index == widget.steps.length - 1;
    final card = _index < 0
        ? _TourCard(
            key: const Key('tour-welcome'),
            title: widget.welcome!.title,
            body: widget.welcome!.body,
            actions: [
              TextButton(
                key: const Key('tour-skip'),
                onPressed: widget.onDone,
                child: Text(l.tourSkip),
              ),
              FilledButton(
                key: const Key('tour-start'),
                onPressed: () => _go(0),
                child: Text(l.tourStart),
              ),
            ],
          )
        : _TourCard(
            key: ValueKey('tour-step-$_index'),
            progress: l.tourProgress(_index + 1, widget.steps.length),
            title: widget.steps[_index].title,
            body: widget.steps[_index].body,
            // Salta resta sempre visibile in alto, fino all'ultimo passo dove
            // non serve più.
            skip: last
                ? null
                : TextButton(
                    key: const Key('tour-skip'),
                    onPressed: widget.onDone,
                    child: Text(l.tourSkip),
                  ),
            actions: [
              if (_index > 0)
                TextButton(
                  key: const Key('tour-back'),
                  onPressed: () => _go(_index - 1),
                  child: Text(l.tourBack),
                ),
              FilledButton(
                key: const Key('tour-next'),
                onPressed: () => _go(_index + 1),
                child: Text(last ? l.tourDone : l.tourNext),
              ),
            ],
          );
    // Il lettore di schermo legge solo il tour, non la schermata oscurata.
    return BlockSemantics(
      child: LayoutBuilder(
        key: _overlayKey,
        builder: (context, constraints) => Stack(
          children: [
            // Il velo prende tutti i tocchi: sotto non si tocca niente.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: AnimatedBuilder(
                  animation: _move,
                  builder: (context, _) => CustomPaint(
                    painter: _ScrimPainter(
                      hole: _shownHole,
                      scrim: Colors.black.withValues(
                        alpha: LeviathanOpacity.tourScrim,
                      ),
                      ring: context.palette.accent,
                    ),
                  ),
                ),
              ),
            ),
            _placeCard(constraints.biggest, card),
          ],
        ),
      ),
    );
  }

  /// La scheda va dalla parte dell'elemento dove c'è più spazio. Se
  /// l'elemento è così alto che non ci sta da nessuna parte, la scheda sta in
  /// fondo e lo copre in parte.
  Widget _placeCard(Size size, Widget card) {
    final padding = MediaQuery.paddingOf(context);
    const margin = LeviathanSpacing.lg;
    final hole = _hole;
    final animated = AnimatedSwitcher(
      duration: LeviathanDurations.quick,
      child: card,
    );
    Widget at({double? top, double? bottom}) => AnimatedPositioned(
      duration: LeviathanDurations.tourMove,
      curve: Curves.easeInOutCubic,
      left: margin,
      right: margin,
      top: top,
      bottom: bottom,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: LeviathanSizes.tourCardWidth,
          ),
          child: animated,
        ),
      ),
    );
    if (hole == null) {
      return Positioned.fill(
        child: Padding(
          padding: padding + const EdgeInsets.all(margin),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: LeviathanSizes.tourCardWidth,
              ),
              child: animated,
            ),
          ),
        ),
      );
    }
    final above = hole.top - padding.top;
    final below = size.height - padding.bottom - hole.bottom;
    if (below >= LeviathanSizes.tourCardRoom && below >= above) {
      return at(top: hole.bottom + margin);
    }
    if (above >= LeviathanSizes.tourCardRoom) {
      return at(bottom: size.height - hole.top + margin);
    }
    return at(bottom: padding.bottom + margin);
  }
}

/// La scheda del tour: avanzamento, titolo, testo e pulsanti.
class _TourCard extends StatelessWidget {
  const _TourCard({
    super.key,
    required this.title,
    required this.body,
    required this.actions,
    this.progress,
    this.skip,
  });

  final String title;
  final String body;
  final List<Widget> actions;

  /// "2 di 5", in alto a sinistra; accanto, a destra, il pulsante [skip].
  final String? progress;
  final Widget? skip;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      liveRegion: true,
      child: Material(
        color: palette.surfaceHigh,
        elevation: LeviathanSizes.tourCardElevation,
        borderRadius: BorderRadius.circular(LeviathanRadii.lg),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            LeviathanSpacing.xl,
            progress == null ? LeviathanSpacing.xl : LeviathanSpacing.xs,
            LeviathanSpacing.md,
            LeviathanSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (progress != null)
                SizedBox(
                  height: LeviathanSizes.button,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          progress!.toUpperCase(),
                          style: LeviathanText.caption.copyWith(
                            color: palette.muted,
                          ),
                        ),
                      ),
                      ?skip,
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: LeviathanSpacing.md),
                child: Text(
                  title,
                  style: LeviathanText.editorTitle.copyWith(
                    color: palette.text,
                  ),
                ),
              ),
              const SizedBox(height: LeviathanSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(right: LeviathanSpacing.md),
                child: Text(
                  body,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: palette.text),
                ),
              ),
              const SizedBox(height: LeviathanSpacing.md),
              // Se i pulsanti non ci stanno in fila vanno uno sotto l'altro.
              OverflowBar(
                alignment: MainAxisAlignment.end,
                overflowAlignment: OverflowBarAlignment.end,
                spacing: LeviathanSpacing.xs,
                overflowSpacing: LeviathanSpacing.xs,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Il riquadro illuminato che si sposta da un elemento all'altro. Al primo
/// elemento (dopo il benvenuto) si apre dal suo centro invece di arrivare
/// dall'angolo in alto.
class _HoleTween extends RectTween {
  _HoleTween({super.begin, super.end});

  @override
  Rect? lerp(double t) {
    final end = this.end;
    // Senza elemento il velo copre tutto.
    if (end == null) return null;
    final begin =
        this.begin ?? Rect.fromCenter(center: end.center, width: 0, height: 0);
    return Rect.lerp(begin, end, t);
  }
}

/// Il velo scuro con un buco arrotondato attorno all'elemento del passo, e
/// un anello sottile nel colore d'accento che lo contorna.
class _ScrimPainter extends CustomPainter {
  _ScrimPainter({required this.hole, required this.scrim, required this.ring});

  final Rect? hole;
  final Color scrim;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Path()..addRect(Offset.zero & size);
    final hole = this.hole;
    if (hole == null) {
      canvas.drawPath(screen, Paint()..color = scrim);
      return;
    }
    final rounded = RRect.fromRectAndRadius(
      hole,
      const Radius.circular(LeviathanRadii.md),
    );
    canvas.drawPath(
      Path.combine(PathOperation.difference, screen, Path()..addRRect(rounded)),
      Paint()..color = scrim,
    );
    canvas.drawRRect(
      rounded,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = LeviathanSizes.outline,
    );
  }

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.hole != hole || old.scrim != scrim || old.ring != ring;
}
