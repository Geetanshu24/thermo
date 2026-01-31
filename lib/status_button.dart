import 'package:flutter/material.dart';

class StatusButton extends StatelessWidget {
  final bool selected;
  final String text;
  final VoidCallback onTap;

  const StatusButton({
    required this.selected,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? cs.primary : const Color(0xFF1E3558)),
          color: selected ? cs.primary : const Color(0xFF111E32),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.black : Colors.white70,
          ),
        ),
      ),
    );
  }
}
