import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (message.notification == null && message.data.isNotEmpty) {
    const channel = AndroidNotificationChannel(
      'medistock_alertas',
      'Alertas MediStock',
      description: 'Alertas e avisos do sistema MediStock',
      importance: Importance.high,
    );

    final plugin = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await plugin.initialize(const InitializationSettings(android: androidSettings));

    await plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    final titulo = message.data['titulo'] ?? 'Novo alerta';
    final descricao = message.data['descricao'] ?? '';

    await plugin.show(
      message.hashCode,
      titulo,
      descricao,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );

    debugPrint('FCM Background (data-only): $titulo');
  } else {
    debugPrint('FCM Background: ${message.notification?.title}');
  }
}
