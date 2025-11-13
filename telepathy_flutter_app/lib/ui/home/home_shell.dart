import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/deep_link_service.dart';
import '../../state/app_state_controller.dart';
import '../../state/status_controller.dart';
import '../settings/settings_screen.dart';
import 'pairing_view.dart';
import 'remote_status_view.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  bool _showSettings = false;

  void _toggleSettings() {
    setState(() {
      _showSettings = !_showSettings;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateController>();
    final statusController = context.watch<StatusController>();
    final DeepLinkService? deepLinkService = context.read<DeepLinkService?>();
    final isPaired = appState.isPaired;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _showSettings
          ? SettingsScreen(
              onClose: _toggleSettings,
              statusController: statusController,
              appState: appState,
            )
          : Scaffold(
              appBar: AppBar(
                title: Text(
                  isPaired ? 'Paired device' : 'Let’s pair',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_rounded),
                    onPressed: _toggleSettings,
                  ),
                ],
              ),
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeInBack,
                  child: isPaired
                      ? RemoteStatusView(
                          key: const ValueKey('remote-view'),
                          statusController: statusController,
                          pairingCode: appState.pairingCode!,
                        )
                      : PairingView(
                          key: const ValueKey('pairing-view'),
                          statusController: statusController,
                          appState: appState,
                          deepLinkService: deepLinkService,
                        ),
                ),
              ),
            ),
    );
  }
}

