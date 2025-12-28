import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';

/// Provider for BootstrapService
final bootstrapServiceProvider = Provider<BootstrapService>((ref) {
  return BootstrapService();
});

/// Provider for bootstrap state
final bootstrapStateProvider = StateNotifierProvider<BootstrapStateNotifier, BootstrapState>((ref) {
  return BootstrapStateNotifier(ref.read(bootstrapServiceProvider));
});

/// Bootstrap state
enum BootstrapStatus {
  initial,
  checking,
  notInstalled,
  downloading,
  extracting,
  configuring,
  completed,
  error,
}

class BootstrapState {
  final BootstrapStatus status;
  final double progress;
  final String message;
  final String? error;

  const BootstrapState({
    this.status = BootstrapStatus.initial,
    this.progress = 0.0,
    this.message = '',
    this.error,
  });

  BootstrapState copyWith({
    BootstrapStatus? status,
    double? progress,
    String? message,
    String? error,
  }) {
    return BootstrapState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      error: error,
    );
  }
}

class BootstrapStateNotifier extends StateNotifier<BootstrapState> {
  final BootstrapService _service;

  BootstrapStateNotifier(this._service) : super(const BootstrapState());

  Future<void> checkAndInstall() async {
    state = state.copyWith(status: BootstrapStatus.checking, message: 'Checking installation...');

    final isInstalled = await _service.isBootstrapInstalled();
    if (isInstalled) {
      state = state.copyWith(status: BootstrapStatus.completed, message: 'Ready');
      return;
    }

    state = state.copyWith(status: BootstrapStatus.notInstalled, message: 'Bootstrap not installed');
  }

  Future<void> install() async {
    try {
      // Download
      state = state.copyWith(
        status: BootstrapStatus.downloading,
        message: 'Downloading BusyBox...',
        progress: 0.0,
      );

      await _service.downloadBootstrap(
        onProgress: (received, total) {
          final progress = total > 0 ? received / total : 0.0;
          state = state.copyWith(
            progress: progress,
            message: 'Downloading... ${(progress * 100).toStringAsFixed(0)}%',
          );
        },
      );

      // Configure
      state = state.copyWith(
        status: BootstrapStatus.configuring,
        message: 'Configuring environment...',
        progress: 0.8,
      );

      await _service.configureEnvironment();

      // Mark as completed
      await _service.markBootstrapCompleted();

      state = state.copyWith(
        status: BootstrapStatus.completed,
        message: 'Installation complete!',
        progress: 1.0,
      );
    } catch (e) {
      state = state.copyWith(
        status: BootstrapStatus.error,
        message: 'Installation failed',
        error: e.toString(),
      );
    }
  }
}

/// Service for managing bootstrap/Linux environment
class BootstrapService {
  late String _baseDir;
  late String _prefixPath;
  late String _homePath;
  late String _tmpPath;
  late String _binPath;

  final Dio _dio = Dio();

  /// Initialize paths
  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _baseDir = appDir.path;
    _prefixPath = '$_baseDir/${AppConstants.prefixDirName}';
    _homePath = '$_baseDir/${AppConstants.homeDirName}';
    _tmpPath = '$_baseDir/${AppConstants.tmpDirName}';
    _binPath = '$_prefixPath/${AppConstants.binDirName}';

