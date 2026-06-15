import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
        context.read<IaStore>().analisarResiliencia();
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
          'IA Estratégica',
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
                    label: 'Essenciais',
                    ativo: _abaAtiva == 0,
                    onTap: () => setState(() => _abaAtiva = 0),
                  ),
                  const SizedBox(width: 4),
                  _IaToggleBtn(
                    label: 'Previsão',
                    ativo: _abaAtiva == 1,
                    onTap: () => setState(() => _abaAtiva = 1),
                  ),
                  const SizedBox(width: 4),
                  _IaToggleBtn(
                    label: 'Distribuição',
                    ativo: _abaAtiva == 2,
                    onTap: () => setState(() => _abaAtiva = 2),
                  ),
                  const SizedBox(width: 4),
                  _IaToggleBtn(
                    label: 'Resiliência',
                    ativo: _abaAtiva == 3,
                    onTap: () => setState(() => _abaAtiva = 3),
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
        return const _AbaEssenciais(key: ValueKey(0));
      case 1:
        return const _AbaPrevisao(key: ValueKey(1));
      case 2:
        return const _AbaDistribuicao(key: ValueKey(2));
      case 3:
        return const _AbaResiliencia(key: ValueKey(3));
      default:
        return const SizedBox();
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

//
class _AbaEssenciais extends StatelessWidget {
  const _AbaEssenciais({super.key});

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
              Icon(Icons.auto_awesome, color: AppTheme.purple600, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'A IA calcula a quantidade ideal e o melhor local de armazenamento '
                  'para itens essenciais com baixa demanda regular.',
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
                'Nenhum item essencial cadastrado',
                style: TextStyle(color: Colors.white),
              ),
            ),
          )
        else
          ...essenciais.map((item) => _EssencialIaCard(item: item)),
      ],
    );
  }
}

class _EssencialIaCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _EssencialIaCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final atual = item['quantidade_atual'] as int;
    final recomendado = item['quantidade_recomendada_ia'] as int? ?? 0;
    final progresso = recomendado > 0
        ? (atual / recomendado).clamp(0.0, 1.0)
        : 0.0;

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
                    color: AppTheme.purple800
                  ),
                ),
              ),
              const AiBadge(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Item essencial · consumo sazonal detectado',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ColInfo('Qtd atual', '$atual un'),
              const SizedBox(width: 20),
              _ColInfo(
                'IA recomenda',
                recomendado > 0 ? '$recomendado un' : '—',
                cor: AppTheme.blue600,
              ),
              const SizedBox(width: 20),
              _ColInfo(
                'Local ideal',
                item['local_armazenamento'] ?? 'Calculando...',
              ),
            ],
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
              _BtnIA(label: 'Aplicar sugestão', primario: true, onTap: () {}),
              const SizedBox(width: 8),
              _BtnIA(label: 'Detalhar', onTap: () {}),
            ],
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

  const _ColInfo(this.label, this.valor, {this.cor});

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

