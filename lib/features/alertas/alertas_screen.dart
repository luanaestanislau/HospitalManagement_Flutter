import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../stores/stores.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  String _filtro = 'todos';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AlertasStore>();

    final alertasFiltrados = switch (_filtro) {
      'critico' => store.alertasCriticos,
      'atencao' => store.alertasAtencao,
      'info' => store.alertas.where((a) => a['prioridade'] == 'info').toList(),
      _ => store.alertas,
    };

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        shape: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        title: const Text(
          'Alertas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (store.totalCriticos > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: AppBadge(
                  label: '${store.totalCriticos} críticos',
                  type: AppBadgeType.critico,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF1E1E1E),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  _FiltroChip(
                    label: 'Todos',
                    ativo: _filtro == 'todos',
                    count: store.alertas.length,
                    onTap: () => setState(() => _filtro = 'todos'),
                  ),
                  const SizedBox(width: 8),
                  _FiltroChip(
                    label: 'Críticos',
                    ativo: _filtro == 'critico',
                    count: store.totalCriticos,
                    tipo: AppBadgeType.critico,
                    onTap: () => setState(() => _filtro = 'critico'),
                  ),
                  const SizedBox(width: 8),
                  _FiltroChip(
                    label: 'Atenção',
                    ativo: _filtro == 'atencao',
                    count: store.alertasAtencao.length,
                    tipo: AppBadgeType.atencao,
                    onTap: () => setState(() => _filtro = 'atencao'),
                  ),
                  const SizedBox(width: 8),
                  _FiltroChip(
                    label: 'Info',
                    ativo: _filtro == 'info',
                    count: 0,
                    onTap: () => setState(() => _filtro = 'info'),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: alertasFiltrados.isEmpty
                ? _Empty(filtro: _filtro)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: alertasFiltrados.length,
                    itemBuilder: (_, i) {
                      final a = alertasFiltrados[i];
                      return _AlertaItem(alerta: a);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AlertaItem extends StatelessWidget {
  final Map<String, dynamic> alerta;

  const _AlertaItem({required this.alerta});

  @override
  Widget build(BuildContext context) {
    final tipo = alerta['prioridade'] == 'critico'
        ? AppBadgeType.critico
        : alerta['prioridade'] == 'atencao'
        ? AppBadgeType.atencao
        : AppBadgeType.info;

    final badgeLabel = switch (alerta['tipo']) {
      'estoque_critico' => 'CRÍTICO',
      'validade' => 'VALIDADE',
      'atraso_entrega' => 'LOGÍSTICA',
      'ia' => 'IA',
      _ => 'AVISO',
    };

    final estoqueStore = context.watch<EstoqueStore>();
    double? progresso;
    if (alerta['tipo'] == 'estoque_critico' && alerta['item_id'] != null) {
      final item = estoqueStore.itens
          .where((i) => i['id'] == alerta['item_id'])
          .firstOrNull;
      if (item != null) {
        final atual = item['quantidade_atual'] as int;
        final max = (item['quantidade_minima'] as int) * 3;
        progresso = (atual / max).clamp(0.0, 1.0);
      }
    }

    return AlertCard(
      titulo: alerta['titulo'],
      descricao: alerta['descricao'],
      tipo: tipo,
      badgeLabel: badgeLabel,
      progressoPercent: progresso,
      acoes: (alerta['acoes'] as List<String>? ?? [])
          .map(
            (ac) => AlertaAcao(
              label: ac,
              primaria: ac == 'Repor',
              onTap: () => _executarAcao(context, ac, alerta),
            ),
          )
          .toList(),
    );
  }

  void _executarAcao(
    BuildContext ctx,
    String acao,
    Map<String, dynamic> alerta,
  ) {
    switch (acao) {
      case 'Repor':
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Abrindo reposição de estoque...')),
        );
      case 'Rastrear':
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Abrindo rastreamento...')),
        );
      case 'Redistribuir':
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Sugerindo redistribuição via IA...')),
        );
    }
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool ativo;
  final int count;
  final AppBadgeType? tipo;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.label,
    required this.ativo,
    required this.count,
    this.tipo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: ativo ? AppTheme.purple600 : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            boxShadow: ativo
                ? [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1))
            ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: ativo ? FontWeight.w500 : FontWeight.normal,
                  color: ativo ? AppTheme.purple50 : Colors.grey.shade500,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: ativo
                        ? AppTheme.purple600
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: ativo ? Colors.white : Colors.grey.shade400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String filtro;

  const _Empty({required this.filtro});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 48, color: AppTheme.green600),
          const SizedBox(height: 12),
          Text(
            filtro == 'todos'
                ? 'Nenhum alerta ativo'
                : 'Nenhum alerta nesta categoria',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
