import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hospitalmanagement_flutter/widgets/app_widgets.dart';
import 'package:provider/provider.dart';
import 'package:hospitalmanagement_flutter/theme/app_theme.dart';

import '../../stores/stores.dart';

class MatriculaScreen extends StatefulWidget {
  const MatriculaScreen({super.key});

  @override
  State<MatriculaScreen> createState() => _MatriculaScreenState();
}

class _MatriculaScreenState extends State<MatriculaScreen> {


  Future<void> _confirmar() async {
    final store = context.read<AuthStore>();
    final ok = await store.confirmarMatricula();

    if (!mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(store.erro ?? 'Erro ao confirmar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AuthStore>();
    final matricula = store.usuario?['matricula'] ?? 'Gerando...';
    final email = store.usuario?['email'] ?? '';

    return LoadingOverlay(
        carregando: store.carregando,
        child:Scaffold(
          backgroundColor: Colors.grey.shade900,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(onPressed: () {
              Navigator.pop(context);
            }, icon: const Icon(Icons.arrow_back, color: AppTheme.purple200,)),

          ),
          body: SafeArea(child: CustomScrollView(
            slivers: [SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AuthHeader(
                  icon: Icons.app_registration_outlined,
                  titulo: 'Matrícula',
                  subtitulo: 'Confirme seus dados funcionais',
                ),
                SizedBox(height: 24,),

                _CampoLeitura(label: 'Matrícula funcional', valor: store.usuario?['matricula']),
                const SizedBox(height: 10),
                _CampoLeitura(label: 'E-mail', valor: email),
                const SizedBox(height: 10),
                _CampoLeitura(
                    label: 'Departamento', valor: store.usuario?['departamento']),
                const SizedBox(height: 10),
                _CampoLeitura(label: 'Cargo / Função', valor: store.usuario?['cargo']),
                const SizedBox(height: 10),
                _CampoLeitura(
                    label: 'Registro profissional', valor: store.usuario?['registro']),

                const Spacer(),
                const SizedBox(height: 48),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _confirmar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.purple600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Confirmar e avançar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),),
                  ),
                ),
                const SizedBox(height: 12),


              ],),),
            )]
          )),
        )
    );
  }
}

class _CampoLeitura extends StatelessWidget {
  final String label;
  final String valor;
  const _CampoLeitura({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 15, color: AppTheme.purple50)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.purple600),
          ),
          child: Text(valor,
              style: const TextStyle(fontSize: 13, color: Colors.white)),
        ),
      ],
    );
  }
}

