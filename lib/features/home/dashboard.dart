import 'package:flutter/material.dart';
import 'package:hospitalmanagement_flutter/features/home/home_screen.dart';
import 'package:hospitalmanagement_flutter/stores/stores.dart';
import 'package:hospitalmanagement_flutter/theme/app_theme.dart';
import 'package:hospitalmanagement_flutter/widgets/app_widgets.dart';
import 'package:provider/provider.dart';

import '../ai/ai_screen.dart';
import '../alertas/alertas_screen.dart';
import '../estoque/estoque_screen.dart';
import '../logistica/logistica_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _abaAtual = 0;

  final List<Widget> _telas = const [
    HomeScreen(),
    AlertasScreen(),
    EstoqueScreen(),
    IaScreen(),
    LogisticaScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: IndexedStack(index: _abaAtual, children: _telas),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _abaAtual,
          onTap: (index) => setState(() => _abaAtual = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF1E1E1E),
          elevation: 0,
          selectedItemColor: AppTheme.purple600,
          unselectedItemColor: Colors.grey.shade500,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              label: 'Alertas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              label: 'Estoque',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_outlined),
              label: 'IA',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined),
              label: 'Logística',
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertIcon extends StatelessWidget {
  final bool ativo;

  const _AlertIcon({this.ativo = false});

  @override
  Widget build(BuildContext context) {
    // final alertasStore = context.watch<AlertasStore>();
    // final total = alertasStore.totalCriticos;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(ativo ? Icons.notifications : Icons.notifications_outlined),
        // if (total > 0)
        //   Positioned(
        //     right: -6,
        //     top: -4,
        //     child: Container(
        //       padding: const EdgeInsets.all(2),
        //       decoration: const BoxDecoration(
        //         color: AppTheme.red400,
        //         shape: BoxShape.circle,
        //       ),
        //       constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
        //       child: Text(
        //         '$total',
        //         style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w500),
        //         textAlign: TextAlign.center,
        //       ),
        //     ),
        //   ),
      ],
    );
  }
}
