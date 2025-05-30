import 'package:flutter/material.dart';

/// 智谱AI信息卡片
class ZhipuInfoCard extends StatelessWidget {
  final List<String> features;
  final Widget? bottomWidget;
  const ZhipuInfoCard({super.key, required this.features, this.bottomWidget});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '关于智谱AI搜索',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '智谱AI Web Search API 是专为大模型设计的搜索引擎，具有以下特点：',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            ...features.map((f) => ZhipuFeatureItem(text: f)),
            const SizedBox(height: 12),
            if (bottomWidget != null) bottomWidget!,
          ],
        ),
      ),
    );
  }
}

class ZhipuFeatureItem extends StatelessWidget {
  final String text;
  const ZhipuFeatureItem({super.key, required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.blue)),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

// 配置区块、测试区块、测试结果卡片
class ZhipuConfigSection extends StatelessWidget {
  final TextEditingController apiKeyController;
  final bool isLoading;
  final bool isApiKeyVisible;
  final VoidCallback onToggleApiKeyVisible;
  final VoidCallback onSave;
  final VoidCallback onClear;
  const ZhipuConfigSection({
    super.key,
    required this.apiKeyController,
    required this.isLoading,
    required this.isApiKeyVisible,
    required this.onToggleApiKeyVisible,
    required this.onSave,
    required this.onClear,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'API配置',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'API Key',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: apiKeyController,
              decoration: InputDecoration(
                hintText: '请输入智谱AI API Key',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    isApiKeyVisible ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: onToggleApiKeyVisible,
                ),
              ),
              obscureText: !isApiKeyVisible,
            ),
            const SizedBox(height: 8),
            Text(
              '获取API Key：访问 bigmodel.cn → 用户中心 → API管理',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onSave,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('保存配置'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: onClear,
                  child: const Text('清除'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ZhipuTestSection extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTest;
  const ZhipuTestSection({super.key, required this.isLoading, required this.onTest});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '连接测试',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '测试API Key是否有效以及搜索功能是否正常',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onTest,
                icon: isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_find),
                label: const Text('测试连接'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ZhipuTestResultCard extends StatelessWidget {
  final String testResult;
  const ZhipuTestResultCard({super.key, required this.testResult});
  @override
  Widget build(BuildContext context) {
    final isSuccess = testResult.contains('测试成功');
    return Card(
      color: isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  '测试结果',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              testResult,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
