import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/zhipu_search_service.dart';
import '../../controllers/provider_controller.dart';
import '../../models/provider.dart';
import 'zhipu_setting_widgets.dart';

/// 智谱AI配置页面
class ZhipuSettingPage extends StatefulWidget {
  const ZhipuSettingPage({super.key});

  @override
  State<ZhipuSettingPage> createState() => _ZhipuSettingPageState();
}

class _ZhipuSettingPageState extends State<ZhipuSettingPage> {
  final TextEditingController _apiKeyController = TextEditingController();
  final ZhipuSearchService _zhipuService = Get.find<ZhipuSearchService>();
  final ProviderController _providerController = Get.find<ProviderController>();
  
  bool _isLoading = false;
  bool _isApiKeyVisible = false;
  String? _testResult;
  Provider? _zhipuProvider;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  void _loadCurrentConfig() {
    // 从Provider系统加载智谱AI的API Key
    try {
      _zhipuProvider = _providerController.providers
          .map((p) => p.value)
          .where((p) => p.name == 'ZhipuAI')
          .firstOrNull;
      
      if (_zhipuProvider != null && _zhipuProvider!.apiKey != null && _zhipuProvider!.apiKey!.isNotEmpty) {
        _apiKeyController.text = _zhipuProvider!.apiKey!;
        // 同时配置服务
        _zhipuService.configure(_zhipuProvider!.apiKey!);
      }    } catch (e) {
      // 加载智谱AI配置失败
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智谱AI配置'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ZhipuInfoCard(
              features: const [
                '意图增强检索：智能识别用户查询意图',
                '结构化输出：返回适合LLM处理的数据格式',
                '多引擎支持：整合多个主流搜索引擎',
              ],
              bottomWidget: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.celebration, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '限时免费！基础版搜索免费至2025年5月31日',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ZhipuConfigSection(
              apiKeyController: _apiKeyController,
              isLoading: _isLoading,
              isApiKeyVisible: _isApiKeyVisible,
              onToggleApiKeyVisible: () {
                setState(() {
                  _isApiKeyVisible = !_isApiKeyVisible;
                });
              },
              onSave: _saveConfiguration,
              onClear: _clearConfiguration,
            ),
            const SizedBox(height: 16),
            ZhipuTestSection(
              isLoading: _isLoading,
              onTest: _testConnection,
            ),
            if (_testResult != null) ...[
              const SizedBox(height: 16),
              ZhipuTestResultCard(testResult: _testResult!),
            ],
          ],
        ),
      ),
    );
  }

  void _saveConfiguration() async {
    if (_apiKeyController.text.trim().isEmpty) {
      _showSnackBar('请输入API Key', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _testResult = null;
    });

    try {
      // 配置智谱搜索服务
      _zhipuService.configure(_apiKeyController.text.trim());
      
      // 保存到Provider系统
      if (_zhipuProvider != null) {
        // 更新现有的Provider
        _zhipuProvider!.apiKey = _apiKeyController.text.trim();
        await _providerController.isar.writeTxn(() async {
          await _providerController.isar.providers.put(_zhipuProvider!);
        });
      } else {
        // 创建新的ZhipuAI Provider（理论上不应该发生，因为默认已创建）
        final newProvider = Provider()
          ..name = 'ZhipuAI'
          ..baseUrl = 'https://open.bigmodel.cn/api/paas/v4'
          ..apiKey = _apiKeyController.text.trim();
        await _providerController.addProvider(newProvider);
        _zhipuProvider = newProvider;
      }
      
      _showSnackBar('配置保存成功');
    } catch (e) {
      _showSnackBar('保存配置失败: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearConfiguration() async {
    setState(() {
      _apiKeyController.clear();
      _testResult = null;
      _isLoading = true;
    });
    
    try {
      // 清除服务配置
      _zhipuService.configure('');
      
      // 清除Provider中的API Key
      if (_zhipuProvider != null) {
        _zhipuProvider!.apiKey = '';
        await _providerController.isar.writeTxn(() async {
          await _providerController.isar.providers.put(_zhipuProvider!);
        });
      }
      
      _showSnackBar('配置已清除');
    } catch (e) {
      _showSnackBar('清除配置失败: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _testConnection() async {
    if (_apiKeyController.text.trim().isEmpty) {
      _showSnackBar('请先输入API Key', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _testResult = null;
    });

    try {
      // 先保存配置
      _zhipuService.configure(_apiKeyController.text.trim());
      
      // 执行测试搜索
      final result = await _zhipuService.webSearch(
        searchQuery: '测试搜索',
        count: 1,
      );
      
      if (result['search_result'] != null) {
        setState(() {
          _testResult = '✅ 测试成功！API Key有效，搜索功能正常。';
        });
      } else {
        setState(() {
          _testResult = '⚠️ 测试部分成功：API Key有效，但未返回搜索结果。';
        });
      }
    } catch (e) {
      setState(() {
        _testResult = '❌ 测试失败：$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
}