/// MM:SS for a code-request cooldown. A fraction waits until the next whole second.
String formatCodeRepeatClock(num seconds) {
  if (seconds.isNaN || seconds.isInfinite || seconds <= 0) {
    return '00:00';
  }
  final whole = seconds.floor();
  final minutes = whole ~/ 60;
  final rest = whole % 60;
  return '${minutes.toString().padLeft(2, '0')}:'
      '${rest.toString().padLeft(2, '0')}';
}
