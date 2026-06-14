import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Services e Stores
import 'package:hospitalmanagement_flutter/services/database.dart';
import 'package:hospitalmanagement_flutter/services/ia_service.dart';
import 'package:hospitalmanagement_flutter/stores/stores.dart';
import 'package:hospitalmanagement_flutter/firebase_options.dart';
import 'firebase_messaging_background.dart';

// Telas
import 'package:hospitalmanagement_flutter/features/auth/splash_screen.dart';
import 'package:hospitalmanagement_flutter/features/auth/login_screen.dart';
import 'package:hospitalmanagement_flutter/features/auth/cadastro_screen.dart';
import 'package:hospitalmanagement_flutter/features/auth/matricula_screen.dart';
import 'package:hospitalmanagement_flutter/features/home/dashboard.dart';
import 'package:hospitalmanagement_flutter/features/ai/ai_screen.dart';
import 'package:hospitalmanagement_flutter/features/alertas/alertas_screen.dart';
import 'package:hospitalmanagement_flutter/features/logistica/logistica_screen.dart';
import 'package:hospitalmanagement_flutter/features/estoque/estoque_screen.dart';
import 'package:firebase_app_installations/firebase_app_installations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicialização do Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Configuração de Notificações
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Solicita permissão (Importante para iOS/Android 13+)
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // Captura de IDs para Teste (Sempre visível no log ao iniciar)
  String? token = await messaging.getToken();
  String fid = await FirebaseInstallations.instance.getId();
  debugPrint("==== FIREBASE DEBUG INFO ====");
  debugPrint("TOKEN FCM: $token");
  debugPrint("ID INSTALAÇÃO (FID): $fid");
  debugPrint("=============================");

  // Listener para App Aberto
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Notificação recebida com app aberto: ${message.notification?.title}');
  });

  // Listener para Clique na Notificação
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('Usuário abriu o app pela notificação: ${message.notification?.title}');
  });

  // 3. Inicialização de Serviços
  final dbService = DatabaseService.instance;
  final iaService = IaService();

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthStore>(create: (_) => AuthStore()),
        ChangeNotifierProvider<EstoqueStore>(
          create: (_) => EstoqueStore(database: dbService, ia: iaService),
        ),
        ChangeNotifierProvider<AlertasStore>(
          create: (context) => AlertasStore(
            estoqueStore: Provider.of<EstoqueStore>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider<LogisticaStore>(create: (_) => LogisticaStore()),
        ChangeNotifierProvider<IaStore>(
          create: (context) => IaStore(
            estoqueStore: Provider.of<EstoqueStore>(context, listen: false),
            ia: iaService,
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MediStock',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const SplashScreen(),
      routes: {
        '/intro': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/cadastro': (context) => const CadastroScreen(),
        '/matricula': (context) => const MatriculaScreen(),
        '/home': (context) => const DashboardScreen(),
        '/ia': (context) => const IaScreen(),
        '/estoque': (context) => const EstoqueScreen(),
        '/alertas': (context) => const AlertasScreen(),
        '/logistica': (context) => const LogisticaScreen(),
      },
    );
  }
}