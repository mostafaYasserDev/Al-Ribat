part of '../prayer_repository_impl.dart';

_PrayerDayData _computePrayerForDate(
  Coordinates coordinates,
  AppSettings settings,
  DateTime date,
) {
  final params = _toPrayerMethod(settings.prayerMethod).getParameters()
    ..madhab = Madhab.shafi;
  final dc = DateComponents(date.year, date.month, date.day);
  final prayerTimes = PrayerTimes(coordinates, dc, params);
  return _PrayerDayData(
    sunrise: prayerTimes.sunrise,
    prayers: [
      PrayerTime(phase: PrayerPhase.fajr, time: prayerTimes.fajr),
      PrayerTime(phase: PrayerPhase.dhuhr, time: prayerTimes.dhuhr),
      PrayerTime(phase: PrayerPhase.asr, time: prayerTimes.asr),
      PrayerTime(phase: PrayerPhase.maghrib, time: prayerTimes.maghrib),
      PrayerTime(phase: PrayerPhase.isha, time: prayerTimes.isha),
    ],
  );
}

CalculationMethod _toPrayerMethod(PrayerCalculationMethod method) {
  switch (method) {
    case PrayerCalculationMethod.muslimWorldLeague:
      return CalculationMethod.muslim_world_league;
    case PrayerCalculationMethod.egyptian:
      return CalculationMethod.egyptian;
    case PrayerCalculationMethod.karachi:
      return CalculationMethod.karachi;
    case PrayerCalculationMethod.ummAlQura:
      return CalculationMethod.umm_al_qura;
    case PrayerCalculationMethod.dubai:
      return CalculationMethod.dubai;
  }
}
