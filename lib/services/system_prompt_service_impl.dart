import 'package:isar/isar.dart';
import 'package:get/get.dart';
import '../models/system_prompt.dart';
import 'system_prompt_service.dart';

class SystemPromptServiceImpl implements SystemPromptService {
  late final Isar _isar;

  SystemPromptServiceImpl() {
    _isar = Get.find<Isar>();
  }

  @override
  Future<List<SystemPrompt>> loadSystemPrompts() async {
    return await _isar.systemPrompts
        .where()
        .sortBySortOrder()
        .thenByCreateTime()
        .findAll();
  }

  @override
  Future<SystemPrompt> createSystemPrompt(SystemPrompt prompt) async {
    await _isar.writeTxn(() async {
      // 如果设置为默认，先取消其他默认设置
      if (prompt.isDefault) {
        await _clearDefaultPrompts();
      }
      
      // 设置排序顺序
      if (prompt.sortOrder == 0) {
        final maxOrder = await _isar.systemPrompts
            .where()
            .sortBySortOrderDesc()
            .findFirst();
        prompt.sortOrder = (maxOrder?.sortOrder ?? 0) + 1;
      }
      
      await _isar.systemPrompts.put(prompt);
    });
    return prompt;
  }

  @override
  Future<void> updateSystemPrompt(SystemPrompt prompt) async {
    await _isar.writeTxn(() async {
      // 如果设置为默认，先取消其他默认设置
      if (prompt.isDefault) {
        await _clearDefaultPrompts();
      }
      
      prompt.updateTime = DateTime.now();
      await _isar.systemPrompts.put(prompt);
    });
  }

  @override
  Future<void> deleteSystemPrompt(int id) async {
    await _isar.writeTxn(() async {
      await _isar.systemPrompts.delete(id);
    });
  }

  @override
  Future<SystemPrompt?> getDefaultSystemPrompt() async {
    return await _isar.systemPrompts
        .filter()
        .isDefaultEqualTo(true)
        .findFirst();
  }

  @override
  Future<void> setDefaultSystemPrompt(int id) async {
    await _isar.writeTxn(() async {
      // 先取消所有默认设置
      await _clearDefaultPrompts();
      
      // 设置新的默认
      final prompt = await _isar.systemPrompts.get(id);
      if (prompt != null) {
        prompt.isDefault = true;
        prompt.updateTime = DateTime.now();
        await _isar.systemPrompts.put(prompt);
      }
    });
  }

  @override
  Future<List<SystemPrompt>> searchSystemPrompts(String query) async {
    if (query.isEmpty) {
      return await loadSystemPrompts();
    }
    
    return await _isar.systemPrompts
        .filter()
        .nameContains(query, caseSensitive: false)
        .or()
        .contentContains(query, caseSensitive: false)
        .sortBySortOrder()
        .thenByCreateTime()
        .findAll();
  }

  @override
  Future<void> reorderSystemPrompts(List<int> ids) async {
    await _isar.writeTxn(() async {
      for (int i = 0; i < ids.length; i++) {
        final prompt = await _isar.systemPrompts.get(ids[i]);
        if (prompt != null) {
          prompt.sortOrder = i;
          prompt.updateTime = DateTime.now();
          await _isar.systemPrompts.put(prompt);
        }
      }
    });
  }

  /// 清除所有默认设置
  Future<void> _clearDefaultPrompts() async {
    final defaultPrompts = await _isar.systemPrompts
        .filter()
        .isDefaultEqualTo(true)
        .findAll();
    
    for (final prompt in defaultPrompts) {
      prompt.isDefault = false;
      prompt.updateTime = DateTime.now();
      await _isar.systemPrompts.put(prompt);
    }
  }

  /// 初始化默认系统提示词
  Future<void> initializeDefaultPrompts() async {
    final existingPrompts = await loadSystemPrompts();
    if (existingPrompts.isNotEmpty) return;

    await _createDefaultPrompts();
  }

  /// 强制重新创建默认系统提示词（用于重置）
  Future<void> forceInitializeDefaultPrompts() async {
    await _createDefaultPrompts();
  }

  /// 创建默认提示词的具体实现
  Future<void> _createDefaultPrompts() async {
    final defaultPrompts = [
      SystemPrompt.create(
        name: '默认助手',
        content: '你是一个有用的AI助手，请友好、准确地回答用户的问题。',
        isDefault: true,
        description: '通用的AI助手角色',
      ),
      SystemPrompt.create(
        name: '编程助手',
        content: '你是一个专业的编程助手，擅长多种编程语言和技术栈。请提供清晰、准确的代码示例和技术解释。当前用户：{{username}}，当前时间：{{time}}',
        description: '专门用于编程相关问题的助手',
      ),
      SystemPrompt.create(
        name: '写作助手',
        content: '你是一个专业的写作助手，能够帮助用户改进文本、提供写作建议、校对语法和优化表达。请保持专业且富有创造性。',
        description: '帮助用户进行写作和文本优化',
      ),
      SystemPrompt.create(
        name: '学习导师',
        content: '你是一个耐心的学习导师，善于用简单易懂的方式解释复杂概念。请根据用户的理解水平调整解释的深度和方式。今天是{{date}}。',
        description: '教育和学习指导专用',
      ),
    ];

    for (final prompt in defaultPrompts) {
      await createSystemPrompt(prompt);
    }
  }
}