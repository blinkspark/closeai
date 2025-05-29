import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// 日志配置类
class LoggerConfig {
  /// 根据环境获取适当的日志级别
  static Level getLogLevel() {
    if (kDebugMode) {
      return Level.debug;
    } else if (kProfileMode) {
      return Level.info;
    } else {
      return Level.warning;
    }
  }
  /// 获取日志过滤器
  static LogFilter getLogFilter() {
    if (kDebugMode) {
      return DevelopmentFilter();
    } else {
      return ProductionFilter();
    }
  }

  /// 获取日志输出器
  static LogOutput getLogOutput() {
    if (kDebugMode) {
      return ConsoleOutput();
    } else {
      // 在生产环境中，你可能想要将日志输出到文件或远程服务
      return ConsoleOutput();
    }
  }

  /// 获取日志打印器
  static LogPrinter getLogPrinter() {
    if (kDebugMode) {
      return PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
        excludeBox: const {},
        noBoxingByDefault: false,
      );
    } else {
      return SimplePrinter(
        colors: false,
        printTime: false,
      );
    }
  }

  /// 创建配置好的Logger实例
  static Logger createLogger() {
    return Logger(
      filter: getLogFilter(),
      printer: getLogPrinter(),
      output: getLogOutput(),
      level: getLogLevel(),
    );
  }
}

/// 自定义的生产环境过滤器
class ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (kDebugMode) {
      return true; // Debug模式下记录所有日志
    }
    
    // 生产环境只记录Warning及以上级别的日志
    return event.level.index >= Level.warning.index;
  }
}

/// 文件日志输出器（用于生产环境）
class FileOutput extends LogOutput {
  final String filePath;
  
  FileOutput(this.filePath);
  
  @override
  void output(OutputEvent event) {
    // 这里可以实现写入文件的逻辑
    // 例如使用 dart:io 的 File 类
    for (final line in event.lines) {
      // 写入文件或发送到远程日志服务
      if (kDebugMode) {
        // 在调试模式下同时输出到控制台
        print(line);
      }
    }
  }
}

/// 远程日志输出器（用于生产环境监控）
class RemoteLogOutput extends LogOutput {
  final String endpoint;
  
  RemoteLogOutput(this.endpoint);
  
  @override
  void output(OutputEvent event) {
    // 这里可以实现发送到远程日志服务的逻辑
    // 例如发送到 Firebase Crashlytics, Sentry 等
    for (final line in event.lines) {
      // 发送到远程服务
      _sendToRemote(line);
    }
  }
  
  void _sendToRemote(String logLine) {
    // 实现远程发送逻辑
    // 例如使用HTTP请求发送到日志收集服务
  }
}
