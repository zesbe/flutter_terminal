import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

import '../../data/services/pty_service.dart';
import '../../../../core/themes/terminal_themes.dart';
import '../widgets/extra_keys_bar.dart';

/// Main terminal page
class TerminalPage extends ConsumerStatefulWidget {
  const TerminalPage({super.key});

  @override
  ConsumerState<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends ConsumerState<TerminalPage> {
  late Terminal _terminal;
  late TerminalController _terminalController;
  Pty? _pty;
  final FocusNode _focusNode = FocusNode();

  // Settings
  double _fontSize = 14.0;
  String _currentTheme = 'Default';
  bool _showExtraKeys = true;

  @override
  void initState() {
    super.initState();
    _initTerminal();
  }

  void _initTerminal() {
    _terminal = Terminal(
      maxLines: 10000,
    );

    _terminalController = TerminalController();

    // Start PTY
    _startPty();

    // Handle terminal title changes
    _terminal.onTitleChange = (title) {
      // Could update app bar title here
    };

    // Handle terminal resize
    _terminal.onResize = (width, height, pixelWidth, pixelHeight) {
      _pty?.resize(height, width);
    };

    // Handle terminal output (input from user)
    _terminal.onOutput = (data) {
      _pty?.write(const Utf8Encoder().convert(data));
    };
  }

  void _startPty() {
    final ptyService = ref.read(ptyServiceProvider);

    _pty = ptyService.startPty(
      rows: 24,
      columns: 80,
    );

    // Connect PTY output to terminal
    _pty!.output.cast<List<int>>().transform(const Utf8Decoder()).listen(
      (data) {
        _terminal.write(data);
      },
      onError: (error) {
        _terminal.write('\r\n[Error: $error]\r\n');
      },
      onDone: () {
        _terminal.write('\r\n[Session ended]\r\n');
      },
    );

    // Write welcome message
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _terminal.write('\x1B[1;32mFlutter Terminal\x1B[0m\r\n');
        _terminal.write('Type commands to get started...\r\n\r\n');
      }
    });
  }

  void _restartPty() {
    _pty?.kill();
    _terminal.buffer.clear();
    _terminal.buffer.setCursor(0, 0);
    _startPty();
  }

  void _sendSpecialKey(String key) {
    switch (key) {
      case 'ESC':
        _terminal.keyInput(TerminalKey.escape);
        break;
      case 'TAB':
        _terminal.keyInput(TerminalKey.tab);
        break;
      case 'CTRL':
        // Toggle CTRL modifier - handled in extra keys bar
        break;
      case 'ALT':
        // Toggle ALT modifier - handled in extra keys bar
        break;
      case 'UP':
        _terminal.keyInput(TerminalKey.arrowUp);
        break;
      case 'DOWN':
        _terminal.keyInput(TerminalKey.arrowDown);
        break;
      case 'LEFT':
        _terminal.keyInput(TerminalKey.arrowLeft);
        break;
      case 'RIGHT':
        _terminal.keyInput(TerminalKey.arrowRight);
        break;
      case 'HOME':
        _terminal.keyInput(TerminalKey.home);
        break;
      case 'END':
        _terminal.keyInput(TerminalKey.end);
        break;
      case 'PGUP':
        _terminal.keyInput(TerminalKey.pageUp);
        break;
      case 'PGDN':
        _terminal.keyInput(TerminalKey.pageDown);
        break;
    }
    _focusNode.requestFocus();
  }

  void _sendCtrlKey(String char) {
    // Send CTRL+char sequence
    final code = char.toUpperCase().codeUnitAt(0) - 64;
    if (code > 0 && code < 32) {
      _pty?.write(Uint8List.fromList([code]));
    }
    _focusNode.requestFocus();
  }

  void _copyToClipboard() {
    final selection = _terminalController.selection;
    if (selection != null) {
      final text = _terminal.buffer.getText(selection);
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _pty?.write(const Utf8Encoder().convert(data!.text!));
    }
  }

  void _showSettingsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Terminal Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Font size
              Row(
                children: [
                  const Text('Font Size:', style: TextStyle(color: Colors.white)),
                  Expanded(
                    child: Slider(
                      value: _fontSize,
                      min: 8,
                      max: 24,
                      divisions: 16,
                      label: _fontSize.round().toString(),
                      onChanged: (value) {
                        setModalState(() => _fontSize = value);
                        setState(() {});
                      },
                    ),
                  ),
                  Text(
                    _fontSize.round().toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),

              // Theme selection
              const SizedBox(height: 8),
              const Text('Theme:', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: TerminalThemes.all.keys.map((name) {
                  return ChoiceChip(
                    label: Text(name),
                    selected: _currentTheme == name,
                    onSelected: (selected) {
                      if (selected) {
                        setModalState(() => _currentTheme = name);
                        setState(() {});
                      }
                    },
                  );
                }).toList(),
              ),

              // Show extra keys toggle
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text(
                  'Show Extra Keys',
                  style: TextStyle(color: Colors.white),
                ),
                value: _showExtraKeys,
                onChanged: (value) {
                  setModalState(() => _showExtraKeys = value);
                  setState(() {});
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pty?.kill();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = TerminalThemes.all[_currentTheme] ?? TerminalThemes.defaultTheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        title: Text(
          'Flutter Terminal',
          style: TextStyle(color: theme.foreground),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.content_copy, color: theme.foreground),
            onPressed: _copyToClipboard,
            tooltip: 'Copy',
          ),
          IconButton(
            icon: Icon(Icons.content_paste, color: theme.foreground),
            onPressed: _pasteFromClipboard,
            tooltip: 'Paste',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: theme.foreground),
            onPressed: _restartPty,
            tooltip: 'Restart',
          ),
          IconButton(
            icon: Icon(Icons.settings, color: theme.foreground),
            onPressed: _showSettingsDialog,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Terminal view
            Expanded(
              child: TerminalView(
                _terminal,
                controller: _terminalController,
                focusNode: _focusNode,
                autofocus: true,
                theme: theme,
                textStyle: TerminalStyle(
                  fontSize: _fontSize,
                  fontFamily: 'monospace',
                ),
                padding: const EdgeInsets.all(4),
                alwaysShowCursor: true,
                deleteDetection: Platform.isAndroid,
              ),
            ),

            // Extra keys bar
            if (_showExtraKeys)
              ExtraKeysBar(
                onKeyPressed: _sendSpecialKey,
                onCtrlKeyPressed: _sendCtrlKey,
                backgroundColor: theme.background,
                foregroundColor: theme.foreground,
              ),
          ],
        ),
      ),
    );
  }
}
