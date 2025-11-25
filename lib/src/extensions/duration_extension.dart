/// Provides human-readable formatting utilities for [Duration] values.
///
/// This extension converts raw duration values into easy-to-read short strings,
/// such as `"01:23.450 min"`, `"45.200 sec"`, or `"300 ms"`.
extension HumanDuration on Duration {
  /// A reusable constant representing a duration of one second.
  static const Duration oneSecond = Duration(seconds: 1);

  /// Converts an integer into a two-digit formatted string.
  ///
  /// Pads with leading zeros when necessary. Example: `5` becomes `"05"`.
  static String twoDigits(int n) => n.toString().padLeft(2, '0');

  /// Converts an integer into a three-digit formatted string.
  ///
  /// Pads with leading zeros when necessary. Example: `7` becomes `"007"`.
  static String threeDigits(int n) => n.toString().padLeft(3, '0');

  /// Converts the duration into a compact human-readable time format.
  ///
  /// Formatting rules:
  /// * If duration contains minutes: returns `"mm:ss.SSS min"`
  /// * Else if contains seconds: returns `"ss.SSS sec"`
  /// * Else: returns `"X ms"`
  ///
  /// Examples:
  /// ```
  /// Duration(milliseconds: 350)       -> "350 ms"
  /// Duration(seconds: 5)              -> "05.000 sec"
  /// Duration(minutes: 1, seconds: 2)  -> "01:02.000 min"
  /// ```
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
