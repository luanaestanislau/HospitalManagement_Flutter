import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:hospitalmanagement_flutter/theme/app_theme.dart';
import 'package:hospitalmanagement_flutter/widgets/app_widgets.dart';
import 'package:provider/provider.dart';
import '../../stores/stores.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _senhaVisivel = false;

  Future<void> _fazerCadastro() async {
    if (_nomeCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _senhaCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos corretamente.")),
      );
      return;
    }

    final store = context.read<AuthStore>();
    final sucesso = await store.cadastrar(
      _nomeCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _senhaCtrl.text,
    );

    if (mounted) {
      if (sucesso) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(store.erro ?? "Erro ao cadastrar")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<AuthStore>();

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Observer(
        builder: (_) => Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AuthHeader(
                    icon: Icons.person_add_outlined,
                    titulo: 'Cadastro',
                    subtitulo: 'Registre seus dados institucionais',
                  ),
                  const SizedBox(height: 48),

                  AuthTextField(
                    label: 'Nome completo',
                    hint: 'Digite seu nome',
                    controller: _nomeCtrl,
                  ),

                  AuthTextField(
                    label: 'E-mail institucional',
                    hint: 'nome@hospital.com',
                    controller: _emailCtrl,
                  ),

                  AuthTextField(
                    label: 'Senha',
                    hint: 'Mínimo 6 caracteres',
                    controller: _senhaCtrl,
                    isPassword: !_senhaVisivel,
                    suffixIcon: _senhaVisivel ? Icons.visibility_off : Icons.visibility,
                    onSuffixPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: store.carregando ? null : _fazerCadastro,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.purple600,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cadastrar',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            if (store.carregando)
              Center(
                child: CircularProgressIndicator(
                  color: AppTheme.purple600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}