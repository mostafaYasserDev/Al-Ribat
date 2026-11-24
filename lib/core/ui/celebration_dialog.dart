import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import 'celebration_message.dart';

/// نافذة احتفال صغيرة تُعرض عند إكمال نشاط أو جلسة تركيز.
class CelebrationDialog extends StatefulWidget {
  const CelebrationDialog({super.key, required this.message});

  final String message;

  @override
  State<CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<CelebrationDialog> {
  late final ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 2))
      ..play();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ConfettiWidget(
            confettiController: _controller,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
          ),
          CelebrationMessage(message: widget.message),
        ],
      ),
    );
  }
}
