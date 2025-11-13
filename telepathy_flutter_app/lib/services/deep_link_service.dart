import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final StreamController<String?> _roomCodeController = StreamController<String?>.broadcast();
  Stream<String?> get roomCodeStream => _roomCodeController.stream;

  final _appLinks = AppLinks();
  StreamSubscription<Uri?>? _sub;

  Future<void> initialize() async {
    // Handle initial link when app is launched from a deep link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    // Handle incoming links while app is running
    _sub = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    }, onError: (err) {
      debugPrint('Error handling deep link: $err');
    });
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Received deep link: $uri');

    // Check for telepathy://join/room/{code} format
    if (uri.scheme == 'telepathy' && uri.host == 'join' && uri.path.startsWith('/room/')) {
      String roomCode = uri.path.substring('/room/'.length);
      _roomCodeController.add(roomCode);
      return;
    }

    // Check for https://telepathy.join/room/{code} format
    if (uri.scheme == 'https' && uri.host == 'telepathy.join' && uri.path.startsWith('/room/')) {
      String roomCode = uri.path.substring('/room/'.length);
      _roomCodeController.add(roomCode);
      return;
    }

    debugPrint('Unhandled deep link format: $uri');
  }

  String createShareableLink(String roomCode) {
    // Create a URL-encoded sharing link
    return 'https://telepathy.join/room/$roomCode';
  }

  String createWhatsAppMessage(String roomCode) {
    String link = createShareableLink(roomCode);
    return 'Join my Telepathy room: $link';
  }

  void dispose() {
    _sub?.cancel();
    _roomCodeController.close();
  }
}
