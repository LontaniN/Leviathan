/// Pezzi di testo che non spezzano un carattere a metà.
///
/// Le stringhe di Dart contano unità UTF-16: emoji e altri caratteri fuori
/// dal piano base ne occupano due (una coppia surrogata). Tagliando fra le
/// due resta mezzo carattere, e Flutter rifiuta di disegnare il testo
/// ("string is not well-formed UTF-16").
library;

bool _isHigh(int unit) => unit >= 0xD800 && unit <= 0xDBFF;
bool _isLow(int unit) => unit >= 0xDC00 && unit <= 0xDFFF;

/// Vero se in [text] la posizione [index] cade in mezzo a una coppia.
bool _splitsPair(String text, int index) =>
    index > 0 &&
    index < text.length &&
    _isLow(text.codeUnitAt(index)) &&
    _isHigh(text.codeUnitAt(index - 1));

/// Come `substring`, ma un bordo in mezzo a una coppia si sposta prima di
/// lei: l'inizio la include, la fine la lascia fuori.
String safeSubstring(String text, int start, [int? end]) {
  var from = start;
  var to = end ?? text.length;
  if (_splitsPair(text, from)) from--;
  if (_splitsPair(text, to)) to--;
  return text.substring(from, to < from ? from : to);
}
