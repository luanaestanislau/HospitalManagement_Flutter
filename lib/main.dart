import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hospitalmanagement_flutter/features/ai/ai_screen.dart';
import 'package:hospitalmanagement_flutter/features/alertas/alertas_screen.dart';
import 'package:hospitalmanagement_flutter/features/auth/matricula_screen.dart';
import 'package:hospitalmanagement_flutter/features/auth/splash_screen.dart';
import 'package:hospitalmanagement_flutter/features/home/dashboard.dart';
import 'package:hospitalmanagement_flutter/features/logistica/logistica_screen.dart';
import 'package:hospitalmanagement_flutter/services/database.dart';
import 'package:hospitalmanagement_flutter/services/ia_service.dart';
import 'package:provider/provider.dart';
import 'package:hospitalmanagement_flutter/features/auth/login_screen.dart';
import 'package:hospitalmanagement_flutter/stores/stores.dart';
import 'features/estoque/estoque_screen.dart';
import 'firebase_options.dart';

import 'features/auth/cadastro_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,
  );

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

        ChangeNotifierProvider<LogisticaStore>(
          create: ((context) => LogisticaStore()),
        ),

        ChangeNotifierProvider<IaStore>(
          create: (context) => IaStore(
            estoqueStore: Provider.of<EstoqueStore>(context, listen: false),
            ia: iaService
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
      home: const SplashScreen(),
      routes: {
        '/intro': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/cadastro': (context) => const CadastroScreen(),
        '/matricula' : (context) => const MatriculaScreen(),
        '/home' : (context) => const DashboardScreen(),
        '/ia': (context) => const IaScreen(),
        '/estoque': (context) => const EstoqueScreen(),
        '/alertas': (context) => const AlertasScreen(),
        '/logistica': (context) => const LogisticaScreen()
      },
    );
  }
}