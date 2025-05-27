/// MCP工具定义
class MCPTool {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;
  
  const MCPTool({
    required this.name,
    required this.description,
    required this.inputSchema,
  });
  
  factory MCPTool.fromJson(Map<String, dynamic> json) {
    return MCPTool(
      name: json['name'] as String,
      description: json['description'] as String,
      inputSchema: json['inputSchema'] as Map<String, dynamic>,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'inputSchema': inputSchema,
    };
  }
}

/// MCP工具调用
class MCPToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> parameters;
  
  const MCPToolCall({
    required this.id,
    required this.name,
    required this.parameters,
  });
  
  factory MCPToolCall.fromJson(Map<String, dynamic> json) {
    return MCPToolCall(
      id: json['id'] as String,
      name: json['name'] as String,
      parameters: json['parameters'] as Map<String, dynamic>,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parameters': parameters,
    };
  }
}

/// MCP工具调用结果
class MCPToolResult {
  final String toolCallId;
  final bool isError;
  final String content;
  final Map<String, dynamic>? metadata;
  
  const MCPToolResult({
    required this.toolCallId,
    required this.isError,
    required this.content,
    this.metadata,
  });
  
  factory MCPToolResult.success({
    required String toolCallId,
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    return MCPToolResult(
      toolCallId: toolCallId,
      isError: false,
      content: content,
      metadata: metadata,
    );
  }
  
  factory MCPToolResult.error({
    required String toolCallId,
    required String error,
    Map<String, dynamic>? metadata,
  }) {
    return MCPToolResult(
      toolCallId: toolCallId,
      isError: true,
      content: error,
      metadata: metadata,
    );
  }
  
  factory MCPToolResult.fromJson(Map<String, dynamic> json) {
    return MCPToolResult(
      toolCallId: json['toolCallId'] as String,
      isError: json['isError'] as bool,
      content: json['content'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'toolCallId': toolCallId,
      'isError': isError,
      'content': content,
      'metadata': metadata,
    };
  }
}

/// MCP资源
class MCPResource {
  final String uri;
  final String name;
  final String? description;
  final String? mimeType;
  final String content;
  
  const MCPResource({
    required this.uri,
    required this.name,
    this.description,
    this.mimeType,
    required this.content,
  });
  
  factory MCPResource.fromJson(Map<String, dynamic> json) {
    return MCPResource(
      uri: json['uri'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      mimeType: json['mimeType'] as String?,
      content: json['content'] as String,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'uri': uri,
      'name': name,
      'description': description,
      'mimeType': mimeType,
      'content': content,
    };
  }
}