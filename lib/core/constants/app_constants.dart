/// Application constants
class AppConstants {
  AppConstants._();

  /// App name
  static const String appName = 'Flutter Terminal';

  /// Bootstrap URLs - using pre-built binaries
  /// BusyBox provides most common Linux commands
  static const String busyboxArm64Url =
      'https://busybox.net/downloads/binaries/1.35.0-arm64-linux-musl/busybox';
  static const String busyboxArmUrl =
      'https://busybox.net/downloads/binaries/1.35.0-armv7l-linux-musleabihf/busybox';
  static const String busyboxX86_64Url =
      'https://busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox';

  /// Directory names
  static const String prefixDirName = 'usr';
  static const String homeDirName = 'home';
  static const String tmpDirName = 'tmp';
  static const String binDirName = 'bin';
  static const String libDirName = 'lib';

  /// Shell
  static const String defaultShell = 'sh';

  /// Environment variable names
  static const String envHome = 'HOME';
  static const String envPrefix = 'PREFIX';
  static const String envPath = 'PATH';
  static const String envTerm = 'TERM';
  static const String envLang = 'LANG';
  static const String envTmpDir = 'TMPDIR';

  /// Shared preferences keys
  static const String prefBootstrapCompleted = 'bootstrap_completed';
  static const String prefCurrentTheme = 'current_theme';
  static const String prefFontSize = 'font_size';
  static const String prefShowExtraKeys = 'show_extra_keys';
}
