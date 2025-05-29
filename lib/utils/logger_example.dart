import '../utils/app_logger.dart';
import 'package:logger/logger.dart';

/// 日志使用示例
class LoggerExample {
  
  /// 展示基本日志级别的使用
  static void demonstrateBasicLogging() {
    // 基本日志级别
    AppLogger.d('调试信息：变量值检查');
    AppLogger.i('应用启动完成');
    AppLogger.w('网络连接不稳定，正在重试');
    AppLogger.e('API调用失败', 'connection timeout');
    AppLogger.f('严重错误：应用即将崩溃', Exception('OutOfMemory'));
  }
  
  /// 展示网络请求日志
  static void demonstrateNetworkLogging() {
    AppLogger.network(
      'POST', 
      'https://api.openai.com/v1/chat/completions',
      data: {'model': 'gpt-3.5-turbo', 'messages': []},
      statusCode: 200,
    );
  }
  
  /// 展示业务流程日志
  static void demonstrateBusinessLogging() {
    AppLogger.business(
      'ChatService', 
      '发送消息', 
      data: {'user_id': '123', 'message_length': 50}
    );
  }
  
  /// 展示性能监控日志
  static void demonstratePerformanceLogging() {
    final stopwatch = Stopwatch()..start();
    
    // 模拟一些操作
    Future.delayed(Duration(milliseconds: 100));
    
    stopwatch.stop();
    AppLogger.performance(
      'API调用',
      stopwatch.elapsed,
      extra: {'endpoint': '/chat/completions', 'tokens': 150}
    );
  }
  
  /// 展示API调用日志
  static void demonstrateApiLogging() {
    AppLogger.api(
      'ChatCompletion',
      endpoint: 'https://api.openai.com/v1/chat/completions',
      request: {
        'model': 'gpt-3.5-turbo',
        'messages_count': 3,
        'stream': false,
      },
      response: {
        'usage': {'total_tokens': 150},
        'choices_count': 1,
      },
      statusCode: 200,
      duration: Duration(milliseconds: 1500),
    );
  }
  
  /// 展示用户行为日志
  static void demonstrateUserActionLogging() {
    AppLogger.userAction(
      'SendMessage',
      context: {
        'session_id': 'abc123',
        'message_type': 'text',
        'timestamp': DateTime.now().toIso8601String(),
      }
    );
  }
  
  /// 展示应用状态日志
  static void demonstrateAppStateLogging() {
    AppLogger.appState(
      'ModelChanged',
      data: {
        'old_model': 'gpt-3.5-turbo',
        'new_model': 'gpt-4',
        'provider': 'OpenAI',
      }
    );
  }
  
  /// 展示带标签的日志
  static void demonstrateTaggedLogging() {
    AppLogger.tagged('DatabaseService', Level.info, '数据库连接成功');
    AppLogger.tagged('CacheService', Level.warning, '缓存即将过期');
    AppLogger.tagged('AuthService', Level.error, '认证失败');
  }
  
  /// 展示批量日志
  static void demonstrateBatchLogging() {
    AppLogger.batch('InitializeServices', [
      '初始化数据库服务',
      '加载用户配置',
      '连接到API服务器',
      '启动后台任务',
      '完成应用初始化',
    ]);
  }
  
  /// 展示条件日志（仅在debug模式）
  static void demonstrateDebugLogging() {
    AppLogger.debug('这条日志只在debug模式下显示');
    AppLogger.debug('调试变量：count = 42, isValid = true');
  }
  
  /// 综合示例：模拟一个完整的API调用流程
  static Future<void> simulateApiCallFlow() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // 1. 记录开始
      AppLogger.business('ChatService', '开始处理用户消息');
      
      // 2. 记录API调用开始
      AppLogger.api('ChatCompletion', 
        endpoint: 'https://api.openai.com/v1/chat/completions');
      
      // 3. 模拟API调用
      await Future.delayed(Duration(milliseconds: 1200));
      
      // 4. 记录成功结果
      stopwatch.stop();
      AppLogger.api(
        'ChatCompletion',
        endpoint: 'https://api.openai.com/v1/chat/completions',
        statusCode: 200,
        duration: stopwatch.elapsed,
        response: {'usage': {'total_tokens': 156}},
      );
      
      // 5. 记录业务完成
      AppLogger.business('ChatService', '消息处理完成',
        data: {'response_tokens': 156, 'processing_time': stopwatch.elapsed.inMilliseconds});
      
      // 6. 记录用户行为
      AppLogger.userAction('ReceiveResponse', context: {
        'response_time': stopwatch.elapsed.inMilliseconds,
        'tokens_used': 156,
      });
      
    } catch (e) {
      stopwatch.stop();
      AppLogger.api(
        'ChatCompletion',
        endpoint: 'https://api.openai.com/v1/chat/completions',
        duration: stopwatch.elapsed,
        error: e,
      );
      
      AppLogger.e('API调用失败', e);
    }
  }
}
