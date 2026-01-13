// ignore_for_file: unused_local_variable

import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';

/// This example demonstrates Carbon integration with Ormed.
///
/// Carbon is a date/time library ported from PHP's Carbon. It provides two
/// variants:
/// - **Carbon** (mutable): Methods like `subDay()` modify the instance in-place
/// - **CarbonImmutable**: Methods return new instances, leaving the original unchanged
///
/// ## Important: Ormed returns immutable timestamps
///
/// All timestamp getters (`createdAt`, `updatedAt`, `deletedAt`) return
/// **immutable** Carbon instances. This prevents accidental mutation of model
/// state when chaining date methods.
///
/// Carbon is automatically configured when you call `DataSource.init()`.
/// No manual configuration is required unless you want to override the defaults.
void main() async {
  // Example 1: Basic setup (UTC, no named timezones)
  await example1BasicSetup();

  // Example 2: Named timezone support
  await example2NamedTimezones();

  // Example 3: Custom locale
  await example3CustomLocale();

  // Example 4: Manual configuration override
  await example4ManualOverride();

  // Example 5: Mutable vs Immutable Carbon behavior
  example5MutableVsImmutable();

  // Example 6: Safe timestamp manipulation
  example6SafeTimestampManipulation();
}

/// Example 1: Basic automatic configuration
///
/// Carbon is automatically configured with UTC timezone.
/// Named timezones are not available, but UTC and fixed offsets work.
Future<void> example1BasicSetup() async {
  print('\n=== Example 1: Basic Setup ===');

  final ds = DataSource(
    DataSourceOptions(
      driver: InMemoryQueryExecutor(),
      entities: [PostOrmDefinition.definition], // Add your model definitions here
      // Carbon uses defaults: UTC, en_US, no named timezones
    ),
  );

  await ds.init(); // Carbon automatically configured here

  // Create a Carbon instance
  final now = CarbonConfig.createCarbon();
  print('Current time (UTC): ${now.format('yyyy-MM-dd HH:mm:ss z')}');
  print('Is UTC: ${now.isUtc}');

  await ds.dispose();
}

/// Example 2: Named timezone support
///
/// Enable named timezones like 'America/New_York', 'Europe/London', etc.
Future<void> example2NamedTimezones() async {
  print('\n=== Example 2: Named Timezone Support ===');

  // Reset Carbon to demonstrate fresh configuration
  CarbonConfig.reset();

  
  final ds = DataSource(
    DataSourceOptions(
      driver: InMemoryQueryExecutor (),
      entities: [PostOrmDefinition.definition],
      carbonTimezone: 'America/New_York',
      enableNamedTimezones: true, // Enable TimeMachine
    ),
  );

  await ds.init(); // Carbon + TimeMachine automatically configured

  // Now named timezones work
  final utcTime = CarbonConfig.createCarbon(timezone: 'UTC');
  final nyTime = utcTime.tz('America/New_York');
  final londonTime = utcTime.tz('Europe/London');

  print('UTC:        ${utcTime.format('yyyy-MM-dd HH:mm z')}');
  print('New York:   ${nyTime.format('yyyy-MM-dd HH:mm z')}');
  print('London:     ${londonTime.format('yyyy-MM-dd HH:mm z')}');

  await ds.dispose();
}

/// Example 3: Custom locale
///
/// Configure Carbon with a different locale for date formatting.
Future<void> example3CustomLocale() async {
  print('\n=== Example 3: Custom Locale ===');

  CarbonConfig.reset();

  
  final ds = DataSource(
    DataSourceOptions(
      driver: InMemoryQueryExecutor(),
      entities: [PostOrmDefinition.definition],
      carbonTimezone: 'UTC',
      carbonLocale: 'fr_FR', // French locale
    ),
  );

  await ds.init();

  final date = CarbonConfig.createCarbon(
    dateTime: DateTime(2024, 12, 25, 10, 30),
  );

  print('English:  ${date.locale('en_US').format('LLLL')}');
  print('French:   ${date.locale('fr_FR').format('LLLL')}');
  print('Spanish:  ${date.locale('es_ES').format('LLLL')}');
  print('Japanese: ${date.locale('ja_JP').format('LLLL')}');

  await ds.dispose();
}

