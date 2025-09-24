import 'package:flutter/material.dart';

class CustomFloatingButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;
  final Color? backgroundColor;

  const CustomFloatingButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.tooltip = '',
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
      tooltip: tooltip,
      elevation: 4.0,
      child: Icon(icon),
    );
  }
}
