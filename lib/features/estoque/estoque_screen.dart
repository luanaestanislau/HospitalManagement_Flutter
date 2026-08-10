import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../stores/stores.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class EstoqueScreen extends StatefulWidget {
  const EstoqueScreen({super.key});

  @override
  State<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends State<EstoqueScreen> {
  final _buscaCtrl = TextEditingController();
  String _filtroStatus = 'todos';
  String _termoBusca = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final estoqueStore = context.read<EstoqueStore>();
      if (estoqueStore.itens.isEmpty) {
        await estoqueStore.carregar();
      }
      if (!mounted) return;
      context.read<AlertasStore>().gerarAlertas();
    });
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filtrar(List<Map<String, dynamic>> itens) {
    var lista = itens;
    if (_termoBusca.isNotEmpty) {
      lista = lista
          .where(
            (i) => i['nome'].toString().toLowerCase().contains(
              _termoBusca.toLowerCase(),
            ),
          )
          .toList();
    }
    if (_filtroStatus != 'todos') {
      lista = _filtroStatus == 'essencial_ia'
          ? lista.where((i) => i['tipo'] == 'essencial_baixa_demanda').toList()
          : lista.where((i) => i['status'] == _filtroStatus).toList();
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<EstoqueStore>();
    final essenciais = store.itensEssenciaisBaixaDemanda;
    final primordiais = _filtrar(store.itensPrimordiais);

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        shape: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        title: const Text(
          'Estoque',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _mostrarAdicionarItem(context),
          ),
        ],
      ),
      body: store.carregando
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.purple600),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await store.carregar();
                if (!context.mounted) return;
                context.read<AlertasStore>().gerarAlertas();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: _buscaCtrl,
                    onChanged: (v) => setState(() => _termoBusca = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar insumo...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _termoBusca.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _buscaCtrl.clear();
                                setState(() {
                                  _termoBusca = '';
                                });
                              },
                              icon: const Icon(Icons.close, size: 18),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _Chip(
                          'Todos',
                          'todos',
                          _filtroStatus,
                          () => setState(() => _filtroStatus = 'todos'),
                        ),
                        const SizedBox(width: 8),
                        _Chip(
                          'Crítico',
                          'critico',
                          _filtroStatus,
                          () => setState(() => _filtroStatus = 'critico'),
                          cor: AppTheme.red600,
                        ),
                        const SizedBox(width: 8),
                        _Chip(
                          'Prioritários',
                          'essencial_ia',
                          _filtroStatus,
                          () => setState(() => _filtroStatus = 'essencial_ia'),
                          cor: AppTheme.purple600,
                        ),
                        const SizedBox(width: 8),
                        _Chip(
                          'Vencendo',
                          'vencendo',
                          _filtroStatus,
                          () => setState(() => _filtroStatus = 'vencendo'),
                          cor: AppTheme.amber600,
                        ),
                        const SizedBox(width: 8),
                        _Chip(
                          'Normal',
                          'normal',
                          _filtroStatus,
                          () => setState(() => _filtroStatus = 'normal'),
                          cor: AppTheme.green600,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (essenciais.isNotEmpty && _filtroStatus != 'critico') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.purple50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.purple200,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.purple600,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Essenciais · baixa demanda',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.purple900,
                                  ),
                                ),
                                Text(
                                  'Sugestão de estoque interno · requer atenção especial',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.purple600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const AiBadge(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...essenciais.map((item) => _EssencialCard(item: item)),
                    const SizedBox(height: 8),
                  ],
                  if (_filtroStatus != 'essencial_ia') ...[
                    const SectionDivider(
                      label: 'Itens primordiais · monitoramento contínuo',
                    ),
                    if (primordiais.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Nenhum item encontrado',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ),
                      )
                    else
                      Card(
                        child: Column(
                          children: [
                            // Cabeçalho da tabela
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 0.5,
                                  ),
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      'Item',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Qtd',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Mín',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Status',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Linhas
                            ...primordiais.asMap().entries.map((e) {
                              final idx = e.key;
                              final item = e.value;
                              return _TabelaLinha(
                                item: item,
                                isLast: idx == primordiais.length - 1,
                              );
                            }),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () {},
                        child: Text(
                          'Ver todos os ${store.totalItens} itens',
                          style: const TextStyle(
                            color: AppTheme.purple600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String slug;
  final String selecionado;
  final VoidCallback onTap;
  final Color? cor;

  const _Chip(this.label, this.slug, this.selecionado, this.onTap, {this.cor});

  @override
  Widget build(BuildContext context) {
    final isSelected = selecionado == slug;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? (cor ?? AppTheme.blue600) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (cor ?? AppTheme.blue600)
                : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade400,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

void _mostrarAdicionarItem(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _AdicionarItemSheet(),
  );
}

class _EssencialCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _EssencialCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final atual = item['quantidade_atual'] as int;
    final recomendado = item['quantidade_recomendada_ia'] as int? ?? 0;
    final progresso = recomendado > 0
        ? (atual / recomendado).clamp(0.0, 1.0)
        : 0.0;

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
                  item['nome'],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.purple800,
                  ),
                ),
              ),
              AppBadge(
                label: recomendado > 0 ? 'Pronto' : 'Calcular',
                type: AppBadgeType.ia,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Item essencial · baixa demanda regular',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoMini(label: 'Atual', valor: '$atual un'),
              const SizedBox(width: 16),
              _InfoMini(
                label: 'Sugestão',
                valor: recomendado > 0 ? '$recomendado un' : '—',
                destaque: true,
              ),
              if (item['local_armazenamento'] != null) ...[
                const SizedBox(width: 16),
                _InfoMini(
                  label: 'Local ideal',
                  valor: item['local_armazenamento'],
                ),
              ],
            ],
          ),
          if (recomendado > 0) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progresso,
                backgroundColor: AppTheme.purple200.withOpacity(0.3),
                color: AppTheme.purple600,
                minHeight: 4,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _BtnPequeno(
                label: 'Ver cálculo',
                primario: true,
                onTap: () => _verCalculo(context, item),
              ),
              const SizedBox(width: 8),
              _BtnPequeno(
                label: recomendado == 0 ? 'Calcular básico' : 'Repor',
                onTap: () {
                  if (recomendado == 0) {
                    context.read<EstoqueStore>().calcularEstoqueBasico(
                      item['id'],
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _verCalculo(BuildContext ctx, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DetalheCalculoSheet(item: item),
    );
  }
}

class _InfoMini extends StatelessWidget {
  final String label;
  final String valor;
  final bool destaque;
  const _InfoMini({
    required this.label,
    required this.valor,
    this.destaque = false,
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
          style: TextStyle(
            fontSize: destaque ? 13 : 12,
            fontWeight: destaque ? FontWeight.w500 : FontWeight.normal,
            color: destaque ? AppTheme.purple600 : Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _BtnPequeno extends StatelessWidget {
  final String label;
  final bool primario;
  final VoidCallback? onTap;
  const _BtnPequeno({required this.label, this.primario = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: primario ? AppTheme.blue600 : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: primario ? AppTheme.blue600 : Colors.grey.shade300,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: primario ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _TabelaLinha extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isLast;
  const _TabelaLinha({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final tipo = badgeTypeFromStatus(item['status']);
    final label = switch (item['status']) {
      'critico' => 'Crítico',
      'atencao' => 'Atenção',
      _ => 'OK',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.grey.shade100, width: 0.5),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              item['nome'],
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${item['quantidade_atual']}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${item['quantidade_minima']}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: AppBadge(label: label, type: tipo),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetalheCalculoSheet extends StatelessWidget {
  final Map<String, dynamic> item;
  const _DetalheCalculoSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final atual = item['quantidade_atual'] as int;
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
            'Cálculo interno com base no histórico de consumo',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const Divider(height: 24),
          _LinhaDetalhe('Quantidade atual', '$atual unidades'),
          _LinhaDetalhe('Recomendado', '$recomendado unidades', destaque: true),
          _LinhaDetalhe(
            'Local ideal',
            item['local_armazenamento'] ?? 'Não calculado',
          ),
          _LinhaDetalhe('Diferença', '${recomendado - atual} unidades a repor'),
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
                    'Este cálculo considera histórico dos últimos 30 dias e ajuste interno de consumo.',
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
              child: const Text('Aplicar sugestão'),
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

class _AdicionarItemSheet extends StatefulWidget {
  const _AdicionarItemSheet();

  @override
  State<_AdicionarItemSheet> createState() => _AdicionarItemSheetState();
}

class _AdicionarItemSheetState extends State<_AdicionarItemSheet> {
  final _nomeCtrl = TextEditingController();
  final _qtdCtrl = TextEditingController();
  final _minCtrl = TextEditingController();
  String _tipo = 'primordial';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border.all(color: Color(0xFF1E1E1E), width: 0.5),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Novo item de estoque',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nomeCtrl,
              decoration: const InputDecoration(labelText: 'Nome do item'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtdCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Qtd atual'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _minCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Qtd mínima'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Tipo',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _TipoOpcao(
                  label: 'Primordial',
                  selecionado: _tipo == 'primordial',
                  onTap: () => setState(() => _tipo = 'primordial'),
                ),
                const SizedBox(width: 10),
                _TipoOpcao(
                  label: 'Essencial / Baixa demanda',
                  selecionado: _tipo == 'essencial_baixa_demanda',
                  onTap: () =>
                      setState(() => _tipo = 'essencial_baixa_demanda'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.purple600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Adicionar item',
                  style: TextStyle(color: AppTheme.purple50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipoOpcao extends StatelessWidget {
  final String label;
  final bool selecionado;
  final VoidCallback onTap;
  const _TipoOpcao({
    required this.label,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selecionado ? AppTheme.purple50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selecionado ? AppTheme.purple600 : Colors.grey.shade300,
            width: selecionado ? 1.5 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selecionado ? AppTheme.purple600 : Colors.grey.shade700,
            fontWeight: selecionado ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
