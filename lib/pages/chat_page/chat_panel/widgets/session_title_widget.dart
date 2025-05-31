import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/session_controller.dart';
import '../../../../widgets/generate_title_button.dart';

class SessionTitleWidget extends StatefulWidget {
  final ValueChanged<String>? onTitleGenerated;
  
  const SessionTitleWidget({super.key, this.onTitleGenerated});

  @override
  State<SessionTitleWidget> createState() => _SessionTitleWidgetState();
}

class _SessionTitleWidgetState extends State<SessionTitleWidget> {
  late TextEditingController _titleController;
  SessionController? _sessionController;

  @override
  void initState() {
    super.initState();
    _sessionController = Get.find<SessionController>();
    _titleController = TextEditingController();
    _updateControllerText();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _updateControllerText() {
    final controller = _sessionController!;
    final isEmpty = controller.sessions.isEmpty;
    final currentTitle = isEmpty ? '' : controller.sessions[controller.index.value].value.title;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_titleController.text != currentTitle) {
        _titleController.text = currentTitle;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionController = _sessionController!;
    
    return Obx(() {
      final index = sessionController.index.value;
      final isEmpty = sessionController.sessions.isEmpty;
      final isEditing = sessionController.editingTitle.value;
      // 显式监听sessions变化
      final currentSession = isEmpty ? null : sessionController.sessions[index].value;
      
      // 更新controller文本
      _updateControllerText();

      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: _titleController,
              enabled: isEditing,
              onSubmitted: (value) {
                if (!isEmpty && isEditing) {
                  _saveTitle(sessionController, index, value);
                }
              },
            ),
          ),
          GenerateTitleButton(
            isEmpty: isEmpty,
            onTitleGenerated: (title) {
              if (widget.onTitleGenerated != null) {
                widget.onTitleGenerated!(title);
              }
            },
          ),
          IconButton(
            onPressed: isEmpty
                ? null
                : () {
                    if (isEditing) {
                      _saveTitle(sessionController, index, _titleController.text);
                    } else {
                      sessionController.editingTitle.value = true;
                    }
                  },
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            tooltip: isEditing ? '保存标题' : '编辑标题',
          ),
        ],
      );
    });
  }

  void _saveTitle(SessionController controller, int index, String newTitle) {
    final session = controller.sessions[index].value;
    session.title = newTitle;
    controller.sessions[index].value = session;
    controller.updateSession(session);
    controller.editingTitle.value = false;
  }
}
