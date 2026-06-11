import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../stores/stores.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class LogisticaScreen extends StatelessWidget {
  const LogisticaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LogisticaStore>();

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        shape: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        title: const Text('Logística',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (store.pedidosAtrasados > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AppBadge(
                label: '${store.pedidosAtrasados} atrasado',
                type: AppBadgeType.critico,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AppBadge(
              label: '${store.pedidosEmRota} em rota',
              type: AppBadgeType.info,
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
                border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  _ToggleBtn(
                    label: 'Entregas',
                    icon: Icons.local_shipping_outlined,
                    ativo: store.abaAtiva == 'entregas',
                    onTap: () => store.mudarAba('entregas'),
                  ),
                  _ToggleBtn(
                    label: 'Transferências',
                    icon: Icons.compare_arrows,
                    ativo: store.abaAtiva == 'transferencias',
                    onTap: () => store.mudarAba('transferencias'),
                    badge: '2',
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: store.abaAtiva == 'entregas'
                  ? const _AbaEntregas()
                  : const _AbaTransferencias(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool ativo;
  final VoidCallback onTap;
  final String? badge;

  const _ToggleBtn({
    required this.label,
    required this.icon,
    required this.ativo,
    required this.onTap,
    this.badge,
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
              Icon(icon,
                  size: 16,
                  color: ativo ? AppTheme.purple50 : Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: ativo ? FontWeight.w500 : FontWeight.normal,
                  color: ativo ? AppTheme.purple50 : Colors.grey.shade500,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.purple50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(badge!,
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.purple600,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


//
class _AbaEntregas extends StatefulWidget {
  const _AbaEntregas();

  @override
  State<_AbaEntregas> createState() => _AbaEntregasState();
}

class _AbaEntregasState extends State<_AbaEntregas> {
  String _statusFiltro = 'em_rota';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LogisticaStore>();
    final pedidosFiltrados = store.pedidos
        .where((p) => _statusFiltro == 'todos' || p['status'] == _statusFiltro)
        .toList();

    return Column(
      children: [

        Container(
          color: const Color(0xFF1E1E1E),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                _SubTab('Em rota', 'em_rota', _statusFiltro,
                        () => setState(() => _statusFiltro = 'em_rota')),
                const SizedBox(width: 8),
                _SubTab('Atrasados', 'atrasado', _statusFiltro,
                        () => setState(() => _statusFiltro = 'atrasado'),
                    tipo: AppBadgeType.critico),
                const SizedBox(width: 8),
                _SubTab('Concluídos', 'entregue', _statusFiltro,
                        () => setState(() => _statusFiltro = 'entregue'),
                    tipo: AppBadgeType.normal),
              ],
            ),
          ),
        ),

        // Em produção: GoogleMap(initialCameraPosition: ..., markers: ...)
        _MapaPlaceholder(
          pontos: const [
            {'cor': AppTheme.red400, 'label': 'Atrasado'},
            {'cor': AppTheme.blue600, 'label': 'Em rota'},
            {'cor': AppTheme.green600, 'label': 'Entregue'},
          ],
        ),

        Expanded(
          child: pedidosFiltrados.isEmpty
              ? Center(
              child: Text('Nenhum pedido neste status',
                  style: TextStyle(color: Colors.grey.shade500)))
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pedidosFiltrados.length,
            itemBuilder: (_, i) =>
                _PedidoCard(pedido: pedidosFiltrados[i]),
          ),
        ),
      ],
    );
  }
}

class _SubTab extends StatelessWidget {
  final String label;
  final String valor;
  final String atual;
  final VoidCallback onTap;
  final AppBadgeType? tipo;
  const _SubTab(this.label, this.valor, this.atual, this.onTap, {this.tipo});

  @override
  Widget build(BuildContext context) {
    final ativo = valor == atual;
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
          child: Text(
            textAlign: TextAlign.center,
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: ativo ? FontWeight.w500 : FontWeight.normal,
              color: ativo ? AppTheme.purple50 : Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }
}

class _PedidoCard extends StatelessWidget {
  final Map<String, dynamic> pedido;
  const _PedidoCard({required this.pedido});

  @override
  Widget build(BuildContext context) {
    final status = pedido['status'] as String;
    final tipo = switch (status) {
      'atrasado' => AppBadgeType.critico,
      'em_rota' => AppBadgeType.info,
      'entregue' => AppBadgeType.normal,
      _ => AppBadgeType.info,
    };
    final badgeLabel = switch (status) {
      'atrasado' => 'ATRASADO',
      'em_rota' => 'EM ROTA',
      'entregue' => 'ENTREGUE',
      _ => status.toUpperCase(),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: status == 'atrasado'
            ? AppTheme.red50
            : status == 'entregue'
            ? AppTheme.green50
            : Colors.white,
        border: Border.all(
          color: status == 'atrasado'
              ? AppTheme.red200
              : status == 'entregue'
              ? AppTheme.green100
              : Colors.grey.shade200,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${pedido['codigo']} · ${pedido['fornecedor']}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              AppBadge(label: badgeLabel, type: tipo),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            status == 'atrasado'
                ? 'SLA excedido ${pedido['sla_excedido']} · ${pedido['item']}'
                : status == 'entregue'
                ? '${pedido['item']} · ${pedido['hora_entrega']}'
                : 'ETA: ${pedido['eta']} · ${pedido['item']}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          if (status != 'entregue') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _BtnLog(label: 'Rastrear', primario: true, onTap: () {}),
                const SizedBox(width: 8),
                if (status == 'atrasado') ...[
                  _BtnLog(label: 'Contatar', onTap: () {}),
                  const SizedBox(width: 8),
                  _BtnLog(label: 'Alertar', onTap: () {}),
                ] else
                  _BtnLog(label: 'Detalhes', onTap: () {}),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BtnLog extends StatelessWidget {
  final String label;
  final bool primario;
  final VoidCallback? onTap;
  const _BtnLog({required this.label, this.primario = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: primario ? AppTheme.blue600 : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: primario ? AppTheme.blue600 : Colors.grey.shade300,
            width: 0.5,
          ),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: primario ? Colors.white : Colors.black87)),
      ),
    );
  }
}

//
class _AbaTransferencias extends StatefulWidget {
  const _AbaTransferencias();

  @override
  State<_AbaTransferencias> createState() => _AbaTransferenciasState();
}

class _AbaTransferenciasState extends State<_AbaTransferencias> {
  String _statusFiltro = 'pendente';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LogisticaStore>();
    final filtradas = store.transferencias
        .where((t) => t['status'] == _statusFiltro)
        .toList();

    return Column(
      children: [
        Container(
          color: const Color(0xFF1E1E1E),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                _SubTab('Pendentes', 'pendente', _statusFiltro,
                        () => setState(() => _statusFiltro = 'pendente'),
                    tipo: AppBadgeType.ia),
                const SizedBox(width: 8),
                _SubTab('Em trânsito', 'em_transito', _statusFiltro,
                        () => setState(() => _statusFiltro = 'em_transito')),
                const SizedBox(width: 8),
                _SubTab('Concluídas', 'concluida', _statusFiltro,
                        () => setState(() => _statusFiltro = 'concluida'),
                    tipo: AppBadgeType.normal),
              ],
            ),
          ),
        ),

        _MapaRede(),

        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.purple50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.purple200, width: 0.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome,
                  color: AppTheme.purple600, size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Sugestões de redistribuição — IA Estratégica',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.purple900),
                ),
              ),
              const AiBadge(),
            ],
          ),
        ),

        // Lista de transferências
        Expanded(
          child: filtradas.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.compare_arrows,
                    size: 36, color: Colors.grey),
                const SizedBox(height: 8),
                Text('Nenhuma transferência neste status',
                    style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtradas.length + 1,
            itemBuilder: (_, i) {
              if (i == filtradas.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _mostrarNovaTransferencia(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Nova transferência manual'),
                  ),
                );
              }
              return _TransferenciaCard(
                  transferencia: filtradas[i]);
            },
          ),
        ),
      ],
    );
  }

  void _mostrarNovaTransferencia(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _NovaTransferenciaSheet(),
    );
  }
}

