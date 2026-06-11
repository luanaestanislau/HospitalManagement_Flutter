import 'package:flutter/material.dart';
import 'package:hospitalmanagement_flutter/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../stores/stores.dart';
import '../../widgets/app_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _checarStatus();
  }

  Future<void> _checarStatus() async {
    final store = context.read<AuthStore>();

    await Future.delayed(const Duration(seconds: 2));
    await store.verificarLogin();

    if (!mounted) return;

    if (store.autenticado) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 13,),
              const AuthHeader(
                icon: Icons.medical_information_outlined,
                titulo: 'MediStock',
                subtitulo: 'Gestão inteligente de insumos hospitalares com IA',
              ),
              const SizedBox(height: 48),

              _FeatureItem(
                icon: Icons.notifications_active_outlined,
                texto: 'Alertas e avisos em tempo real',
              ),
              const SizedBox(height: 16),
              _FeatureItem(
                icon: Icons.inventory_2_outlined,
                texto: 'Estoque crítico com IA preditiva',
              ),
              const SizedBox(height: 16),
              _FeatureItem(
                icon: Icons.account_tree_outlined,
                texto: 'Distribuição entre hospitais',
              ),
              const SizedBox(height: 16),
              _FeatureItem(
                icon: Icons.local_shipping_outlined,
                texto: 'Rastreamento de entregas',
              ),
              const SizedBox(height: 16),
              _FeatureItem(
                icon: Icons.shield_outlined,
                texto: 'Análise de resiliência e cenários de risco',
              ),
              const SizedBox(height: 16),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.purple600,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Entrar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (_) => const _SaibaMaisSheet(),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.purple50,
                    side: BorderSide(color: AppTheme.purple600),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Saiba mais',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: Text(
                  'v1.0.0 · Seguro e conforme com a LGPD',
                  style: TextStyle(fontSize: 11, color: AppTheme.purple200),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaibaMaisSheet extends StatelessWidget {
  const _SaibaMaisSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Sobre o MediStock',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Text(
            'Sistema de gestão de insumos hospitalares desenvolvido para '
            'reduzir desperdícios, prevenir faltas críticas e garantir que '
            'hospitais e pacientes nunca fiquem sem os recursos necessários.\n\n'
            'Utiliza Inteligência Artificial para calcular estoques ideais, '
            'antecipar riscos e coordenar redistribuição entre hospitais.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String texto;

  const _FeatureItem({required this.icon, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.purple800,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.purple200, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(fontSize: 15, color: AppTheme.purple50),
          ),
        ),
      ],
    );
  }
}
