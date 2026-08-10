import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../stores/stores.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class IaScreen extends StatefulWidget {
  const IaScreen({super.key});

  @override
  State<IaScreen> createState() => _IaScreenState();
}

class _IaScreenState extends State<IaScreen> {
  int _abaAtiva = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<IaStore>().analisarOtimizacaoInterna();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text(
          'IA Interna',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
                  _IaToggleBtn(
                    label: 'Estocagem',
                    ativo: _abaAtiva == 0,
                    onTap: () => setState(() => _abaAtiva = 0),
                  ),
                  const SizedBox(width: 4),
                  _IaToggleBtn(
                    label: 'Redistribuição',
                    ativo: _abaAtiva == 1,
                    onTap: () => setState(() => _abaAtiva = 1),
                  ),
                  const SizedBox(width: 4),
                  _IaToggleBtn(
                    label: 'Resumo',
                    ativo: _abaAtiva == 2,
                    onTap: () => setState(() => _abaAtiva = 2),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildConteudoAba(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConteudoAba() {
    switch (_abaAtiva) {
      case 0:
        return const _AbaEstocagem(key: ValueKey(0));
      case 1:
        return const _AbaRedistribuicao(key: ValueKey(1));
      case 2:
        return const _AbaResumoInterno(key: ValueKey(2));
      default:
        return const SizedBox.shrink();
    }
  }
}

class _IaToggleBtn extends StatelessWidget {
  final String label;
  final bool ativo;
  final VoidCallback onTap;

  const _IaToggleBtn({
    required this.label,
    required this.ativo,
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
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
              color: ativo ? Colors.white : Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }
}

class _AbaEstocagem extends StatelessWidget {
  const _AbaEstocagem({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<EstoqueStore>();
    final essenciais = store.itensEssenciaisBaixaDemanda;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.purple50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.purple200, width: 0.5),
          ),
          child: const Row(
            children: [
              Icon(Icons.storefront, color: AppTheme.purple600, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'A IA agora foca em armazenagem interna e no melhor local para itens de alto valor e baixa demanda.',
                  style: TextStyle(fontSize: 12, color: AppTheme.purple800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (essenciais.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Nenhum item prioritário cadastrado',
                style: TextStyle(color: Colors.white),
              ),
            ),
          )
        else
          ...essenciais.map((item) => _EstoqueInternoCard(item: item)),
      ],
    );
  }
}

class _EstoqueInternoCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _EstoqueInternoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final atual = item['quantidade_atual'] as int? ?? 0;
    final recomendado = item['quantidade_recomendada_ia'] as int? ?? 0;
    final progresso = recomendado > 0
        ? (atual / recomendado).clamp(0.0, 1.0)
        : 0.0;
    final local = item['local_armazenamento']?.toString() ?? 'Não definido';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.blue50,
        border: Border.all(color: AppTheme.blue100, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item['nome'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.purple800,
                  ),
                ),
              ),
              const AiBadge(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Item de alto valor com baixa demanda',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _ColInfo('Qtd atual', '$atual un')),
              const SizedBox(width: 12),
              Expanded(
                child: _ColInfo(
                  'Sugestão básica',
                  recomendado > 0 ? '$recomendado un' : '—',
                  cor: AppTheme.blue600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ColInfo(
            'Local ideal',
            local,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (recomendado > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progresso,
                backgroundColor: AppTheme.blue100.withOpacity(0.4),
                color: AppTheme.blue600,
                minHeight: 4,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _BtnIA(
                label: 'Ver detalhe',
                primario: true,
                onTap: () => _abrirDetalhe(context, item),
              ),
              const SizedBox(width: 8),
              _BtnIA(
                label: 'Recalcular',
                onTap: () => context.read<EstoqueStore>().calcularEstoqueBasico(
                  item['id'],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _abrirDetalhe(BuildContext ctx, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DetalheInternoSheet(item: item),
    );
  }
}

class _AbaRedistribuicao extends StatelessWidget {
  const _AbaRedistribuicao({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LogisticaStore>();
    final transferencias = store.transferencias;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Transferências internas',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Sugestões e movimentações para reduzir o tempo de entrega entre hospitais.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        if (transferencias.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text(
              'Nenhuma transferência cadastrada',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          )
        else
          ...transferencias.map(
            (t) => _TransferenciaInternaCard(transferencia: t),
          ),
      ],
    );
  }
}

class _TransferenciaInternaCard extends StatelessWidget {
  final Map<String, dynamic> transferencia;

  const _TransferenciaInternaCard({required this.transferencia});

  @override
  Widget build(BuildContext context) {
    final status = transferencia['status']?.toString() ?? 'pendente';
    final badgeType = switch (status) {
      'concluida' => AppBadgeType.normal,
      'em_transito' => AppBadgeType.info,
      'aprovada' => AppBadgeType.atencao,
      'recusada' => AppBadgeType.critico,
      _ => AppBadgeType.ia,
    };

    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    transferencia['item']?.toString() ?? 'Item',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                AppBadge(label: status, type: badgeType),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${transferencia['origem']} → ${transferencia['destino']} · ${transferencia['quantidade']} un',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 4),
            Text(
              'Objetivo: menor tempo de resposta e menor deslocamento interno.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _AbaResumoInterno extends StatelessWidget {
  const _AbaResumoInterno({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<IaStore>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Text(
              'Resumo interno',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const AiBadge(),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${store.scoreInterno}/100',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                store.classificacaoInterna,
                style: const TextStyle(fontSize: 13, color: AppTheme.purple200),
              ),
              const SizedBox(height: 10),
              ScoreBar(score: store.scoreInterno),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ResumoLinha(
          label: 'Itens críticos',
          valor: '${store.analiseInterna?['itensCriticos'] ?? 0}',
        ),
        _ResumoLinha(
          label: 'Itens sem local definido',
          valor: '${store.analiseInterna?['itensSemLocal'] ?? 0}',
        ),
        _ResumoLinha(
          label: 'Itens prioritários',
          valor: '${store.analiseInterna?['itensPrioritarios'] ?? 0}',
        ),
        const SizedBox(height: 16),
        const Text(
          'Prioridades',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        ...store.recomendacoesInternas.map(
          (r) => _PrioridadeCard(recomendacao: r),
        ),
      ],
    );
  }
}

class _PrioridadeCard extends StatelessWidget {
  final Map<String, dynamic> recomendacao;

  const _PrioridadeCard({required this.recomendacao});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    recomendacao['item']?.toString() ?? 'Item',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                AppBadge(
                  label: (recomendacao['prioridade']?.toString() ?? 'media')
                      .toUpperCase(),
                  type: recomendacao['prioridade'] == 'alta'
                      ? AppBadgeType.critico
                      : AppBadgeType.atencao,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${recomendacao['localAtual']} → ${recomendacao['localSugerido']}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 4),
            Text(
              recomendacao['motivo']?.toString() ?? '',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumoLinha extends StatelessWidget {
  final String label;
  final String valor;

  const _ResumoLinha({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ColInfo extends StatelessWidget {
  final String label;
  final String valor;
  final Color? cor;
  final int maxLines;
  final TextOverflow overflow;

  const _ColInfo(
    this.label,
    this.valor, {
    this.cor,
    this.maxLines = 1,
    this.overflow = TextOverflow.visible,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
        ),
        Text(
          valor,
          maxLines: maxLines,
          overflow: overflow,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: cor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _BtnIA extends StatelessWidget {
  final String label;
  final bool primario;
  final VoidCallback? onTap;

  const _BtnIA({required this.label, this.primario = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: primario ? AppTheme.purple600 : Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: primario ? AppTheme.purple600 : Colors.grey.shade300,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: primario ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _DetalheInternoSheet extends StatelessWidget {
  final Map<String, dynamic> item;

  const _DetalheInternoSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final atual = item['quantidade_atual'] as int? ?? 0;
    final recomendado = item['quantidade_recomendada_ia'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item['nome'],
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const AiBadge(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Ajuste interno para reduzir movimentação e manter o item no ponto certo.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const Divider(height: 24),
          _LinhaDetalhe('Quantidade atual', '$atual unidades'),
          _LinhaDetalhe(
            'Sugestão básica',
            '$recomendado unidades',
            destaque: true,
          ),
          _LinhaDetalhe(
            'Local ideal',
            item['local_armazenamento'] ?? 'Não calculado',
          ),
          _LinhaDetalhe('Diferença', '${recomendado - atual} unidades'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.purple50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppTheme.purple600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'O cálculo agora é interno: usa consumo histórico e prioriza o local de armazenagem, sem previsão de falhas de entrega.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.purple800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinhaDetalhe extends StatelessWidget {
  final String label;
  final String valor;
  final bool destaque;

  const _LinhaDetalhe(this.label, this.valor, {this.destaque = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: 13,
              fontWeight: destaque ? FontWeight.w500 : FontWeight.normal,
              color: destaque ? AppTheme.purple600 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
