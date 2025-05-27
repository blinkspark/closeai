import 'package:get/get.dart';
import 'dart:convert';

import '../models/message.dart';
import '../models/session.dart';
import '../models/mcp_tool.dart';
import '../services/message_service.dart';
import 'mcp_controller.dart';

/// 聊天控制器，负责管理聊天相关的UI状态和业务逻辑
class ChatController extends GetxController {
  late final MessageService _messageService;
  late final MCPController _mcpController;
  
  // UI状态
  final messages = <Message>[].obs;
  final isLoading = false.obs;
  final currentSessionId = Rxn<int>();
  final streamingMessage = Rxn<Message>();
  final isStreaming = false.obs;

  @override
  void onInit() {
    super.onInit();
    _messageService = Get.find<MessageService>();
    _mcpController = Get.find<MCPController>();
  }

  /// 加载指定会话的消息
  Future<void> loadMessages(int sessionId) async {
    isLoading.value = true;
    try {
      currentSessionId.value = sessionId;
      final sessionMessages = await _messageService.getMessagesBySessionId(sessionId);
      messages.assignAll(sessionMessages);
    } finally {
      isLoading.value = false;
    }
  }

  /// 添加消息到当前会话
  Future<Message> addMessage({
    required String role,
    required String content,
    required Session session,
  }) async {
    final message = await _messageService.createMessage(
      role: role,
      content: content,
      session: session,
    );
    
    // 如果是当前会话的消息，添加到UI列表
    if (currentSessionId.value == session.id) {
      messages.add(message);
    }
    
    return message;
  }