    // Create directories
    await Directory(_prefixPath).create(recursive: true);
    await Directory(_homePath).create(recursive: true);
    await Directory(_tmpPath).create(recursive: true);
    await Directory(_binPath).create(recursive: true);
    await Directory('$_prefixPath/${AppConstants.libDirName}').create(recursive: true);
  }

  /// Get paths
  String get baseDir => _baseDir;
  String get prefixPath => _prefixPath;
  String get homePath => _homePath;
  String get binPath => _binPath;
  String get tmpPath => _tmpPath;

  /// Check if bootstrap is installed
  Future<bool> isBootstrapInstalled() async {
    await initialize();

    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(AppConstants.prefBootstrapCompleted) ?? false;

    if (!completed) return false;

    // Verify busybox exists
    final busybox = File('$_binPath/busybox');
    return busybox.existsSync();
  }

  /// Get the appropriate download URL for device architecture
  String _getDownloadUrl() {
    // Detect architecture
    final arch = Platform.version.toLowerCase();
    if (arch.contains('arm64') || arch.contains('aarch64')) {
      return AppConstants.busyboxArm64Url;
    } else if (arch.contains('arm')) {
      return AppConstants.busyboxArmUrl;
    } else if (arch.contains('x86_64') || arch.contains('x64')) {
      return AppConstants.busyboxX86_64Url;
    }
    // Default to arm64 for modern devices
    return AppConstants.busyboxArm64Url;
  }

  /// Download bootstrap (BusyBox)
  Future<void> downloadBootstrap({
    Function(int received, int total)? onProgress,
  }) async {
    await initialize();

    final url = _getDownloadUrl();
    final busyboxPath = '$_binPath/busybox';

    await _dio.download(
      url,
      busyboxPath,
      onReceiveProgress: onProgress,
    );

    // Make executable
    await Process.run('chmod', ['+x', busyboxPath]);
  }

  /// Configure environment - create symlinks for busybox applets
  Future<void> configureEnvironment() async {
    final busyboxPath = '$_binPath/busybox';
    final busybox = File(busyboxPath);

    if (!busybox.existsSync()) {
      throw Exception('BusyBox not found');
    }

    // Get list of applets from busybox
    final result = await Process.run(busyboxPath, ['--list']);
    if (result.exitCode != 0) {
      throw Exception('Failed to get BusyBox applets: ${result.stderr}');
    }

    final applets = (result.stdout as String).split('\n').where((s) => s.isNotEmpty).toList();

    // Create symlinks for each applet
    for (final applet in applets) {
      final linkPath = '$_binPath/$applet';
      final link = Link(linkPath);

      try {
        if (await link.exists()) {
          await link.delete();
        }
        await link.create(busyboxPath);
      } catch (e) {
        // Some applets might fail, continue with others
        print('Failed to create symlink for $applet: $e');
      }
    }

    // Create shell script wrapper for sh
    final shScript = '''#!/system/bin/sh
exec $_binPath/busybox sh "\$@"
''';
    final shPath = '$_binPath/sh';
    await File(shPath).writeAsString(shScript);
    await Process.run('chmod', ['+x', shPath]);

    // Create .profile
    final profile = '''
export HOME=$_homePath
export PREFIX=$_prefixPath
export PATH=$_binPath:\$PATH
export TMPDIR=$_tmpPath
export TERM=xterm-256color
export LANG=en_US.UTF-8

cd \$HOME
''';
    await File('$_homePath/.profile').writeAsString(profile);

    // Create .bashrc (alias for ash)
    final bashrc = '''
# Flutter Terminal
PS1='\\w \$ '
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
''';
    await File('$_homePath/.bashrc').writeAsString(bashrc);
  }

  /// Mark bootstrap as completed
  Future<void> markBootstrapCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefBootstrapCompleted, true);
  }

  /// Get environment variables for terminal
  Map<String, String> getEnvironment() {
    return {
      AppConstants.envHome: _homePath,
      AppConstants.envPrefix: _prefixPath,
      AppConstants.envPath: '$_binPath:/system/bin:/system/xbin',
      AppConstants.envTmpDir: _tmpPath,
      AppConstants.envTerm: 'xterm-256color',
      AppConstants.envLang: 'en_US.UTF-8',
    };
  }

  /// Get shell path
  String getShellPath() {
    final busybox = '$_binPath/busybox';
    if (File(busybox).existsSync()) {
      return busybox;
    }
    return '/system/bin/sh';
  }

  /// Get shell arguments
  List<String> getShellArgs() {
    final busybox = '$_binPath/busybox';
    if (File(busybox).existsSync()) {
      return ['ash', '--login'];
    }
    return [];
  }
}
