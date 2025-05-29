import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'logger_config.dart';

/// 应用全局日志工具
class AppLogger {
  static Logger? _logger;
    /// 获取Logger实例，支持不同环境的配置
  static Logger get _instance {
    _logger ??= LoggerConfig.createLogger();
    return _logger!;
  }
  /// Debug 级别日志 - 用于开发调试
  static void d(dynamic message, [Object? error, StackTrace? stackTrace]) {
    _instance.d(message, error: error, stackTrace: stackTrace);
  }

  /// Info 级别日志 - 用于一般信息
  static void i(dynamic message, [Object? error, StackTrace? stackTrace]) {
    _instance.i(message, error: error, stackTrace: stackTrace);
  }

  /// Warning 级别日志 - 用于警告信息
  static void w(dynamic message, [Object? error, StackTrace? stackTrace]) {
    _instance.w(message, error: error, stackTrace: stackTrace);
  }

  /// Error 级别日志 - 用于错误信息
  static void e(dynamic message, [Object? error, StackTrace? stackTrace]) {
    _instance.e(message, error: error, stackTrace: stackTrace);
  }

  /// Fatal 级别日志 - 用于致命错误
  static void f(dynamic message, [Object? error, StackTrace? stackTrace]) {
    _instance.f(message, error: error, stackTrace: stackTrace);
  }

  /// 网络请求日志
  static void network(String method, String url, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
    int? statusCode,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('🌐 [$method] $url');
    if (statusCode != null) buffer.writeln('📊 Status: $statusCode');
    if (headers != null && headers.isNotEmpty) {
      buffer.writeln('📋 Headers: $headers');
    }
    if (data != null) buffer.writeln('📤 Data: $data');
      _instance.i(buffer.toString());
  }

  /// 业务流程日志
  static void business(String tag, String message, {Object? data}) {
    final logMessage = data != null 
        ? '🏢 [$tag] $message\n📄 Data: $data'
        : '🏢 [$tag] $message';
    _instance.i(logMessage);
  }

  /// 性能监控日志
  static void performance(String operation, Duration duration, {Object? extra}) {
    final message = extra != null
        ? '⚡ [$operation] 耗时: ${duration.inMilliseconds}ms\n📊 Extra: $extra'
        : '⚡ [$operation] 耗时: ${duration.inMilliseconds}ms';
    _instance.i(message);
  }

  /// API调用日志
  static void api(String action, {
    String? endpoint,
    Map<String, dynamic>? request,
    Map<String, dynamic>? response,
    int? statusCode,
    Duration? duration,
    Object? error,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('🔌 API[$action]');
    
    if (endpoint != null) buffer.writeln('🎯 Endpoint: $endpoint');
    if (statusCode != null) buffer.writeln('📊 Status: $statusCode');
    if (duration != null) buffer.writeln('⏱️ Duration: ${duration.inMilliseconds}ms');
    if (request != null) buffer.writeln('📤 Request: $request');
    if (response != null) buffer.writeln('📥 Response: $response');
    if (error != null) buffer.writeln('❌ Error: $error');
    
    if (error != null) {
      _instance.e(buffer.toString());
    } else {
      _instance.i(buffer.toString());
    }
  }

  /// 用户行为日志
  static void userAction(String action, {Map<String, dynamic>? context}) {
    final logMessage = context != null
        ? '👤 User[$action]\n📍 Context: $context'
        : '👤 User[$action]';
    _instance.i(logMessage);
  }

  /// 应用状态日志
  static void appState(String state, {Object? data}) {
    final logMessage = data != null
        ? '📱 App[$state]\n📊 Data: $data'
        : '📱 App[$state]';
    _instance.i(logMessage);
  }

  /// 条件日志 - 仅在debug模式下输出
  static void debug(dynamic message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _instance.d(message, error: error, stackTrace: stackTrace);
    }
  }

  /// 工具方法：创建带有标签的logger
  static void tagged(String tag, Level level, dynamic message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final taggedMessage = '[$tag] $message';
    switch (level) {
      case Level.debug:
        _instance.d(taggedMessage, error: error, stackTrace: stackTrace);
        break;
      case Level.info:
        _instance.i(taggedMessage, error: error, stackTrace: stackTrace);
        break;
      case Level.warning:
        _instance.w(taggedMessage, error: error, stackTrace: stackTrace);
        break;
      case Level.error:
        _instance.e(taggedMessage, error: error, stackTrace: stackTrace);
        break;
      case Level.fatal:
        _instance.f(taggedMessage, error: error, stackTrace: stackTrace);
        break;
      default:
        _instance.i(taggedMessage, error: error, stackTrace: stackTrace);
    }
  }

  /// 批量日志 - 用于记录多个相关操作
  static void batch(String operation, List<String> messages) {
    final buffer = StringBuffer();
    buffer.writeln('📦 [$operation] 批量操作:');
    for (int i = 0; i < messages.length; i++) {
      buffer.writeln('  ${i + 1}. ${messages[i]}');
    }
    _instance.i(buffer.toString());
  }

  /// 清理资源（如果需要的话）
  static void dispose() {
    _logger?.close();
    _logger = null;
  }
}
