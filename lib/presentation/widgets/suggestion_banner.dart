import 'package:flutter/material.dart';

class SuggestionBanner extends StatelessWidget {
  const SuggestionBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    final colors = light
        ? const [Color(0xFFE8F2EC), Color(0xFFD4E8DD)]
        : const [Color(0xFF1A2B45), Color(0xFF203A61)];
    final fg = light ? const Color(0xFF143524) : const Color(0xFFE8ECF5);
    final icon = light ? const Color(0xFF1F6F4A) : const Color(0xFFB8D4FF);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(14),
        border: light ? Border.all(color: const Color(0xFFAAC9B6)) : null,
      ),
      child: Row(
        children: [
          Icon(Icons.tips_and_updates_outlined, color: icon),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: fg,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
