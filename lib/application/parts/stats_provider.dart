part of '../providers.dart';

final statsProvider = Provider<StatsSnapshot>((ref) {
  return _buildStatsSnapshot(ref);
});
