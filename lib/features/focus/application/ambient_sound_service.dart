import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AmbientSoundscape {
  silent,
  rain,
  waves,
  birds,
  clockTicks;

  String get arabicName {
    switch (this) {
      case AmbientSoundscape.silent:
        return 'صامت (تركيز عميق)';
      case AmbientSoundscape.rain:
        return 'مطر خفيف';
      case AmbientSoundscape.waves:
        return 'أمواج هادئة';
      case AmbientSoundscape.birds:
        return 'طبيعة وطيور';
      case AmbientSoundscape.clockTicks:
        return 'تكتكة ساعة هادئة';
    }
  }

  IconData get icon {
    switch (this) {
      case AmbientSoundscape.silent:
        return Icons.volume_off_rounded;
      case AmbientSoundscape.rain:
        return Icons.water_drop_rounded;
      case AmbientSoundscape.waves:
        return Icons.waves_rounded;
      case AmbientSoundscape.birds:
        return Icons.forest_rounded;
      case AmbientSoundscape.clockTicks:
        return Icons.timer_outlined;
    }
  }
}

class AmbientSoundState {
  final AmbientSoundscape soundscape;
  final double volume;
  final bool isPlaying;

  const AmbientSoundState({
    this.soundscape = AmbientSoundscape.silent,
    this.volume = 0.7,
    this.isPlaying = false,
  });

  AmbientSoundState copyWith({
    AmbientSoundscape? soundscape,
    double? volume,
    bool? isPlaying,
  }) {
    return AmbientSoundState(
      soundscape: soundscape ?? this.soundscape,
      volume: volume ?? this.volume,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}

final ambientSoundProvider =
    NotifierProvider<AmbientSoundNotifier, AmbientSoundState>(
  AmbientSoundNotifier.new,
);

class AmbientSoundNotifier extends Notifier<AmbientSoundState> {
  @override
  AmbientSoundState build() {
    return const AmbientSoundState();
  }

  void setSoundscape(AmbientSoundscape soundscape) {
    state = state.copyWith(
      soundscape: soundscape,
      isPlaying: soundscape != AmbientSoundscape.silent,
    );
    HapticFeedback.selectionClick();
  }

  void setVolume(double volume) {
    state = state.copyWith(volume: volume.clamp(0.0, 1.0));
  }

  void togglePlay() {
    if (state.soundscape == AmbientSoundscape.silent) {
      setSoundscape(AmbientSoundscape.rain);
    } else {
      state = state.copyWith(isPlaying: !state.isPlaying);
      HapticFeedback.lightImpact();
    }
  }

  void playCompletionChime() {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.heavyImpact();
  }
}