class _AbaPrevisao extends StatelessWidget {
  const _AbaPrevisao({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<EstoqueStore>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Histórico vs. previsão',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Baseado nos últimos 30 dias de consumo',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),

        Card(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: store.itensPrimordiais.isNotEmpty
                    ? store.itensPrimordiais.first['nome']
                    : null,
                hint: const Text(
                  'Selecionar item',
                  style: TextStyle(color: Colors.white),
                ),
                isExpanded: true,
                items: store.itens
                    .map(
                      (i) => DropdownMenuItem(
                        value: i['nome'] as String,
                        child: Text(
                          i['nome'],
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (_) {},
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // fl_chart
        Card(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Legenda(cor: AppTheme.blue400, label: 'Histórico'),
                    const SizedBox(width: 16),
                    _Legenda(
                      cor: AppTheme.blue600,
                      label: 'Previsão IA',
                      tracejado: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: _GraficoPrevisaoFlChart(),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['D-30', 'D-20', 'D-10', 'Hoje', 'D+7', 'D+14']
                      .map(
                        (d) => Text(
                          d,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Recomendações de reposição',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        ...store.itens.take(3).map((item) => _RecomendacaoCard(item: item)),
      ],
    );
  }
}

class _Legenda extends StatelessWidget {
  final Color cor;
  final String label;
  final bool tracejado;

  const _Legenda({
    required this.cor,
    required this.label,
    this.tracejado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          color: tracejado ? null : cor,
          decoration: tracejado
              ? BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: cor,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _GraficoPrevisaoFlChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final historico = [50.0, 40.0, 60.0, 45.0, 55.0, 70.0, 50.0, 65.0];
    final previsao = [65.0, 80.0, 75.0, 90.0];

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.05),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final labels = ['D-30', 'D-20', 'D-10', 'Hoje', 'D+7', 'D+14'];
                int index = value.toInt();
                if (index >= 0 && index < labels.length) {
                  return Text(
                    labels[index],
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 5,
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              historico.length,
              (i) => FlSpot(i * 0.625, historico[i]),
            ),
            isCurved: true,
            color: AppTheme.blue400,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: AppTheme.blue400,
                  strokeWidth: 0,
                );
              },
            ),
            belowBarData: BarAreaData(show: false),
          ),
          // Linha de previsão (tracejada)
          LineChartBarData(
            spots: List.generate(
              previsao.length,
              (i) => FlSpot(3.125 + (i * 0.625), previsao[i]),
            ),
            isCurved: true,
            color: AppTheme.blue600,
            barWidth: 3,
            dashArray: [5, 5],
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppTheme.blue600,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}

class _RecomendacaoCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _RecomendacaoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['nome'],
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Repor ${(item['quantidade_minima'] as int? ?? 0) * 2} un · próxima semana',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            AppBadge(
              label: item['status'] == 'critico' ? 'Urgente' : 'Programar',
              type: item['status'] == 'critico'
                  ? AppBadgeType.critico
                  : AppBadgeType.info,
            ),
          ],
        ),
      ),
    );
  }
}

//
class _AbaDistribuicao extends StatelessWidget {
  const _AbaDistribuicao({super.key});

  static const _hospitais = [
    {
      'nome': 'HC Unicamp (seu hospital)',
      'status': 'ok',
      'cor': AppTheme.blue600,
    },
    {
      'nome': 'Hosp. São Luiz — Campinas',
      'status': 'demanda',
      'cor': AppTheme.red400,
    },
    {
      'nome': 'Santa Casa — Campinas',
      'status': 'excedente',
      'cor': AppTheme.green600,
    },
    {
      'nome': 'Hosp. Mário Gatti',
      'status': 'atencao',
      'cor': AppTheme.amber400,
    },
  ];

  static const _sugestoes = [
    {
      'item': 'Morfina 10mg/ml',
      'origem': 'Santa Casa',
      'destino': 'Hosp. São Luiz',
      'quantidade': 18,
      'urgencia': 'imediata',
    },
    {
      'item': 'Epinefrina 1mg/ml',
      'origem': 'HC Unicamp',
      'destino': 'Santa Casa',
      'quantidade': 10,
      'urgencia': 'preventiva',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Mapa real dos hospitais da rede
        _MapaRedeHospitalar(),
        const SizedBox(height: 16),

        const Text(
          'Rede hospitalar',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: _hospitais.asMap().entries.map((e) {
              final h = e.value;
              final isLast = e.key == _hospitais.length - 1;
              final badgeType = switch (h['status']) {
                'ok' => AppBadgeType.normal,
                'demanda' => AppBadgeType.critico,
                'excedente' => AppBadgeType.normal,
                _ => AppBadgeType.atencao,
              };
              final badgeLabel = switch (h['status']) {
                'ok' => 'OK',
                'demanda' => 'Demanda',
                'excedente' => 'Excedente',
                _ => 'Atenção',
              };
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade100,
                            width: 0.5,
                          ),
                        ),
                ),

                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: h['cor'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        h['nome'] as String,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    AppBadge(label: badgeLabel, type: badgeType),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            const Text(
              'Sugestões de redistribuição',
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
        ..._sugestoes.map((s) => _SugestaoCard(sugestao: s)),
      ],
    );
  }
}


class _SugestaoCard extends StatelessWidget {
  final Map<String, dynamic> sugestao;

  const _SugestaoCard({required this.sugestao});

