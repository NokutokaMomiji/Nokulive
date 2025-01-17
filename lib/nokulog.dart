// My own little logger thingy built on top of the logger package.
import 'package:logger/logger.dart';

/// The modes the logger can be set to which dictate which information will actually be logged.
enum NokulogMode {
    base,
    all,
    errors,
    onlyErrors,
    off
}

// The type of event that was logged.
enum NokulogEventType {
    debug,
    info,
    warning,
    error,
    trace
}

/// Custom [LogFilter] to make the aforementioned modes work.
class ErrorFilter extends LogFilter {
    @override
    bool shouldLog(LogEvent event) {
        switch (Nokulog.mode) {
            case NokulogMode.base:

            var shouldLog = false;
            assert(() {
                if (event.level.value >= level!.value) {
                    shouldLog = true;
                }
                return true;
            }());

            if (event.level.value >= Level.warning.value && event.level.value != Level.off.value) {
                return true;
            }

            return shouldLog;
        
            case NokulogMode.all:
            return true;
            
            case NokulogMode.errors:
            if (event.level.value >= Level.warning.value && event.level.value != Level.off.value) {
                return true;
            }
            break;

            case NokulogMode.onlyErrors:
            return (event.level.value == Level.error.value);

            case NokulogMode.off:
            return false;
        }

        return false;
    }
}

/// Wrapper around a log event.
class NokulogEvent {
    final NokulogEventType eventType;
    final dynamic message;
    final DateTime time;
    final Object? error;
    final StackTrace stackTrace;

    NokulogEvent(this.eventType, this.message, {DateTime? time, this.error, StackTrace? stackTrace}) : time = DateTime.now(), stackTrace = StackTrace.current;

}

/// A little wrapper around SourceHorizon's [Logger].
class Nokulog {
    static NokulogMode mode = NokulogMode.base; 

    static final List<NokulogEvent> log = [];

    static final Logger _logger = Logger(
        filter: ErrorFilter(),
        printer: PrettyPrinter()
    );

    static void d(dynamic message, {DateTime? time, Object? error, StackTrace? stackTrace}) {
        _logger.d(message, time: time, error: error, stackTrace: stackTrace);

        if (mode == NokulogMode.errors || mode == NokulogMode.off) return;

        log.add(
            NokulogEvent(
                NokulogEventType.debug,
                message,
                time: time,
                error: error,
                stackTrace: stackTrace
            )
        );
    }

    static void i(dynamic message, {DateTime? time, Object? error, StackTrace? stackTrace}) {
        _logger.i(message, time: time, error: error, stackTrace: stackTrace);

        if (mode == NokulogMode.errors || mode == NokulogMode.off) return;

        log.add(
            NokulogEvent(
                NokulogEventType.info,
                message,
                time: time,
                error: error,
                stackTrace: stackTrace
            )
        );
    }

    static void w(dynamic message, {DateTime? time, Object? error, StackTrace? stackTrace}) {
        _logger.w(message, time: time, error: error, stackTrace: stackTrace);

        if (mode == NokulogMode.off) return;

        log.add(
            NokulogEvent(
                NokulogEventType.warning,
                message,
                time: time,
                error: error,
                stackTrace: stackTrace
            )
        );
    }

    static void e(dynamic message, {DateTime? time, Object? error, StackTrace? stackTrace}) {
        _logger.e(message, time: time, error: error, stackTrace: stackTrace);

        if (mode == NokulogMode.off) return;

        log.add(
            NokulogEvent(
                NokulogEventType.error,
                message,
                time: time,
                error: error,
                stackTrace: stackTrace
            )
        );
    }

    static void t(dynamic message, {DateTime? time, Object? error, StackTrace? stackTrace}) {
        _logger.t(message, time: time, error: error, stackTrace: stackTrace);

        if (mode == NokulogMode.off) return;
        
        log.add(
            NokulogEvent(
                NokulogEventType.trace,
                message,
                time: time,
                error: error,
                stackTrace: stackTrace
            )
        );
    }
}