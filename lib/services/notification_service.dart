import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

typedef PushAlertCallback = void Function({
  required String titulo,
  required String descricao,
  String prioridade,
  String tipo,
});

/// Serviço de push via FCM.
///
/// iOS (passos manuais):
/// 1. Xcode → Runner → Signing & Capabilities → Push Notifications + Background Modes (Remote notifications)
/// 2. Firebase Console → Project Settings → Cloud Messaging → upload da APNs Authentication Key (.p8)
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channelId = 'medistock_alertas';
  static const _channelName = 'Alertas MediStock';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _token;
  String? _lastError;
  PushAlertCallback? _onPushAlert;
  VoidCallback? _onNavigateToAlertas;
  void Function(String titulo)? _onForegroundSnackBar;

  String? get token => _token;
  String? get lastError => _lastError;
  bool get isReady => _token != null && _token!.isNotEmpty;

  Future<void> initialize() async {
    _lastError = null;

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Alertas e avisos do sistema MediStock',
      importance: Importance.high,
    );

    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(androidChannel);
      await androidPlugin?.requestNotificationsPermission();
    }

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (_) => _onNavigateToAlertas?.call(),
    );

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await fetchToken();
    _messaging.onTokenRefresh.listen((newToken) {
      _token = newToken;
      _lastError = null;
    });
  }

  Future<String?> fetchToken({bool forceRefresh = false}) async {
    _lastError = null;

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        if (Platform.isIOS) {
          await _waitForApnsToken();
        }

        if (forceRefresh) {
          await _messaging.deleteToken();
        }

        final token = await _messaging.getToken();
        if (token != null && token.isNotEmpty) {
          _token = token;
          debugPrint('FCM token obtido com sucesso');
          return token;
        }
      } catch (e, stack) {
        debugPrint('Erro ao obter FCM token (tentativa ${attempt + 1}): $e');
        debugPrint('$stack');
        _lastError = e.toString();
      }

      if (attempt < 2) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    _lastError ??= _mensagemErroPlataforma();
    return null;
  }

  Future<void> _waitForApnsToken() async {
    for (var i = 0; i < 3; i++) {
      final apnsToken = await _messaging.getAPNSToken();
      if (apnsToken != null) return;
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  String _mensagemErroPlataforma() {
    if (Platform.isAndroid) {
      return 'Use um emulador Android com Google Play e permita notificações.';
    }
    if (Platform.isIOS) {
      return 'FCM não funciona no simulador iOS. Teste no emulador Android.';
    }
    return 'Token FCM indisponível nesta plataforma.';
  }

  Future<void> copiarToken(BuildContext context) async {
    var token = _token;
    if (token == null || token.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buscando token FCM...')),
      );
      token = await fetchToken(forceRefresh: true);
    }

    if (token == null || token.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lastError ?? 'Token FCM indisponível.')),
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: token));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Token FCM copiado para a área de transferência'),
      ),
    );
  }

  void setupFcmListeners({
    required PushAlertCallback onPushAlert,
    required VoidCallback onNavigateToAlertas,
    void Function(String titulo)? onForegroundSnackBar,
  }) {
    _onPushAlert = onPushAlert;
    _onNavigateToAlertas = onNavigateToAlertas;
    _onForegroundSnackBar = onForegroundSnackBar;

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

    _messaging.getInitialMessage().then((message) {
      if (message == null) return;
      _processMessageData(message);
      _onNavigateToAlertas?.call();
    });
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await _showLocalNotification(message);
    _processMessageData(message);

    final titulo =
        message.notification?.title ?? message.data['titulo'] ?? 'Novo alerta';
    _onForegroundSnackBar?.call(titulo);
  }

  void _handleMessageOpened(RemoteMessage message) {
    _processMessageData(message);
    _onNavigateToAlertas?.call();
  }

  void _processMessageData(RemoteMessage message) {
    final data = message.data;
    final titulo =
        data['titulo'] ?? message.notification?.title ?? 'Novo alerta';
    final descricao =
        data['descricao'] ?? message.notification?.body ?? '';
    final prioridade = data['prioridade'] ?? 'atencao';
    final tipo = data['tipo'] ?? 'push';

    _onPushAlert?.call(
      titulo: titulo,
      descricao: descricao,
      prioridade: prioridade,
      tipo: tipo,
    );
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final titulo =
        message.notification?.title ?? message.data['titulo'] ?? 'Novo alerta';
    final descricao =
        message.notification?.body ?? message.data['descricao'] ?? '';

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Alertas e avisos do sistema MediStock',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      message.hashCode,
      titulo,
      descricao,
      details,
    );
  }
}
