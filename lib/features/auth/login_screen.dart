import 'package:flutter/material.dart';
import 'package:hospitalmanagement_flutter/theme/app_theme.dart';
import 'package:hospitalmanagement_flutter/widgets/app_widgets.dart';
import 'package:hospitalmanagement_flutter/stores/stores.dart';
import 'package:provider/provider.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _senhaVisivel = false;
  String? _dominioDetectado;
  bool _dominioValido = false;

  static const _dominiosValidos = {
    'hc.unicamp.br': 'Hospital das Clínicas — Unicamp',
    'hc.usp.br': 'Hospital das Clínicas — USP',
    'einstein.br': 'Hospital Albert Einstein',
    'hospital.gov.br': 'Hospital Federal',
    'saude.sp.gov.br': 'Secretaria de Saúde — SP',
  };

  void _onEmailChanged(String value) {
    if (value.contains('@')) {
      final dominio = value.split('@').last;
      setState(() {
        _dominioDetectado = _dominiosValidos[dominio];
        _dominioValido = _dominiosValidos.containsKey(dominio);
      });
    } else {
      setState(() {
        _dominioDetectado = null;
        _dominioValido = false;
      });
    }
  }

  Future<void> _login() async {
    final store = context.read<AuthStore>();

    final sucesso = await store.login(_emailCtrl.text.trim(), _senhaCtrl.text);

    if (!mounted) return;

    if (!sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(store.erro ?? 'Erro desconhecido'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else if (sucesso && mounted) {
      Navigator.pushNamed(context, '/matricula');
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final store = context.read<AuthStore>();

    return Observer(
      builder: (_) {
        return LoadingOverlay(
          carregando: store.carregando,
          child: Scaffold(
            backgroundColor: Colors.grey.shade900,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(onPressed: () {
                Navigator.pop(context);
              },
                  icon: const Icon(Icons.arrow_back, color: AppTheme.purple200,)),
            ),
            body: SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AuthHeader(
                            icon: Icons.local_hospital_outlined,
                            titulo: 'Acesso institucional',
                            subtitulo: 'Use o e-mail fornecido pelo hospital',
                          ),

                          const SizedBox(height: 48),

                          const Text('Email institucional',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.purple50),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _emailCtrl,
                            onChanged: _onEmailChanged,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'seunome@hospital.dominio',
                              hintStyle: const TextStyle(color: Colors.white30),
                              suffixIcon: _emailCtrl.text.isNotEmpty
                                  ? Icon(
                                _dominioValido ? Icons.check_circle : Icons.cancel,
                                color: _dominioValido ? AppTheme.green600 : AppTheme.red400,
                                size: 20,
                              )
                                  : null,
                            ),
                          ),
                          if (_dominioDetectado != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  _dominioValido ? Icons.check_circle_outline : Icons.block,
                                  size: 13,
                                  color: _dominioValido ? AppTheme.green600 : AppTheme.red400,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _dominioValido
                                      ? 'Domínio reconhecido - $_dominioDetectado'
                                      : 'Domínio não autorizado',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _dominioValido ? AppTheme.green600 : AppTheme.red600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Text('Senha',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.purple50),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _senhaCtrl,
                            obscureText: !_senhaVisivel,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: '••••••••••',
                              hintStyle: const TextStyle(color: Colors.white30),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                                icon: Icon(
                                  _senhaVisivel ? Icons.visibility_off : Icons.visibility,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text("Não tem uma conta?", style: TextStyle(color: Colors.white70)),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, '/cadastro'),
                                child: const Text("Cadastre-se", style: TextStyle(color: AppTheme.purple200, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const Spacer(),

                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(

                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.purple600,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Verificar e continuar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}
