import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/bootstrap_service.dart';
import '../../../terminal/presentation/pages/terminal_page.dart';

/// Setup wizard page for first-run bootstrap installation
class SetupWizardPage extends ConsumerStatefulWidget {
  const SetupWizardPage({super.key});

  @override
  ConsumerState<SetupWizardPage> createState() => _SetupWizardPageState();
}

class _SetupWizardPageState extends ConsumerState<SetupWizardPage> {
  @override
  void initState() {
    super.initState();
    // Check bootstrap status on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bootstrapStateProvider.notifier).checkAndInstall();
    });
  }

  void _startInstallation() {
    ref.read(bootstrapStateProvider.notifier).install();
  }

  void _goToTerminal() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TerminalPage()),
    );
  }

  void _skipSetup() {
    _goToTerminal();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bootstrapStateProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              const Icon(
                Icons.terminal,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Flutter Terminal',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Terminal Emulator for Android',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 48),

              // Status based content
              _buildContent(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BootstrapState state) {
    switch (state.status) {
      case BootstrapStatus.initial:
      case BootstrapStatus.checking:
        return const Column(
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Checking installation...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        );

      case BootstrapStatus.notInstalled:
        return Column(
          children: [
            const Text(
              'Install Linux Environment',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Download BusyBox to enable Linux commands:\n'
              'ls, cat, grep, awk, sed, wget, tar, gzip, and 300+ more',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[400],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Download size: ~2 MB',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startInstallation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Install',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _skipSetup,
              child: Text(
                'Skip (use basic Android shell)',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          ],
        );

      case BootstrapStatus.downloading:
      case BootstrapStatus.extracting:
      case BootstrapStatus.configuring:
        return Column(
          children: [
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: state.progress,
                backgroundColor: Colors.grey[800],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              '${(state.progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        );

      case BootstrapStatus.completed:
        // Auto navigate to terminal
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _goToTerminal();
        });
        return Column(
          children: [
            const Icon(
              Icons.check_circle,
              size: 60,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              'Installation Complete!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Starting terminal...',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        );

      case BootstrapStatus.error:
        return Column(
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Installation Failed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _startInstallation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Retry'),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: _skipSetup,
                  child: Text(
                    'Skip',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }
}
