import '../models/system_prompt.dart';

abstract class SystemPromptService {
  Future<List<SystemPrompt>> loadSystemPrompts();
  Future<SystemPrompt> createSystemPrompt(SystemPrompt prompt);
  Future<void> updateSystemPrompt(SystemPrompt prompt);
  Future<void> deleteSystemPrompt(int id);
  Future<SystemPrompt?> getDefaultSystemPrompt();
  Future<void> setDefaultSystemPrompt(int id);
  Future<List<SystemPrompt>> searchSystemPrompts(String query);
  Future<void> reorderSystemPrompts(List<int> ids);
}