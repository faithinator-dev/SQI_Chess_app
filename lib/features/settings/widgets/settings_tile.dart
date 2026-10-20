import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile({super.key, required this.icon, required this.title, this.subtitle, this.value, this.onTap, this.danger = false});
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurface;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: danger ? color : Theme.of(context).colorScheme.primary),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: value != null ? Text(value!, style: TextStyle(color: Theme.of(context).colorScheme.primary)) : (onTap == null ? null : const Icon(Icons.chevron_right_rounded)),
    );
  }
}
