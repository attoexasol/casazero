import 'dart:io';

import 'package:casazero/core/logging/diagnostic_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late DiagnosticLogger logger;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('casazero_diag_');
    logger = DiagnosticLogger.instance;
    await logger.resetForTest();
    await logger.init(
      overrideDirectory: tempDir,
      attachLifecycleObserver: false,
    );
  });

  tearDown(() async {
    await logger.resetForTest();
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  test('writes timestamped INFO entries to a persistent file', () async {
    logger.info('App started');
    await logger.flush();

    final File? file = logger.logFile;
    expect(file, isNotNull);
    final String contents = await file!.readAsString();
    expect(contents, contains('[INFO] App started'));
    expect(contents, contains(RegExp(r'\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}')));
  });

  test('records errors with type and stack trace', () async {
    try {
      throw StateError('session restore failed');
    } catch (e, st) {
      logger.error('Session restore failed', error: e, stackTrace: st);
    }
    await logger.flush();

    final String contents = await logger.logFile!.readAsString();
    expect(contents, contains('[ERROR] Session restore failed'));
    expect(contents, contains('Error: StateError'));
    expect(contents, contains('StackTrace:'));
  });

  test('does not write bearer tokens or secrets', () {
    final String sanitized = DiagnosticLogger.sanitizeForTest(
      'Authorization: Bearer super-secret-token password=hunter2 '
      'fcm_token=abc123 access_token=xyz',
    );
    expect(sanitized, isNot(contains('super-secret-token')));
    expect(sanitized, isNot(contains('hunter2')));
    expect(sanitized, isNot(contains('abc123')));
    expect(sanitized, isNot(contains('xyz')));
    expect(sanitized, contains('[REDACTED]'));
  });

  test('export copy uses the required filename prefix', () async {
    logger.info('Export test');
    await logger.flush();

    final File? copy = await logger.prepareExportFile();
    expect(copy, isNotNull);
    expect(
      copy!.uri.pathSegments.last,
      matches(RegExp(r'^casazero_diagnostic_\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}\.txt$')),
    );
    final String contents = await copy.readAsString();
    expect(contents, contains('[INFO] Export test'));
  });

  test('retains recent logs when the file exceeds the size limit', () async {
    logger.maxLogBytes = 400;
    logger.retainLogBytes = 200;

    for (int i = 0; i < 80; i++) {
      logger.info('entry-$i');
    }
    await logger.flush();

    final int length = await logger.logFile!.length();
    expect(length, lessThanOrEqualTo(400));
    final String contents = await logger.logFile!.readAsString();
    expect(contents, contains('entry-79'));
  });
}
