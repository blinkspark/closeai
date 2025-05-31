import 'package:flutter/material.dart';

/// 通用的“生成标题”按钮组件
class GenerateTitleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isEmpty;
  final double iconSize;

  const GenerateTitleButton({
    super.key,
    required this.onPressed,
    required this.isEmpty,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.assistant, size: iconSize),
      tooltip: '生成标题',
      onPressed: isEmpty ? null : onPressed,
    );
  }
}