class _TransferenciaCard extends StatelessWidget {
  final Map<String, dynamic> transferencia;
  const _TransferenciaCard({required this.transferencia});

  @override
  Widget build(BuildContext context) {
    final urgencia = transferencia['urgencia'] as String;
    final badgeType = urgencia == 'imediata'
        ? AppBadgeType.critico
        : urgencia == 'preventiva'
        ? AppBadgeType.info
        : AppBadgeType.atencao;
    final sugeridaIa = transferencia['sugerida_por_ia'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: sugeridaIa ? AppTheme.purple50 : Colors.white,
        border: Border.all(
          color: sugeridaIa ? AppTheme.purple200 : Colors.grey.shade200,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(transferencia['item'] as String,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
              ),
              if (sugeridaIa) const AiBadge(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${transferencia['origem']} → ${transferencia['destino']} · ${transferencia['quantidade']} un',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 6),
          AppBadge(
            label: urgencia[0].toUpperCase() + urgencia.substring(1),
            type: badgeType,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _BtnLog(label: 'Aprovar', primario: true, onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transferência aprovada!')),
                );
              }),
              const SizedBox(width: 8),
              _BtnLog(label: 'Detalhar', onTap: () {}),
              const SizedBox(width: 8),
              _BtnLog(label: 'Recusar', onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapaPlaceholder extends StatelessWidget {
  final List<Map<String, dynamic>> pontos;
  const _MapaPlaceholder({required this.pontos});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.blue50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.blue100),
      ),
      child: Stack(
        children: [
          const Center(
            child: Text(
              'Mapa em tempo real',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.blue600),
            ),
          ),
          // Pontos simulados
          Positioned(
            top: 25,
            left: 50,
            child: _PontoMapa(cor: AppTheme.red400),
          ),
          Positioned(
            top: 55,
            left: 140,
            child: _PontoMapa(cor: AppTheme.blue600),
          ),
          Positioned(
            top: 30,
            right: 60,
            child: _PontoMapa(cor: AppTheme.green600),
          ),
          // Instrução para integrar Maps
          Positioned(
            bottom: 8,
            right: 10,
            child: Text(
              '⚡ Integre google_maps_flutter aqui',
              style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapaRede extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: AppTheme.blue50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.blue100),
      ),
      child: Stack(
        children: [
          const Center(
            child: Text('Rede hospitalar — mapa inter-hospitalar',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.blue600)),
          ),
          Positioned(top: 18, left: 30, child: _PontoMapa(cor: AppTheme.blue600)),
          Positioned(top: 50, left: 80, child: _PontoMapa(cor: AppTheme.red400)),
          Positioned(top: 25, right: 80, child: _PontoMapa(cor: AppTheme.green600)),
          Positioned(bottom: 18, right: 40, child: _PontoMapa(cor: AppTheme.amber400)),
          Positioned(
            bottom: 6,
            right: 10,
            child: Text('4 hospitais na rede',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
          ),
        ],
      ),
    );
  }
}

class _PontoMapa extends StatelessWidget {
  final Color cor;
  const _PontoMapa({required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: cor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
              color: cor.withOpacity(0.35),
              blurRadius: 4,
              spreadRadius: 1)
        ],
      ),
    );
  }
}

class _NovaTransferenciaSheet extends StatelessWidget {
  const _NovaTransferenciaSheet();

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nova transferência',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          const TextField(decoration: InputDecoration(labelText: 'Hospital de origem')),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(labelText: 'Hospital de destino')),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(labelText: 'Item')),
          const SizedBox(height: 12),
          const TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Quantidade'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Solicitar transferência'),
            ),
          ),
        ],
      ),
    );
  }
}
