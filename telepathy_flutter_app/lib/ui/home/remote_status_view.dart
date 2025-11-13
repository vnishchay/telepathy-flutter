import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/audio_profile.dart';
import '../../services/deep_link_service.dart';
import '../../state/status_controller.dart';

class RemoteStatusView extends StatelessWidget {
  const RemoteStatusView({
    super.key,
    required this.statusController,
    required this.pairingCode,
  });

  final StatusController statusController;
  final String pairingCode;

  Future<void> _showCodeOptions(BuildContext context) async {
    final deepLinkService = DeepLinkService();

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
                  await Clipboard.setData(ClipboardData(text: pairingCode));
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
                  final message = deepLinkService.createWhatsAppMessage(pairingCode);
                  await Share.share(message, subject: 'Join my Telepathy room');
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
    final theme = Theme.of(context);
    final status = context.watch<StatusController>();
    final profile = status.partnerProfile;
    final colorPair = _profileGradient(profile);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Center(
          child: InkWell(
            onTap: () => _showCodeOptions(context),
            borderRadius: BorderRadius.circular(16),
            child: Chip(
              avatar: const Icon(Icons.link_rounded, color: Colors.white),
              label: Text('Code $pairingCode'),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: GestureDetector(
            onTap: status.canCyclePartnerProfile
                ? statusController.cyclePartnerProfile
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  colors: colorPair,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorPair.last.withOpacity(0.35),
                    blurRadius: 48,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _profileIcon(profile),
                    size: 84,
                    color: Colors.white,
                  ),
                  const Spacer(),
                  Text(
                    'Paired phone',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _profileLabel(profile),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    status.isRemote
                        ? 'Tap the icon to cycle ring modes'
                        : 'Awaiting commands from remote controller',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Icon(
              status.isConnected
                  ? Icons.bolt_rounded
                  : Icons.wifi_off_rounded,
              color:
                  status.isConnected ? const Color(0xFF64FFDA) : Colors.amber,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                status.isConnected
                    ? 'Live connection active'
                    : 'Waiting for partner to come online',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        if (status.errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

List<Color> _profileGradient(AudioProfile profile) {
  switch (profile) {
    case AudioProfile.ringing:
      return const [Color(0xFF5E5CE6), Color(0xFF8E8CFF)];
    case AudioProfile.vibrate:
      return const [Color(0xFFFF8A65), Color(0xFFFFC400)];
    case AudioProfile.silent:
      return const [Color(0xFFEF5350), Color(0xFFE53935)];
  }
}

IconData _profileIcon(AudioProfile profile) {
  switch (profile) {
    case AudioProfile.ringing:
      return Icons.volume_up_rounded;
    case AudioProfile.vibrate:
      return Icons.vibration_rounded;
    case AudioProfile.silent:
      return Icons.volume_off_rounded;
  }
}

String _profileLabel(AudioProfile profile) {
  switch (profile) {
    case AudioProfile.ringing:
      return 'Ringing';
    case AudioProfile.vibrate:
      return 'Vibrate';
    case AudioProfile.silent:
      return 'Silent';
  }
}

