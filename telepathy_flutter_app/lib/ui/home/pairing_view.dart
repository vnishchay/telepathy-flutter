import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/deep_link_service.dart';
import '../../state/app_state_controller.dart';
import '../../state/status_controller.dart';

class PairingView extends StatefulWidget {
  const PairingView({
    super.key,
    required this.statusController,
    required this.appState,
    this.deepLinkService,
  });

  final StatusController statusController;
  final AppStateController appState;
  final DeepLinkService? deepLinkService;

  @override
  State<PairingView> createState() => _PairingViewState();
}

class _PairingViewState extends State<PairingView>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _codeController;
  late final AnimationController _orbController;
  bool _isRemote = true;
  String? _generatedCode;

  @override
  void initState() {
    super.initState();
    _isRemote = widget.appState.isRemoteController;
    _codeController = TextEditingController();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _orbController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    FocusScope.of(context).unfocus();
    try {
      final code = await widget.statusController.createRoom();
      setState(() {
        _generatedCode = code;
      });

      // Share via WhatsApp
      if (widget.deepLinkService != null) {
        final message = widget.deepLinkService!.createWhatsAppMessage(code);
        await Share.share(message, subject: 'Join my Telepathy room');
      } else {
        // Fallback: share just the code
        await Share.share(code, subject: 'Join my Telepathy room');
      }
    } catch (e) {
      // Error is handled by StatusController
    }
  }

  Future<void> _joinRoom() async {
    FocusScope.of(context).unfocus();
    await widget.statusController.joinRoom(_codeController.text);
  }

  Future<void> _showCodeOptions(String code) async {
    return showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.content_copy),
                title: const Text('Copy Code'),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied to clipboard')),
                    );
                    Navigator.of(context).pop();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share Code'),
                onTap: () async {
                  if (widget.deepLinkService != null) {
                    final message = widget.deepLinkService!.createWhatsAppMessage(code);
                    await Share.share(message, subject: 'Join my Telepathy room');
                  } else {
                    // Fallback: share just the code
                    await Share.share(code, subject: 'Join my Telepathy room');
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.statusController;
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Chip(
                    avatar: const Icon(Icons.link_off, color: Colors.white),
                    label: const Text('Not paired'),
                    backgroundColor: const Color(0xFF1B1F2B),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 220,
                  child: AnimatedBuilder(
                    animation: _orbController,
                    builder: (context, child) {
                      final rotation = _orbController.value * 2 * pi;
                      return Transform.rotate(
                        angle: rotation,
                        child: child,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: const [
                            Color(0x335E5CE6),
                            Color(0xFF1B1F2B),
                          ],
                          radius: 0.85,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          height: 160,
                          width: 160,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF5E5CE6),
                                Color(0xFF8E8CFF),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF5E5CE6).withOpacity(0.35),
                                blurRadius: 42,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.devices_other_rounded,
                            size: 72,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  _isRemote ? 'Create Room' : 'Join Room',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                if (_isRemote) ...[
                  // Remote device - show generated code or create button
                  if (_generatedCode != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Share this code with the other device:',
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _showCodeOptions(_generatedCode!),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _generatedCode!,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  letterSpacing: 2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the share button above to send this code via WhatsApp. The other device will be able to join automatically when they tap the link.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Waiting for the other device to join...',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Click "Create Room" to generate a secure 14-character code that the other device can use to join.',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ] else ...[
                  // Receiver device - input field for room code
                  TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 14,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                    ],
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.confirmation_number_rounded),
                      hintText: 'Enter 14-character room code',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ask the remote device to create a room and share the code with you.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _isRemote,
                  onChanged: (value) {
                    setState(() {
                      _isRemote = value;
                    });
                  },
                  title: const Text('This phone controls the other device'),
                  subtitle: const Text(
                    'Turn off to let this phone follow the remote controller.',
                  ),
                ),
                const SizedBox(height: 24),
                if (_isRemote) ...[
                  ElevatedButton(
                    onPressed: status.isLoading || _generatedCode != null ? null : _createRoom,
                    child: status.isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Room'),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: status.isLoading ? null : _joinRoom,
                    child: status.isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Join Room'),
                  ),
                ],
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: status.errorMessage == null
                      ? const SizedBox.shrink()
                      : Container(
                          key: ValueKey(status.errorMessage),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Colors.redAccent),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  status.errorMessage!,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: status.clearError,
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}


