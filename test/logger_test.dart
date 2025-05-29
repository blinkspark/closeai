import 'package:flutter_test/flutter_test.dart';
import 'package:closeai/utils/app_logger.dart';
import 'package:closeai/utils/logger_example.dart';

void main() {
  group('日志系统测试', () {
    test('基本日志级别测试', () {
      expect(() => AppLogger.d('Debug测试'), returnsNormally);
      expect(() => AppLogger.i('Info测试'), returnsNormally);
      expect(() => AppLogger.w('Warning测试'), returnsNormally);
      expect(() => AppLogger.e('Error测试'), returnsNormally);
      expect(() => AppLogger.f('Fatal测试'), returnsNormally);
    });

    test('特殊日志类型测试', () {
      expect(() => AppLogger.network('GET', 'https://api.test.com'), returnsNormally);
      expect(() => AppLogger.business('TestService', '测试业务'), returnsNormally);
      expect(() => AppLogger.performance('TestOperation', Duration(milliseconds: 100)), returnsNormally);
      expect(() => AppLogger.userAction('TestAction'), returnsNormally);
      expect(() => AppLogger.appState('TestState'), returnsNormally);
    });

    test('API日志测试', () {
      expect(() => AppLogger.api(
        'TestAPI',
        endpoint: 'https://api.test.com/test',
        statusCode: 200,
        duration: Duration(milliseconds: 500),
      ), returnsNormally);
    });

    test('批量日志测试', () {
      expect(() => AppLogger.batch('TestBatch', [
        '步骤1',
        '步骤2',
        '步骤3',
      ]), returnsNormally);
    });

    test('日志示例运行测试', () {
      expect(() => LoggerExample.demonstrateBasicLogging(), returnsNormally);
      expect(() => LoggerExample.demonstrateNetworkLogging(), returnsNormally);
      expect(() => LoggerExample.demonstrateBusinessLogging(), returnsNormally);
      expect(() => LoggerExample.demonstratePerformanceLogging(), returnsNormally);
      expect(() => LoggerExample.demonstrateApiLogging(), returnsNormally);
      expect(() => LoggerExample.demonstrateUserActionLogging(), returnsNormally);
      expect(() => LoggerExample.demonstrateAppStateLogging(), returnsNormally);
      expect(() => LoggerExample.demonstrateTaggedLogging(), returnsNormally);
      expect(() => LoggerExample.demonstrateBatchLogging(), returnsNormally);
      expect(() => LoggerExample.demonstrateDebugLogging(), returnsNormally);
    });

    test('异步日志测试', () async {
      expect(() async => await LoggerExample.simulateApiCallFlow(), returnsNormally);
    });
  });
}
