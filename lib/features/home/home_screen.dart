import 'package:flutter/material.dart';
import 'package:hospitalmanagement_flutter/stores/stores.dart';
import 'package:hospitalmanagement_flutter/theme/app_theme.dart';
import 'package:hospitalmanagement_flutter/widgets/app_widgets.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _abaAtual = 0;

  void _abrirPerfil(BuildContext context) {
    final usuario = context.read<AuthStore>().usuario;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PerfilSheet(usuario: usuario),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final alertasStore = context.watch<AlertasStore>();
    // final estoqueStore = context.watch<EstoqueStore>();
    final iaStore = context.watch<IaStore>();
    // final logisticaStore = context.watch<LogisticaStore>();
    final usuario = context.read<AuthStore>().usuario;

    final iniciais = usuario?['nome']
        ?.toString()
        .split(' ')
        .take(2)
        .map((n) => n[0])
        .join() ??
        'AS';

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        shape: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        title: const Text(
          'MediStock',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          CircleAvatar(backgroundColor: Color(0xFFFFCDD2), radius: 15, child: Icon(Icons.circle, color: Colors.red, size: 12)),
          SizedBox(width: 8),
          // if (alertasStore.totalCriticos > 0)
          //   Padding(
          //     padding: const EdgeInsets.only(right: 4),
          //     child: Center(
          //       child: Container(
          //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          //         decoration: BoxDecoration(
          //           color: AppTheme.red50,
          //           borderRadius: BorderRadius.circular(20),
          //           border: Border.all(color: AppTheme.red200),
          //         ),
          //         child: Row(
          //           children: [
          //             const Icon(Icons.circle, size: 6, color: AppTheme.red400),
          //             const SizedBox(width: 4),
          //             Text('${alertasStore.totalCriticos} críticos',
          //                 style: const TextStyle(
          //                     fontSize: 11, color: AppTheme.red600, fontWeight: FontWeight.w500)),
          //           ],
          //         ),
          //       ),
          //     ),
          //   ),

          GestureDetector(
            onTap: () => _abrirPerfil(context),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.purple200,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.purple200),
              ),
              child: Center(
                child: Text(iniciais,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.purple800)),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // await estoqueStore.carregar();
          // alertasStore.gerarAlertas();
        },
        child: ListView(

          padding: const EdgeInsets.all(16),
          children: [
            // ── Alertas ativos (prioridade máxima) ──
            Row(
              children: [
                const Text('Alertas ativos',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                const SizedBox(width: 8),
                AppBadge(
                  // label: '${alertasStore.totalCriticos} críticos',
                    label: '.. críticos',
                    type: AppBadgeType.critico),
                const SizedBox(width: 4),
                AppBadge(
                  // label: '${alertasStore.alertasAtencao.length} atenção',
                    label: '.. atenção',
                    type: AppBadgeType.atencao),
              ],

            ),
            const SizedBox(height: 5),
            // ...alertasStore.alertas.take(2).map((a) => AlertCard(
            //   titulo: a['titulo'],
            //   descricao: a['descricao'],
            //   tipo: a['prioridade'] == 'critico'
            //       ? AppBadgeType.ritico
            //       : AppBadgeType.atencao,
            //   badgeLabel: a['prioridade'].toUpperCase(),
            //   progressoPercent: a['tipo'] == 'estoque_critico'
            //       ? _calcularProgresso(a, estoqueStore)
            //       : null,
            //   acoes: (a['acoes'] as List<String>)
            //       .map((ac) => AlertaAcao(
            //     label: ac,
            //     primaria: ac == 'Repor',
            //   ))
            //       .toList(),
            // )),

            Divider(height: 20, thickness: 1, color: Colors.white.withOpacity(0.1),),

            // ── Stats rápidos ──
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    // valor: '${estoqueStore.totalItens}',
                    valor: '...',
                    label: 'Itens em estoque',
                    backcor: AppTheme.coral50,
                    cor: Colors.black87,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    // valor: '${estoqueStore.totalCriticos}',
                    valor: '...',
                    label: 'Críticos',
                    backcor: AppTheme.red100,
                    cor: AppTheme.red600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── IA Estratégica resumo ──
            Card(
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('IA Estratégica',
                                  style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
                              const SizedBox(width: 6),
                              const AiBadge(),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            // '${estoqueStore.itensEssenciaisBaixaDemanda.length} itens essenciais com cálculo pendente',
                            '... itens essenciais com cálculo pendente',
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                          if (iaStore.scoreResiliencia > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Resiliência: ${iaStore.scoreResiliencia}/100',
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.amber600),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── Entregas ──
            Card(
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('Entregas hoje',
                                  style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w500,
                                  color: Colors.white)),
                              const SizedBox(width: 6),
                              AppBadge(
                                // label: '${logisticaStore.pedidosEmRota} em rota',
                                  label: '... em rota',
                                  type: AppBadgeType.info),
                              // if (logisticaStore.pedidosAtrasados > 0) ...[
                              //   const SizedBox(width: 4),
                              //   AppBadge(
                              //       // label: '${logisticaStore.pedidosAtrasados} atrasado',
                              //       label: '... atrasado',
                              //       type: AppBadgeType.critico),
                              // ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Text(
                          //   logisticaStore.pedidos
                          //       .where((p) => p['status'] == 'em_rota')
                          //       .firstOrNull?['codigo'] ??
                          //       'Nenhuma entrega em rota',
                          //   style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          // ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// double? _calcularProgresso(
//     Map<String, dynamic> alerta, EstoqueStore store) {
//   final itemId = alerta['item_id'];
//   if (itemId == null) return null;
//   final item = store.itens.where((i) => i['id'] == itemId).firstOrNull;
//   if (item == null) return null;
//   final atual = item['quantidade_atual'] as int;
//   final max = (item['quantidade_minima'] as int) * 3;
//   return (atual / max).clamp(0.0, 1.0);
// }
}

class _StatCard extends StatelessWidget {
  final String valor;
  final String label;
  final Color cor;
  final Color backcor;

  const _StatCard({required this.valor, required this.label, required this.cor, required this.backcor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: backcor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(valor,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: cor)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

//Perfil
class _PerfilSheet extends StatelessWidget {
  final Map<String, dynamic>? usuario;
  const _PerfilSheet({this.usuario});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.purple50,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.purple200),
                ),
                child: Center(
                  child: Text(
                    usuario?['nome']?.toString().split(' ').take(2).map((n) => n[0]).join() ?? 'AS',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.purple800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(usuario?['nome'] ?? 'Usuário',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    Text(usuario?['cargo'] ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    Text('${usuario?['hospital'] ?? ''} · ${usuario?['registro'] ?? ''}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          _ItemPerfil(icon: Icons.notifications_outlined, label: 'Notificações e alertas'),
          _ItemPerfil(icon: Icons.history_outlined, label: 'Auditoria de IA'),
          _ItemPerfil(icon: Icons.lock_outlined, label: 'Controle de acesso (LGPD)'),
          _ItemPerfil(
            icon: Icons.cloud_done_outlined,
            label: 'Sincronização Firebase',
            trailing: const AppBadge(label: 'Online', type: AppBadgeType.normal),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                context.read<AuthStore>().logout();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(context, '/intro', (_) => false);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.red600,
                side: const BorderSide(color: AppTheme.red200),
              ),
              child: const Text('Sair da conta'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemPerfil extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  const _ItemPerfil({required this.icon, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20, color: Colors.grey.shade600),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {},
    );
  }
}