  /// 更新消息
  Future<void> updateMessage(Message message) async {
    await _messageService.updateMessage(message);
    
    // 更新UI中的消息
    final index = messages.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      messages[index] = message;
    }
  }

  /// 删除消息
  Future<void> deleteMessage(int messageId) async {
    await _messageService.deleteMessage(messageId);
    
    // 从UI列表中移除
    messages.removeWhere((m) => m.id == messageId);
  }

  /// 开始流式消息
  Future<Message> startStreamingMessage({
    required String role,
    required Session session,
  }) async {
    final message = await _messageService.createMessage(
      role: role,
      content: '',
      session: session,
    );
    
    // 如果是当前会话的消息，添加到UI列表
    if (currentSessionId.value == session.id) {
      messages.add(message);
      streamingMessage.value = message;
      isStreaming.value = true;
    }
    
    return message;
  }

  /// 更新流式消息内容
  void updateStreamingMessage(String content) {
    if (streamingMessage.value != null) {
      streamingMessage.value!.content = content;
      
      // 更新UI中的消息
      final index = messages.indexWhere((m) => m.id == streamingMessage.value!.id);
      if (index != -1) {
        messages[index] = streamingMessage.value!;
      }
    }
  }

  /// 完成流式消息
  Future<void> finishStreamingMessage() async {
    if (streamingMessage.value != null) {
      // 保存最终的消息内容到数据库
      await _messageService.updateMessage(streamingMessage.value!);
      
      streamingMessage.value = null;
      isStreaming.value = false;
    }
  }

  /// 取消流式消息
  Future<void> cancelStreamingMessage() async {
    if (streamingMessage.value != null) {
      // 从UI中移除
      messages.removeWhere((m) => m.id == streamingMessage.value!.id);
      
      // 从数据库中删除
      await _messageService.deleteMessage(streamingMessage.value!.id);
      
      streamingMessage.value = null;
      isStreaming.value = false;
    }
  }

  /// 清空当前会话的消息显示
  void clearMessages() {
    messages.clear();
    currentSessionId.value = null;
    streamingMessage.value = null;
    isStreaming.value = false;
  }

  /// 获取消息总数
  Future<int> getMessageCount() async {
    return await _messageService.getMessageCount();
  }

  /// 获取特定会话的消息总数
  Future<int> getMessageCountBySessionId(int sessionId) async {
    return await _messageService.getMessageCountBySessionId(sessionId);
  }

  /// 检测消息中的工具调用
  List<MCPToolCall> detectToolCalls(String content) {
    final toolCalls = <MCPToolCall>[];
    
    // 简单的工具调用检测逻辑
    // 查找类似 @tool_name(param1=value1, param2=value2) 的模式
    final toolCallPattern = RegExp(r'@(\w+)\((.*?)\)');
    final matches = toolCallPattern.allMatches(content);
    
    for (final match in matches) {
      final toolName = match.group(1)!;
      final paramsStr = match.group(2)!;
      
      // 解析参数
      final parameters = <String, dynamic>{};
      if (paramsStr.isNotEmpty) {
        final paramPairs = paramsStr.split(',');
        for (final pair in paramPairs) {
          final keyValue = pair.split('=');
          if (keyValue.length == 2) {
            final key = keyValue[0].trim();
            final value = keyValue[1].trim();
            // 尝试解析为JSON，如果失败则作为字符串
            try {
              parameters[key] = jsonDecode(value);
            } catch (e) {
              parameters[key] = value.replaceAll('"', '').replaceAll("'", '');
            }
          }
        }
      }
      
      toolCalls.add(MCPToolCall(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: toolName,
        parameters: parameters,
      ));
    }
    
    return toolCalls;
  }

  /// 执行工具调用并添加结果消息
  Future<void> executeToolCalls(List<MCPToolCall> toolCalls, Session session) async {
    for (final toolCall in toolCalls) {
      try {
        // 添加工具调用开始消息
        await addMessage(
          role: 'assistant',
          content: '🔧 正在调用MCP工具: ${toolCall.name}\n参数: ${jsonEncode(toolCall.parameters)}',
          session: session,
        );

        // 检查工具是否存在
        final tool = _mcpController.getToolByName(toolCall.name);
        if (tool == null) {
          // 添加错误消息
          await addMessage(
            role: 'tool',
            content: '❌ 错误: 未找到工具 "${toolCall.name}"\n\n可用工具: ${_mcpController.availableTools.map((t) => t.name).join(', ')}',
            session: session,
          );
          continue;
        }

        // 执行工具调用
        final result = await _mcpController.executeTool(toolCall.name, toolCall.parameters);
        
        if (result != null) {
          // 添加工具结果消息
          await addMessage(
            role: 'tool',
            content: result.isError
                ? '❌ 工具执行错误: ${result.content}'
                : '✅ 工具执行成功:\n\n${result.content}',
            session: session,
          );
        }
      } catch (e) {
        // 添加错误消息
        await addMessage(
          role: 'tool',
          content: '❌ 工具调用失败: $e',
          session: session,
        );
      }
    }
  }

  /// 获取可用的MCP工具列表
  List<MCPTool> getAvailableTools() {
    return _mcpController.availableTools;
  }

  /// 获取可用的MCP资源列表
  List<MCPResource> getAvailableResources() {
    return _mcpController.availableResources;
  }

  /// 检查是否有可用的MCP工具
  bool get hasMCPTools => _mcpController.hasAvailableTools;

  /// 检查是否有可用的MCP资源
  bool get hasMCPResources => _mcpController.hasAvailableResources;

  /// 处理用户消息并检测MCP工具调用
  Future<void> processUserMessage(String content, Session session) async {
    // 首先添加用户消息
    await addMessage(
      role: 'user',
      content: content,
      session: session,
    );

    // 检测工具调用
    final toolCalls = detectToolCalls(content);
    
    if (toolCalls.isNotEmpty) {
      // 添加检测到工具调用的提示
      await addMessage(
        role: 'assistant',
        content: '🔍 检测到 ${toolCalls.length} 个MCP工具调用，开始执行...',
        session: session,
      );

      // 执行工具调用
      await executeToolCalls(toolCalls, session);
      
      // 添加完成提示
      await addMessage(
        role: 'assistant',
        content: '✨ MCP工具调用完成！您可以继续对话或调用其他工具。',
        session: session,
      );
    } else {
      // 检查是否包含工具相关的查询
      final lowerContent = content.toLowerCase();
      if (lowerContent.contains('工具') || lowerContent.contains('tool') ||
          lowerContent.contains('mcp') || lowerContent.contains('帮助')) {
        
        if (!hasMCPTools) {
          await addMessage(
            role: 'assistant',
            content: '🔧 当前没有可用的MCP工具。请在设置中配置MCP服务器。\n\n进入路径：设置 → AI配置 → MCP服务器',
            session: session,
          );
        } else {
          await addMessage(
            role: 'assistant',
            content: '🔧 ${getToolCallHelp()}',
            session: session,
          );
        }
      }
    }
  }

  /// 格式化工具调用帮助信息
  String getToolCallHelp() {
    final tools = getAvailableTools();
    if (tools.isEmpty) {
      return '当前没有可用的MCP工具。请在设置中配置MCP服务器。';
    }

    final buffer = StringBuffer();
    buffer.writeln('可用的MCP工具:');
    buffer.writeln();
    
    for (final tool in tools) {
      buffer.writeln('• @${tool.name}()');
      buffer.writeln('  ${tool.description}');
      
      // 显示参数信息
      if (tool.inputSchema.containsKey('properties')) {
        final properties = tool.inputSchema['properties'] as Map<String, dynamic>;
        if (properties.isNotEmpty) {
          buffer.writeln('  参数:');
          for (final entry in properties.entries) {
            final param = entry.value as Map<String, dynamic>;
            final type = param['type'] ?? 'string';
            final description = param['description'] ?? '';
            buffer.writeln('    - ${entry.key} ($type): $description');
          }
        }
      }
      buffer.writeln();
    }
    
    buffer.writeln('使用方法: @工具名(参数1=值1, 参数2=值2)');
    buffer.writeln('例如: @search(query="Flutter MCP", limit=5)');
    
    return buffer.toString();
  }
}