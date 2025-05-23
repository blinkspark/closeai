import 'package:flutter/material.dart';

class SettingSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const SettingSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

class SettingSectionItem extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;
  final bool isDanger;

  const SettingSectionItem({
    super.key,
    required this.title,
    this.onPressed,
    this.leading,
    this.trailing,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isDanger ? Theme.of(context).colorScheme.error : null,
        ),
      ),
      leading: leading,
      trailing: trailing,
      onTap: onPressed,
      contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    );
  }
}
