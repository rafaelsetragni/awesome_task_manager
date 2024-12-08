extension HumanDuration on Duration {
  static const Duration oneSecond = Duration(seconds: 1);

  static String twoDigits(int n) => n.toString().padLeft(2, '0');
  static String threeDigits(int n) => n.toString().padLeft(3, '0');

  String get humanString {
    String minutes = twoDigits(inMinutes);

    if (minutes != '00') {
      String seconds = twoDigits(inSeconds.remainder(60));
      String milliseconds = threeDigits(inMilliseconds.remainder(1000));
      return '$minutes:$seconds.$milliseconds min';
    }

    String seconds = twoDigits(inSeconds.remainder(60));
    if (seconds != '00') {
      String milliseconds = threeDigits(inMilliseconds.remainder(1000));
      return '$inSeconds.$milliseconds sec';
    }

    return '$inMilliseconds ms';
  }
}
