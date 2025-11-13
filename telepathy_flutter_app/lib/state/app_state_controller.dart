import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Coordinates onboarding and persistent pairing metadata.
class AppStateController extends ChangeNotifier {
  AppStateController();

  static const _onboardingKey = 'telepathy_onboarding_complete';
  static const _pairingCodeKey = 'telepathy_active_pairing_code';
  static const _remoteRoleKey = 'telepathy_is_remote_controller';

  SharedPreferences? _prefs;
  bool _onboardingComplete = false;
  String? _pairingCode;
  bool _isRemoteController = true;

  bool get isInitialized => _prefs != null;
  bool get onboardingComplete => _onboardingComplete;
  bool get isPaired => _pairingCode != null && _pairingCode!.isNotEmpty;
  String? get pairingCode => _pairingCode;
  bool get isRemoteController => _isRemoteController;

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    _onboardingComplete = _prefs?.getBool(_onboardingKey) ?? false;
    _pairingCode = _prefs?.getString(_pairingCodeKey);
    _isRemoteController = _prefs?.getBool(_remoteRoleKey) ?? true;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _onboardingComplete = true;
    await _prefs?.setBool(_onboardingKey, true);
    notifyListeners();
  }

  Future<void> setPairingCode(String code) async {
    final normalized = code.trim().toUpperCase();
    _pairingCode = normalized;
    await _prefs?.setString(_pairingCodeKey, normalized);
    notifyListeners();
  }

  Future<void> setRemoteController(bool isRemote) async {
    _isRemoteController = isRemote;
    await _prefs?.setBool(_remoteRoleKey, isRemote);
    notifyListeners();
  }

  Future<void> clearPairing() async {
    _pairingCode = null;
    _isRemoteController = true;
    await _prefs?.remove(_pairingCodeKey);
    await _prefs?.remove(_remoteRoleKey);
    notifyListeners();
  }
}