  @override
  Widget build(BuildContext context) {
    final urgencia = sugestao['urgencia'] as String;
    final badgeType = urgencia == 'imediata'
        ? AppBadgeType.critico
        : urgencia == 'preventiva'
        ? AppBadgeType.info
        : AppBadgeType.atencao;
    final badgeLabel = urgencia[0].toUpperCase() + urgencia.substring(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.purple50,
        border: Border.all(color: AppTheme.purple200, width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sugestao['item'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.purple800
                  ),
                ),
              ),
              AppBadge(label: badgeLabel, type: badgeType),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${sugestao['origem']} → ${sugestao['destino']} · ${sugestao['quantidade']} un',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _BtnIA(
                label: 'Aprovar transferência',
                primario: true,
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _BtnIA(label: 'Detalhar', onTap: () {}),
              const SizedBox(width: 8),
              _BtnIA(label: 'Recusar', onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }
}

//
class _AbaResiliencia extends StatefulWidget {
  const _AbaResiliencia({super.key});

  @override
  State<_AbaResiliencia> createState() => _AbaResilienciaState();
}

class _AbaResilienciaState extends State<_AbaResiliencia> {
  bool _eventoAtivo = false;
  bool _eventoResolvido = false;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<IaStore>();

    if (store.carregando) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.purple600),
            SizedBox(height: 16),
            Text(
              'IA analisando cenários de risco...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Estado 3: pós-evento
    if (_eventoResolvido)
      return _RelatorioPostEvento(
        onReset: () => setState(() {
          _eventoResolvido = false;
          _eventoAtivo = false;
        }),
      );

    // Estado 2: evento em andamento
    if (_eventoAtivo)
      return _EventoAtivo(
        onResolver: () => setState(() => _eventoResolvido = true),
      );

    // Estado 1: preventivo (normal)
    return _CenariosPreventivos(
      store: store,
      onSimularEvento: () => setState(() => _eventoAtivo = true),
    );
  }
}

class _CenariosPreventivos extends StatelessWidget {
  final IaStore store;
  final VoidCallback onSimularEvento;

  const _CenariosPreventivos({
    required this.store,
    required this.onSimularEvento,
  });

  @override
  Widget build(BuildContext context) {
    final score = store.scoreResiliencia;
    final classificacao =
        store.analiseResiliencia?['classificacao'] ?? 'Moderado';
    final cenarios = store.cenarios;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Score de resiliência',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Calculado sobre ${cenarios.length} cenários · atualizado agora',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$score',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.amber600,
                          ),
                        ),
                        AppBadge(
                          label: classificacao,
                          type: score >= 80
                              ? AppBadgeType.normal
                              : score >= 60
                              ? AppBadgeType.atencao
                              : AppBadgeType.critico,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ScoreBar(score: score),
              ],
            ),
          ),
        ),
        const SizedBox(height: 3),

        const SectionDivider(label: 'Cenários calculados pela IA'),

        ...cenarios.map(
          (c) => _CenarioCard(cenario: c as Map<String, dynamic>),
        ),

        if (store.analiseResiliencia?['proximoPontoFraco'] != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.blue50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.blue100),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_outlined,
                  color: AppTheme.blue600,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Próximo ponto fraco: ${store.analiseResiliencia!['proximoPontoFraco']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.blue800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onSimularEvento,
          icon: const Icon(Icons.play_circle_outline, size: 18),
          label: const Text('Simular evento em andamento'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.coral600,
            side: const BorderSide(color: AppTheme.coral200),
          ),
        ),
      ],
    );
  }
}

class _CenarioCard extends StatelessWidget {
  final Map<String, dynamic> cenario;

  const _CenarioCard({required this.cenario});

