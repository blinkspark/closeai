import 'dart:convert';

/// 工具定义模型
class FunctionDefinition {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;
  
  FunctionDefinition({
    required this.name,
    required this.description,
    required this.parameters,
  });
  
  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'parameters': parameters,
  };
  
  factory FunctionDefinition.fromJson(Map<String, dynamic> json) => FunctionDefinition(
    name: json['name'],
    description: json['description'],
    parameters: json['parameters'],
  );
  
  @override
  String toString() => 'FunctionDefinition(name: $name, description: $description)';
}

/// 工具调用模型
class FunctionCall {
  final String name;
  final String arguments;
  
  FunctionCall({
    required this.name,
    required this.arguments,
  });
  
  factory FunctionCall.fromJson(Map<String, dynamic> json) => FunctionCall(
    name: json['name'],
    arguments: json['arguments'],
  );
  
  Map<String, dynamic> toJson() => {
    'name': name,
    'arguments': arguments,
  };
  
  /// 获取解析后的参数
  Map<String, dynamic> getParsedArguments() {    try {
      return jsonDecode(arguments);
    } catch (e) {
      return {};
    }
  }
  
  @override
  String toString() => 'FunctionCall(name: $name, arguments: $arguments)';
}

/// 工具调用完整信息
class ToolCall {
  final String id;
  final String type;
  final FunctionCall function;
  
  ToolCall({
    required this.id,
    required this.type,
    required this.function,
  });
  
  factory ToolCall.fromJson(Map<String, dynamic> json) => ToolCall(
    id: json['id'],
    type: json['type'],
    function: FunctionCall.fromJson(json['function']),
  );
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'function': function.toJson(),
  };
  
  @override
  String toString() => 'ToolCall(id: $id, type: $type, function: $function)';
}

/// 工具选择模型
class ToolChoice {
  final String type;
  final FunctionDefinition? function;
  
  ToolChoice({
    required this.type,
    this.function,
  });
  
  factory ToolChoice.auto() => ToolChoice(type: 'auto');
  factory ToolChoice.none() => ToolChoice(type: 'none');
  factory ToolChoice.required() => ToolChoice(type: 'required');
  factory ToolChoice.function(FunctionDefinition function) => ToolChoice(
    type: 'function',
    function: function,
  );
  
  Map<String, dynamic> toJson() => {
    'type': type,
    if (function != null) 'function': function!.toJson(),
  };
  
  factory ToolChoice.fromJson(Map<String, dynamic> json) => ToolChoice(
    type: json['type'],
    function: json['function'] != null 
      ? FunctionDefinition.fromJson(json['function'])
      : null,
  );
  
  @override
  String toString() => 'ToolChoice(type: $type, function: $function)';
}

/// 工具响应模型
class ToolResponse {
  final String toolCallId;
  final String content;
  final bool isSuccess;
  final String? error;
  
  ToolResponse({
    required this.toolCallId,
    required this.content,
    this.isSuccess = true,
    this.error,
  });
  
  factory ToolResponse.success({
    required String toolCallId,
    required String content,
  }) => ToolResponse(
    toolCallId: toolCallId,
    content: content,
    isSuccess: true,
  );
  
  factory ToolResponse.error({
    required String toolCallId,
    required String error,
  }) => ToolResponse(
    toolCallId: toolCallId,
    content: '工具调用失败: $error',
    isSuccess: false,
    error: error,
  );
  
  Map<String, dynamic> toMessageJson() => {
    'role': 'tool',
    'tool_call_id': toolCallId,
    'content': content,
  };
  
  @override
  String toString() => 'ToolResponse(toolCallId: $toolCallId, isSuccess: $isSuccess, content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content})';
}