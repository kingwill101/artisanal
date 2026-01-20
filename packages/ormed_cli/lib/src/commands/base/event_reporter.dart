import 'package:artisanal/artisanal.dart';
import 'package:ormed/ormed.dart';

/// Subscribes to core events and mirrors them to CLI output with animations.
class CliEventReporter {
  CliEventReporter({required Console io, EventBus? events})
    : _io = io,
      _events = events ?? EventBus.instance;

  final Console _io;
  final EventBus _events;
  final List<void Function()> _subscriptions = [];

  // Batch tracking state for progress display
  int _batchTotal = 0;
  int _batchCurrent = 0;
  Stopwatch? _migrationWatch;

  /// Listen for migration lifecycle events.
  void listenToMigrations() {
    _subscriptions
      ..add(_events.on<MigrationBatchStartedEvent>(_onMigrationBatchStarted))
      ..add(_events.on<MigrationStartedEvent>(_onMigrationStarted))
      ..add(_events.on<MigrationCompletedEvent>(_onMigrationCompleted))
      ..add(_events.on<MigrationFailedEvent>(_onMigrationFailed))
      ..add(
        _events.on<MigrationBatchCompletedEvent>(_onMigrationBatchCompleted),
      );
  }

  /// Listen for seeding lifecycle events.
  void listenToSeeders() {
    _subscriptions
      ..add(_events.on<SeedingStartedEvent>(_onSeedingStarted))
      ..add(_events.on<SeederStartedEvent>(_onSeederStarted))
      ..add(_events.on<SeederCompletedEvent>(_onSeederCompleted))
      ..add(_events.on<SeederFailedEvent>(_onSeederFailed))
      ..add(_events.on<SeedingCompletedEvent>(_onSeedingCompleted));
  }

  /// Remove all event listeners.
  void dispose() {
    for (final unsubscribe in _subscriptions) {
      unsubscribe();
    }
    _subscriptions.clear();
    _migrationWatch = null;
  }

  void _onMigrationBatchStarted(MigrationBatchStartedEvent event) {
    _batchTotal = event.count;
    _batchCurrent = 0;

    final action = event.direction == MigrationDirection.up
        ? 'Applying'
        : 'Rolling back';
    final batchText = event.batch != null ? ' (batch ${event.batch})' : '';

    _io.newLine();
    _io.writeln(
      _io.style.bold().render('$action ${event.count} migration(s)$batchText'),
    );
  }

  void _onMigrationStarted(MigrationStartedEvent event) {
    _batchCurrent = event.index;
    _migrationWatch = Stopwatch()..start();

    final direction = event.direction == MigrationDirection.up ? 'up' : 'down';
    final progress = _io.style
        .foreground(Colors.info)
        .render('[${event.index}/${event.total}]');
    final spinner = _io.style.foreground(Colors.info).render('...');

    _io.write(
      '  $progress ${_io.style.bold().render(event.migrationId)} ${_io.style.muted('($direction)')} $spinner',
    );
  }

  void _onMigrationCompleted(MigrationCompletedEvent event) {
    _migrationWatch?.stop();

    // Clear the current line and write the completed status
    final terminal = _io.promptTerminal;
    terminal.clearLine();

    final verb = event.direction == MigrationDirection.up
        ? 'Applied'
        : 'Rolled back';
    final progress = _io.style
        .foreground(Colors.success)
        .render('[$_batchCurrent/$_batchTotal]');
    final check = _io.style.foreground(Colors.success).render('✓');
    final duration = _io.style.muted('(${_formatDuration(event.duration)})');

    _io.writeln(
      '  $progress $check $verb ${_io.style.bold().render(event.migrationId)} $duration',
    );
  }

  void _onMigrationFailed(MigrationFailedEvent event) {
    _migrationWatch?.stop();

    // Clear the current line and write the error status
    final terminal = _io.promptTerminal;
    terminal.clearLine();

    final progress = _io.style
        .foreground(Colors.error)
        .render('[$_batchCurrent/$_batchTotal]');
    final cross = _io.style.foreground(Colors.error).render('✗');

    _io.writeln(
      '  $progress $cross ${_io.style.bold().render(event.migrationId)} ${_io.style.foreground(Colors.error).render('failed')}',
    );
    _io.error('  ${event.error}');
  }

  void _onMigrationBatchCompleted(MigrationBatchCompletedEvent event) {
    final verb = event.direction == MigrationDirection.up
        ? 'Applied'
        : 'Rolled back';

    _io.newLine();
    _io.success(
      '$verb ${event.count} migration(s) in ${_formatDuration(event.duration)}',
    );

    // Reset batch state
    _batchTotal = 0;
    _batchCurrent = 0;
  }

  void _onSeedingStarted(SeedingStartedEvent event) {
    _batchTotal = event.seederNames.length;
    _batchCurrent = 0;

    _io.newLine();
    _io.writeln(_io.style.bold().render('Seeding database'));
  }

  void _onSeederStarted(SeederStartedEvent event) {
    _batchCurrent = event.index;
    _migrationWatch = Stopwatch()..start();

    final progress = _io.style
        .foreground(Colors.info)
        .render('[${event.index}/${event.total}]');
    final spinner = _io.style.foreground(Colors.info).render('...');

    _io.write(
      '  $progress ${_io.style.bold().render(event.seederName)} $spinner',
    );
  }

  void _onSeederCompleted(SeederCompletedEvent event) {
    _migrationWatch?.stop();

    // Clear the current line and write the completed status
    final terminal = _io.promptTerminal;
    terminal.clearLine();

    final progress = _io.style
        .foreground(Colors.success)
        .render('[$_batchCurrent/$_batchTotal]');
    final check = _io.style.foreground(Colors.success).render('✓');
    final duration = _io.style.muted('(${_formatDuration(event.duration)})');
    final recordsSuffix = event.recordsCreated != null
        ? _io.style.muted(' +${event.recordsCreated} records')
        : '';

    _io.writeln(
      '  $progress $check Seeded ${_io.style.bold().render(event.seederName)} $duration$recordsSuffix',
    );
  }

  void _onSeederFailed(SeederFailedEvent event) {
    _migrationWatch?.stop();

    // Clear the current line and write the error status
    final terminal = _io.promptTerminal;
    terminal.clearLine();

    final progress = _io.style
        .foreground(Colors.error)
        .render('[$_batchCurrent/$_batchTotal]');
    final cross = _io.style.foreground(Colors.error).render('✗');

    _io.writeln(
      '  $progress $cross ${_io.style.bold().render(event.seederName)} ${_io.style.foreground(Colors.error).render('failed')}',
    );
    _io.error('  ${event.error}');
  }

  void _onSeedingCompleted(SeedingCompletedEvent event) {
    _io.newLine();
    _io.success(
      'Seeded ${event.count} seeder(s) in ${_formatDuration(event.duration)}',
    );

    // Reset state
    _batchTotal = 0;
    _batchCurrent = 0;
  }

  String _formatDuration(Duration duration) {
    final ms = duration.inMilliseconds;
    if (ms < 1000) {
      return '${ms}ms';
    }
    final seconds = (ms / 1000).toStringAsFixed(2);
    return '${seconds}s';
  }
}