  @override
  Widget build(BuildContext context) {
    final prob = cenario['probabilidade'] as int;
    final prioridade = cenario['prioridade'] as String;
    final tipo = prioridade == 'alta'
        ? AppBadgeType.critico
        : prioridade == 'media'
        ? AppBadgeType.atencao
        : AppBadgeType.info;
    final cor = prioridade == 'alta'
        ? AppTheme.red50
        : prioridade == 'media'
        ? AppTheme.amber50
        : AppTheme.blue50;
    final border = prioridade == 'alta'
        ? AppTheme.red200
        : prioridade == 'media'
        ? AppTheme.amber100
        : AppTheme.blue100;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor,
        border: Border.all(color: border, width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cenario['titulo'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              AppBadge(label: 'Prob. $prob%', type: tipo),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            cenario['acaoRecomendada'] as String,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MiniInfo(
                'Cobertura atual',
                '${cenario['diasCoberturaAtual']} dias',
              ),
              const SizedBox(width: 16),
              _MiniInfo(
                'Estoque seg.',
                '${cenario['estoqueSegurancaSugerido']} un',
              ),
              const SizedBox(width: 16),
              _MiniInfo(
                'Impacto máx.',
                'R\$ ${(cenario['impactoFinanceiro'] as num).toStringAsFixed(0)}',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _BtnIA(
                label: 'Aplicar estoque seg.',
                primario: true,
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _BtnIA(label: 'Detalhes', onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String label;
  final String valor;

  const _MiniInfo(this.label, this.valor);

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
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _EventoAtivo extends StatelessWidget {
  final VoidCallback onResolver;

  const _EventoAtivo({required this.onResolver});

  @override
  Widget build(BuildContext context) {
    final acoes = [
      {
        'status': 'concluido',
        'label': 'Estoque de segurança ativado',
        'detalhe': '+38 un Soro Fisiol. reservadas · prejuízo: R\$ 0',
      },
      {
        'status': 'concluido',
        'label': 'Redistribuição inter-hospitalar solicitada',
        'detalhe': 'Santa Casa → HC Unicamp · 20 un · aguardando aprovação',
      },
      {
        'status': 'em_andamento',
        'label': 'Fornecedor alternativo acionado',
        'detalhe': 'MediSupply · proposta em análise · ETA +6h',
      },
      {
        'status': 'pendente',
        'label': 'Protocolo emergencial hospitalar',
        'detalhe': 'Aguardando falha das etapas anteriores',
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.red50,
            border: Border.all(color: AppTheme.red400),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppTheme.red400, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Evento ativo — não resolvido',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.red900,
                      ),
                    ),
                    Text(
                      'ForneceMed · Entrega #OG038 · há 3h14min',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const AppBadge(label: 'CRÍTICO', type: AppBadgeType.critico),
            ],
          ),
        ),
        const SectionDivider(label: 'Ações de impacto mínimo — IA calculando'),

        ...acoes.asMap().entries.map(
          (e) =>
              _TimelineItem(acao: e.value, isLast: e.key == acoes.length - 1),
        ),
        const SizedBox(height: 16),

        const SectionDivider(label: 'Projeção de impacto com ações ativas'),
        Row(
          children: const [
            Expanded(
              child: _StatImpacto('R\$ 0', 'Prejuízo atual', verde: true),
            ),
            SizedBox(width: 10),
            Expanded(child: _StatImpacto('R\$ 4.800', 'Projeção sem ação')),
            SizedBox(width: 10),
            Expanded(
              child: _StatImpacto('+14h', 'Cobertura restante', verde: true),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Impacto ao paciente',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    const AppBadge(
                      label: 'Nenhum até agora',
                      type: AppBadgeType.normal,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Todos os procedimentos mantidos · protocolo ativo',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: const LinearProgressIndicator(
                    value: 0.14,
                    backgroundColor: Color(0xFFE2E8F0),
                    color: AppTheme.green600,
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Risco atual',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const Text(
                      'Baixo · 14%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.green600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: onResolver,
          child: const Text('Marcar como resolvido'),
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final Map<String, dynamic> acao;
  final bool isLast;

  const _TimelineItem({required this.acao, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final status = acao['status'] as String;
    final cor = switch (status) {
      'concluido' => AppTheme.green600,
      'em_andamento' => AppTheme.amber400,
      _ => Colors.grey.shade300,
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: Colors.grey.shade200,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    acao['label'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: status == 'pendente'
                          ? Colors.grey.shade400
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    acao['detalhe'] as String,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatImpacto extends StatelessWidget {
  final String valor;
  final String label;
  final bool verde;

  const _StatImpacto(this.valor, this.label, {this.verde = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valor,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: verde ? AppTheme.green600 : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

//
class _RelatorioPostEvento extends StatelessWidget {
  final VoidCallback onReset;

  const _RelatorioPostEvento({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header encerrado
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.green50,
            border: Border.all(color: AppTheme.green100),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: AppTheme.green600,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Evento encerrado · Relatório gerado',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.green900,
                      ),
                    ),
                    Text(
                      'ForneceMed #OG038 · duração: 8h42min',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const AppBadge(label: 'RESOLVIDO', type: AppBadgeType.normal),
            ],
          ),
        ),
        const SectionDivider(
          label: 'Impacto real vs. impacto projetado sem IA',
        ),

        // Tabela comparativa
        Card(
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Table(
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: Colors.grey.shade100,
                  width: 0.5,
                ),
              ),
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
              },
              children: [
                _TabelaHeader(),
                _TabelaLinha2('Prejuízo financeiro', 'R\$ 320', 'R\$ 12.800'),
                _TabelaLinha2('Horas de risco', '0h', '8h42'),
                _TabelaLinha2('Pacientes afetados', '0', 'est. 14'),
                _TabelaLinha2('Procedimentos adiados', '0', 'est. 6'),
                _TabelaLinha2('Nível de ação', 'Nível 2', '—'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: const [
            Expanded(
              child: _StatImpacto(
                'R\$ 12.480',
                'Prejuízo evitado',
                verde: true,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _StatImpacto('97,5%', 'Impacto minimizado', verde: true),
            ),
          ],
        ),
        const SectionDivider(label: 'O que a IA aprendeu com este evento'),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.purple50,
            border: Border.all(color: AppTheme.purple200, width: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.psychology_outlined,
                    color: AppTheme.purple600,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Atualização de modelo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.purple900,
                    ),
                  ),
                  const Spacer(),
                  const AiBadge(),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'ForneceMed tem histórico de atrasos em picos de demanda. '
                'Estoque de segurança deste fornecedor foi recalibrado de 2 para 4 dias.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.purple800,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _BtnIA(
                    label: 'Aceitar calibração',
                    primario: true,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  _BtnIA(label: 'Revisar', onTap: () {}),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Score de resiliência atualizado',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Subiu de 72 para 81 com os dados deste evento.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                const ScoreBar(score: 81),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                label: const Text('Exportar PDF'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: onReset,
                child: const Text('Voltar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

TableRow _TabelaHeader() {
  return TableRow(
    decoration: BoxDecoration(color: Colors.grey.shade50),
    children: [
      const Padding(
        padding: EdgeInsets.all(10),
        child: Text(
          'Métrica',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          'Com IA',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.green600,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          'Sem IA',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.red600,
          ),
        ),
      ),
    ],
  );
}

TableRow _TabelaLinha2(String metrica, String comIa, String semIa) {
  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.all(10),
        child: Text(metrica, style: const TextStyle(fontSize: 12)),
      ),
      Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          comIa,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.green600,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          semIa,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.red600,
          ),
        ),
      ),
    ],
  );
}


class _MapaRedeHospitalar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hospitais = [
      {
        'nome': 'HC Unicamp',
        'lat': -22.821,
        'lng': -47.064,
        'status': 'OK',
        'cor': AppTheme.blue600,
      },
      {
        'nome': 'Santa Casa de Campinas',
        'lat': -22.903,
        'lng': -47.062,
        'status': 'Demanda alta',
        'cor': AppTheme.red400,
      },
      {
        'nome': 'Hospital Mário Gatti',
        'lat': -22.886,
        'lng': -47.046,
        'status': 'Atenção',
        'cor': AppTheme.amber400,
      },
      {
        'nome': 'Hospital São Luiz',
        'lat': -22.830,
        'lng': -47.053,
        'status': 'Excedente',
        'cor': AppTheme.green600,
      },
    ];

    final markers = <Marker>{};
    for (final h in hospitais) {
      final cor = h['cor'] as Color;
      final hue = cor == AppTheme.blue600
          ? BitmapDescriptor.hueBlue
          : cor == AppTheme.red400
              ? BitmapDescriptor.hueRed
              : cor == AppTheme.amber400
                  ? BitmapDescriptor.hueOrange
                  : BitmapDescriptor.hueGreen;

      markers.add(
        Marker(
          markerId: MarkerId(h['nome'] as String),
          position: LatLng(
            (h['lat'] as num?)?.toDouble() ?? 0.0,
            (h['lng'] as num?)?.toDouble() ?? 0.0,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: h['nome'] as String,
            snippet: h['status'] as String,
          ),
        ),
      );
    }

    const centro = LatLng(-22.860, -47.055);

    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.blue100),
      ),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: centro,
          zoom: 11,
        ),
        markers: markers,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
        mapToolbarEnabled: false,
      ),
    );
  }
}

