import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../state/app_state_controller.dart';
import '../../state/status_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.onClose,
    required this.statusController,
    required this.appState,
  });

  final VoidCallback onClose;
  final StatusController statusController;
  final AppStateController appState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: onClose,
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        children: [
          _SettingsIllustration(appState: appState),
          const SizedBox(height: 28),
          Text(
            'Pairing',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: const Color(0xFF1B1F2B),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      appState.isPaired
                          ? Icons.link_rounded
                          : Icons.link_off_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        appState.isPaired
                            ? 'Paired to code ${appState.pairingCode}'
                            : 'Not paired yet',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: appState.isPaired
                      ? () async {
                          await statusController.unpair();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Device unpaired.'),
                              ),
                            );
                          }
                        }
                      : null,
                  icon: const Icon(Icons.link_off_rounded),
                  label: const Text('Unpair this device'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Role',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: const Color(0xFF1B1F2B),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose how this phone behaves when paired.',
                ),
                const SizedBox(height: 16),
                ToggleButtons(
                  isSelected: [
                    appState.isRemoteController,
                    !appState.isRemoteController,
                  ],
                  onPressed: appState.isPaired
                      ? null
                      : (index) {
                          final remote = index == 0;
                          appState.setRemoteController(remote);
                        },
                  borderRadius: BorderRadius.circular(18),
                  constraints: const BoxConstraints(
                    minWidth: 120,
                    minHeight: 44,
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Remote'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Receiver'),
                    ),
                  ],
                ),
                if (appState.isPaired) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Unpair to change the role.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Permissions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: const Color(0xFF1B1F2B),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    statusController.permissionsGranted
                        ? Icons.verified_user_rounded
                        : Icons.shield_moon_rounded,
                    color: statusController.permissionsGranted
                        ? const Color(0xFF64FFDA)
                        : Colors.amberAccent,
                  ),
                  title: const Text('Do Not Disturb access'),
                  subtitle: Text(
                    statusController.permissionsGranted
                        ? 'Ready to adjust ringer mode when receiving commands.'
                        : 'Needed if this device is the receiver.',
                  ),
                  trailing: FilledButton.tonal(
                    onPressed: statusController.permissionsGranted
                        ? null
                        : () async {
                            final granted =
                                await statusController.requestPolicyPermissions();
                            if (!granted) {
                              await statusController.openPolicySettings();
                            }
                          },
                    child: const Text('Grant'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Account',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: const Color(0xFF1B1F2B),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer<AuthService>(
                  builder: (context, authService, child) {
                    final user = authService.currentUser;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF5E5CE6),
                        child: user?.photoURL != null
                            ? ClipOval(
                                child: Image.network(
                                  user!.photoURL!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.person_rounded,
                                      color: Colors.white,
                                    );
                                  },
                                ),
                              )
                            : const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                              ),
                      ),
                      title: Text(
                        user?.displayName ?? 'User',
                        style: theme.textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        user?.email ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final authService = context.read<AuthService>();
                    try {
                      // Unpair device before signing out
                      if (appState.isPaired) {
                        await statusController.unpair();
                      }
                      
                      await authService.signOut();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Signed out successfully'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to sign out: $e'),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsIllustration extends StatelessWidget {
  const _SettingsIllustration({required this.appState});

  final AppStateController appState;

  @override
  Widget build(BuildContext context) {
    final roleText =
        appState.isRemoteController ? 'Remote controller' : 'Receiver';

    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF5E5CE6),
            Color(0xFF8E8CFF),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -20,
            top: -24,
            child: Icon(
              Icons.settings_suggest_rounded,
              size: 180,
              color: Colors.white.withOpacity(0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text(
                    roleText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Manage pairing\nand permissions',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