/// Example 4: Manual configuration override
///
/// You can manually configure Carbon before initializing DataSource.
/// Manual configuration takes precedence.
Future<void> example4ManualOverride() async {
  print('\n=== Example 4: Manual Override ===');

  CarbonConfig.reset();

  // Manual configuration BEFORE DataSource.init()
  await CarbonConfig.configureWithTimeMachine(
    defaultTimezone: 'Asia/Tokyo',
    defaultLocale: 'ja_JP',
  );

  
  final ds = DataSource(
    DataSourceOptions(
      driver: InMemoryQueryExecutor(),
      entities: [PostOrmDefinition.definition],
      carbonTimezone: 'America/New_York', // This will be ignored
      carbonLocale: 'en_US', // This will be ignored
      enableNamedTimezones: true,
    ),
  );

  await ds.init(); // Uses manual configuration, not DataSourceOptions

  // Verify manual configuration was used
  print('Default timezone: ${CarbonConfig.defaultTimezone}'); // Asia/Tokyo
  print('Default locale:   ${CarbonConfig.defaultLocale}'); // ja_JP

  final now = CarbonConfig.createCarbon();
  print('Current time: ${now.format('yyyy-MM-dd HH:mm z')}'); // In Tokyo

  await ds.dispose();
}

// #region mutable-vs-immutable
/// Example 5: Mutable vs Immutable Carbon behavior
///
/// Understanding the difference between Carbon (mutable) and CarbonImmutable
/// is crucial to avoid unexpected bugs.
void example5MutableVsImmutable() {
  print('\n=== Example 5: Mutable vs Immutable ===');

  // MUTABLE Carbon: Methods modify the instance IN-PLACE
  final mutableDate = Carbon.parse('2024-12-21');
  print('Original mutable:   ${mutableDate.toDateString()}'); // 2024-12-21

  final result = mutableDate.subDay(); // Returns SAME instance, mutated!
  print('After subDay():     ${mutableDate.toDateString()}'); // 2024-12-20 ⚠️
  print('Same object?        ${identical(mutableDate, result)}'); // true

  // IMMUTABLE Carbon: Methods return NEW instances
  final immutableDate = CarbonImmutable.parse('2024-12-21');
  print('\nOriginal immutable: ${immutableDate.toDateString()}'); // 2024-12-21

  final newDate = immutableDate.subDay(); // Returns NEW instance
  print('After subDay():     ${immutableDate.toDateString()}'); // 2024-12-21 ✓
  print('New date:           ${newDate.toDateString()}'); // 2024-12-20
  print('Same object?        ${identical(immutableDate, newDate)}'); // false
}
// #endregion mutable-vs-immutable

// #region safe-timestamp-usage
/// Example 6: Safe timestamp manipulation
///
/// Ormed returns immutable Carbon instances from timestamp getters,
/// so you can safely chain methods without corrupting model state.
void example6SafeTimestampManipulation() {
  print('\n=== Example 6: Safe Timestamp Usage ===');

  // Simulating what Ormed does internally for timestamps
  final storedDateTime = DateTime(2024, 12, 21, 10, 30);

  // Ormed's timestamp getters return immutable instances:
  CarbonInterface getCreatedAt() {
    return Carbon.fromDateTime(storedDateTime).toImmutable();
  }

  final createdAt = getCreatedAt();
  print('createdAt: ${createdAt.toDateTimeString()}');

  // Safe to chain methods - original is unchanged
  final yesterday = createdAt.subDay();
  final nextWeek = createdAt.addWeek();

  print('yesterday: ${yesterday.toDateTimeString()}');
  print('nextWeek:  ${nextWeek.toDateTimeString()}');
  print('createdAt still: ${createdAt.toDateTimeString()}'); // Unchanged ✓

  // Common patterns
  final isRecent = createdAt.isAfter(Carbon.now().subDays(7));
  final humanReadable = createdAt.diffForHumans();
  print('Is recent (< 7 days): $isRecent');
  print('Human readable: $humanReadable');
}
// #endregion safe-timestamp-usage

// #region carbon-gotchas
/// Common Carbon gotchas to avoid
void carbonGotchas() {
  // ❌ WRONG: Don't store mutable Carbon and mutate it
  final date = Carbon.now();
  someFunction(date);
  print(date); // Value may have changed!

  // ✓ CORRECT: Use immutable or create copies
  final safeDate = Carbon.now().toImmutable();
  someFunction(safeDate);
  print(safeDate); // Guaranteed unchanged

  // ✓ CORRECT: Create a copy before mutating
  final original = Carbon.now();
  final copy = original.copy();
  copy.subDay(); // Only copy is mutated
}

void someFunction(CarbonInterface date) {
  // This would mutate mutable Carbon!
  date.addDays(5);
}
// #endregion carbon-gotchas

/// Example DataSource adapter (in-memory for examples)
extension SqliteDriverAdapter on Object {
  static DriverAdapter inMemory() {
    // This is a placeholder - in real code you'd use the actual adapter
    throw UnimplementedError('Use actual SqliteDriverAdapter.inMemory()');
  }
}
