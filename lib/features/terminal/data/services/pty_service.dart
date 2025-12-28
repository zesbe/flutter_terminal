import 'dart:convert';
import 'dart:io';

import 'package:flutter_pty/flutter_pty.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for PtyService
final ptyServiceProvider = Provider<PtyService>((ref) {
  return PtyService();
});

/// Service for managing pseudo-terminal operations
class PtyService {
  Pty? _pty;
  bool _isRunning = false;

  /// Check if PTY is currently running
  bool get isRunning => _isRunning;

  /// Get the default shell for the platform
  String get defaultShell {
    if (Platform.isAndroid) {
      // Try to find available shells on Android
      final shells = [
        '/system/bin/sh',
        '/system/bin/bash',
      ];
      for (final shell in shells) {
        if (File(shell).existsSync()) {
          return shell;
        }
      }
      return '/system/bin/sh';
    } else if (Platform.isLinux || Platform.isMacOS) {
      return Platform.environment['SHELL'] ?? '/bin/bash';
    }
    return 'sh';
  }

  /// Get the current PTY instance
  Pty? get pty => _pty;

  /// Start a new PTY session
  Pty startPty({
    String? executable,
    List<String>? arguments,
    String? workingDirectory,
    Map<String, String>? environment,
    int rows = 24,
    int columns = 80,
  }) {
    // Close existing PTY if running
    if (_isRunning) {
      dispose();
    }

    final env = <String, String>{
      ...Platform.environment,
      'TERM': 'xterm-256color',
      'COLORTERM': 'truecolor',
      'LANG': 'en_US.UTF-8',
      'HOME': _getHomeDirectory(),
      ...?environment,
    };

    _pty = Pty.start(
      executable ?? defaultShell,
      arguments: arguments ?? [],
      workingDirectory: workingDirectory ?? _getHomeDirectory(),
      environment: env,
      rows: rows,
      columns: columns,
    );

    _isRunning = true;
    return _pty!;
  }

  /// Write data to PTY
  void write(String data) {
    if (_pty != null && _isRunning) {
      _pty!.write(const Utf8Encoder().convert(data));
    }
  }

  /// Write bytes to PTY
  void writeBytes(List<int> bytes) {
    if (_pty != null && _isRunning) {
      _pty!.write(Uint8List.fromList(bytes));
    }
  }

  /// Resize PTY
  void resize(int rows, int columns) {
    if (_pty != null && _isRunning) {
      _pty!.resize(rows, columns);
    }
  }

  /// Get home directory
  String _getHomeDirectory() {
    if (Platform.isAndroid) {
      // On Android, use app's data directory
      return '/data/data/com.example.flutter_terminal/files';
    }
    return Platform.environment['HOME'] ?? '/';
  }

  /// Dispose PTY
  void dispose() {
    if (_pty != null) {
      _pty!.kill();
      _pty = null;
      _isRunning = false;
    }
  }
}

/// Typedef for PTY output callback
typedef PtyOutputCallback = void Function(String data);
