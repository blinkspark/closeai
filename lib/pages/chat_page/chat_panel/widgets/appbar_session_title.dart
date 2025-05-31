import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/session_controller.dart';
import '../../../../widgets/generate_title_button.dart';

/// 用于AppBar的会话标题和编辑按钮（手机端）
class AppBarSessionTitle extends StatelessWidget {
  const AppBarSessionTitle({
    super.key,
    required this.onTitleGenerated,
  });
  
  final ValueChanged<String> onTitleGenerated;

  @override
  Widget build(BuildContext context) {
    final sessionController = Get.find<SessionController>();
    final titleController = TextEditingController();
    return Obx(() {
      final isEmpty = sessionController.sessions.isEmpty;
      final index = sessionController.index.value;
      final isEditing = sessionController.editingTitle.value;
      final currentTitle = isEmpty ? '聊天' : sessionController.sessions[index].value.title;
      if (!isEditing) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                currentTitle,
                style: Theme.of(context).appBarTheme.titleTextStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!sessionController.isGeneratingTitle.value)
              GenerateTitleButton(
                isEmpty: isEmpty,
                onTitleGenerated: onTitleGenerated,
                iconSize: 20,
              )
            else
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              tooltip: '编辑标题',
              onPressed: isEmpty ? null : () => sessionController.editingTitle.value = true,
            ),
          ],
        );
      } else {
        titleController.text = currentTitle;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 120,
              child: TextField(
                controller: titleController,
                autofocus: true,
                onSubmitted: (value) {
                  _saveTitle(sessionController, index, value);
                },
                decoration: const InputDecoration(
                  isDense: true,
                  border: UnderlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check, size: 20),
              tooltip: '保存标题',
              onPressed: () => _saveTitle(sessionController, index, titleController.text),
            ),
          ],
        );
      }
    });
  }

  void _saveTitle(SessionController controller, int index, String newTitle) {
    if (controller.sessions.isEmpty) return;
    final session = controller.sessions[index].value;
    session.title = newTitle;
    controller.sessions[index].value = session;
    controller.updateSession(session);
    controller.editingTitle.value = false;
  }
}
