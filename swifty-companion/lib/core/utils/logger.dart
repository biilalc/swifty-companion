// Tum uygulama icin tek bir logger instance'i. Debug'da verbose,
// release'de sadece warning ve uzerini yazar. Boylece production'da
// gereksiz log gurultusu olmaz ama hatalar yine de yakalanir.

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final Logger appLogger = Logger(
  filter: _AppLogFilter(),
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 8,
    lineLength: 100,
    colors: true,
    printEmojis: false,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);

/// Debug modunda tum seviyeler, release modunda sadece warning+ loglanir.
class _AppLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (kReleaseMode) {
      return event.level.index >= Level.warning.index;
    }
    return true;
  }
}
