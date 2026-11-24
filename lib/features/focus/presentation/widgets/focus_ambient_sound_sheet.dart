import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/ambient_sound_service.dart';

class FocusAmbientSoundSheet extends ConsumerWidget {
  const FocusAmbientSoundSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const FocusAmbientSoundSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soundState = ref.watch(ambientSoundProvider);
    final soundNotifier = ref.read(ambientSoundProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.spatial_audio_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'أجواء صوتية مهدئة للتركيز',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AmbientSoundscape.values.map((sound) {
                final isSelected = soundState.soundscape == sound;
                return ChoiceChip(
                  avatar: Icon(
                    sound.icon,
                    size: 18,
                    color: isSelected ? Colors.white : colorScheme.primary,
                  ),
                  label: Text(sound.arabicName),
                  selected: isSelected,
                  onSelected: (_) => soundNotifier.setSoundscape(sound),
                );
              }).toList(),
            ),
            if (soundState.soundscape != AmbientSoundscape.silent) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.volume_down_rounded, size: 20),
                  Expanded(
                    child: Slider(
                      value: soundState.volume,
                      onChanged: (val) => soundNotifier.setVolume(val),
                    ),
                  ),
                  const Icon(Icons.volume_up_rounded, size: 20),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
