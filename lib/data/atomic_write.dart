import 'dart:io';

import 'package:path/path.dart' as p;

/// Scrive [contents] in [file] senza mai lasciarlo a metà.
///
/// `writeAsStringSync` svuota il file e poi lo riscrive: se l'app viene
/// chiusa o la memoria si riempie nel mezzo, il file resta troncato. Qui si
/// scrive invece un file temporaneo accanto (stessa cartella, così il rename
/// non cambia file system), lo si porta su disco con `flush` e solo allora
/// lo si rinomina sopra l'originale: chi legge trova la versione vecchia o
/// quella nuova, mai un pezzo.
///
/// Il temporaneo comincia con un punto e finisce in `.tmp`, così né le note
/// (`.md`) né i workspace (cartelle) lo scambiano per qualcosa di loro.
void writeFileAtomic(File file, String contents) {
  file.parent.createSync(recursive: true);
  final temp = File(p.join(file.parent.path, '.${p.basename(file.path)}.tmp'));
  try {
    temp.writeAsStringSync(contents, flush: true);
    temp.renameSync(file.path);
  } on Object {
    if (temp.existsSync()) temp.deleteSync();
    rethrow;
  }
}
