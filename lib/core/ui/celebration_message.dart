import 'package:flutter/material.dart';

class CelebrationMessage extends StatelessWidget {
  const CelebrationMessage({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primaryContainer;
    final onColor = Theme.of(context).colorScheme.onPrimaryContainer;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, _) {
        return Transform.scale(
          scale: Curves.elasticOut.transform(value),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: onColor,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}
