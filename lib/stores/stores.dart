import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:hospitalmanagement_flutter/services/ia_service.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/database.dart';

part 'stores.g.dart';

class AuthStore = _AuthStoreBase with _$AuthStore;

abstract class _AuthStoreBase with Store {
  @observable
  Map<String, dynamic>? usuario;

  @observable
  bool carregando = false;

  @observable
  String? erro;

  @computed
  bool get autenticado => usuario != null;

  @action
  Future<bool> cadastrar(String nome, String email, String senha) async {
    carregando = true;
    erro = null;
    try {
      final database = await DatabaseService.instance.database;

      final ano = DateTime.now().year;
      final idRand = (email.hashCode).abs() % 10000;
      final matriculaGerada = "HE-$ano-$idRand";
      final registro = "CRF-SP $idRand";

      final novoUsuario = {
        'nome': nome,
        'email': email,
        'senha': senha,
        'cargo': 'Farmacêutico Responsável',
        'matricula': matriculaGerada,
        'departamento': 'Conexão de farmácia e terapêutica',
        'registro': registro,
        'hospital': 'HC Unicamp',
      };

      await database.insert('usuarios', novoUsuario);
      usuario = novoUsuario;

      carregando = false;
      return true;
    } catch (e) {
      erro = "E-mail já cadastrado no sistema.";
      carregando = false;
      return false;
    }
  }

  @action
  Future<bool> login(String email, String senha) async {
    carregando = true;
    erro = null;
    try {
      final database = await DatabaseService.instance.database;
      final List<Map<String, dynamic>> res = await database.query(
        'usuarios',
        where: 'email = ? AND senha = ?',
        whereArgs: [email, senha],
      );

      if (res.isNotEmpty) {
        usuario = Map<String, dynamic>.from(res.first);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', email);
        carregando = false;
        return true;
      } else {
        erro = "E-mail ou senha incorretos.";
        carregando = false;
        return false;
      }
    } catch (e) {
      erro = "Erro ao conectar ao banco.";
      carregando = false;
      return false;
    }
  }

  @action
  Future<bool> confirmarMatricula() async {
    if (usuario == null) return false;
    carregando = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', usuario!['email']);
      await prefs.setString('user_matricula', usuario!['matricula']);

      carregando = false;
      return true;
    } catch (e) {
      carregando = false;
      return false;
    }
  }

  @action
  Future<void> verificarLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email != null) {
      final database = await DatabaseService.instance.database;
      final res = await database.query(
        'usuarios',
        where: 'email = ?',
        whereArgs: [email],
      );
      if (res.isNotEmpty) {
        usuario = Map<String, dynamic>.from(res.first);
      }
    }
  }

  @action
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    usuario = null;
  }
}

class AlertasStore extends ChangeNotifier {
  final EstoqueStore estoqueStore;

  List<Map<String, dynamic>> _alertas = [];

  AlertasStore({required this.estoqueStore});

  List<Map<String, dynamic>> get alertas => _alertas;
  List<Map<String, dynamic>> get alertasCriticos =>
      _alertas.where((a) => a['prioridade'] == 'critico').toList();
  List<Map<String, dynamic>> get alertasAtencao =>
      _alertas.where((a) => a['prioridade'] == 'atencao').toList();
  int get totalCriticos => alertasCriticos.length;

  void gerarAlertas() {
    _alertas = [];
    for (final item in estoqueStore.itensCriticos) {
      _alertas.add({
        'id': item['id'],
        'tipo': 'estoque_critico',
        'titulo': item['nome'],
        'descricao':
            'Qtd: ${item['quantidade_atual']} · Mín: ${item['quantidade_minima']}',
        'prioridade': 'critico',
        'item_id': item['id'],
        'acoes': ['Repor', 'Ver', 'Redistribuir'],
      });
    }
    notifyListeners();
  }

  void adicionarAlertaDePush({
    required String titulo,
    required String descricao,
    String prioridade = 'atencao',
    String tipo = 'push',
  }) {
    final duplicado = _alertas.any(
      (a) => a['titulo'] == titulo && a['descricao'] == descricao,
    );
    if (duplicado) return;

    _alertas.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch,
      'tipo': tipo,
      'prioridade': prioridade,
      'titulo': titulo,
      'descricao': descricao,
      'acoes': ['Ver'],
    });
    notifyListeners();
  }

  void carregarMock() {
    _alertas = [
      {
        'id': 1,
        'tipo': 'estoque_critico',
        'prioridade': 'critico',
        'titulo': 'Soro Fisiológico 500ml',
        'descricao': 'Qtd: 18 un · Mín: 100 · Setor: UTI',
        'item_id': 1,
        'acoes': ['Repor', 'Ver', 'Redistribuir'],
      },
      {
        'id': 2,
        'tipo': 'estoque_critico',
        'prioridade': 'critico',
        'titulo': 'Luva Estéril P',
        'descricao': 'Qtd: 5 cx · Mín: 30 · Setor: CC',
        'item_id': 3,
        'acoes': ['Repor', 'Rastrear'],
      },
      {
        'id': 3,
        'tipo': 'validade',
        'prioridade': 'atencao',
        'titulo': 'Seringa 5ml',
        'descricao': 'Lote MN-2024 · Vence em 12 dias',
        'item_id': 2,
        'acoes': ['Descartar', 'Redistribuir'],
      },
      {
        'id': 4,
        'tipo': 'atraso_entrega',
        'prioridade': 'atencao',
        'titulo': 'Entrega #OG38 atrasada',
        'descricao': 'ForneceMed · SLA excedido em 2h',
        'pedido_id': 38,
        'acoes': ['Rastrear', 'Contatar'],
      },
    ];
    notifyListeners();
  }
}

class EstoqueStore extends ChangeNotifier {
  final DatabaseService database;
  final IaService ia;

  List<Map<String, dynamic>> _itens = [];
  bool _carregando = false;
  String? _erro;

  EstoqueStore({required this.database, required this.ia});

  List<Map<String, dynamic>> get itens => _itens;
  bool get carregando => _carregando;
  String? get erro => _erro;

  List<Map<String, dynamic>> get itensCriticos =>
      _itens.where((i) => i['status'] == 'critico').toList();

  List<Map<String, dynamic>> get itensEssenciaisBaixaDemanda =>
      _itens.where((i) => i['tipo'] == 'essencial_baixa_demanda').toList();

  List<Map<String, dynamic>> get itensPrimordiais =>
      _itens.where((i) => i['tipo'] == 'primordial').toList();

  int get totalItens => _itens.length;
  int get totalCriticos => itensCriticos.length;

  Future<void> carregar() async {
    _carregando = true;
    notifyListeners();
    try {
      _itens = await database.query('itens', orderBy: 'status DESC, nome ASC');
      _atualizarStatus();
    } catch (e) {
      _erro = e.toString();
    }
    _carregando = false;
    notifyListeners();
  }

  void _atualizarStatus() {
    for (final item in _itens) {
      final atual = item['quantidade_atual'] as int;
      final minimo = item['quantidade_minima'] as int;
      if (atual <= (minimo * 0.3)) {
        item['status'] = 'critico';
      } else if (atual <= minimo) {
        item['status'] = 'atencao';
      } else {
        item['status'] = 'normal';
      }
    }
  }

  Future<void> calcularEstoqueBasico(int itemId) async {
    final item = _itens.firstWhere((i) => i['id'] == itemId);
    final historico = (jsonDecode(item['historico_consumo'] ?? '[]') as List)
        .map((e) => e as int)
        .toList();

    final mediaDiaria = historico.isEmpty
        ? (item['quantidade_minima'] as int? ?? 0).toDouble()
        : historico.reduce((a, b) => a + b) / historico.length;
    final tipo = (item['tipo'] ?? 'primordial').toString();
    final localIdeal = _sugerirLocalArmazenamento(item);

    final update = <String, dynamic>{
      'local_armazenamento': localIdeal,
      'ultima_atualizacao': DateTime.now().toIso8601String(),
    };

    if (tipo == 'primordial') {
      final minimoBase = max(
        item['quantidade_minima'] as int? ?? 0,
        (mediaDiaria * 7 + (mediaDiaria * 1.5)).ceil(),
      );
      update['quantidade_minima'] = minimoBase;
    } else {
      final recomendada = max(
        item['quantidade_minima'] as int? ?? 1,
        (mediaDiaria * 14).ceil(),
      );
      update['quantidade_recomendada_ia'] = recomendada;
    }

    await database.update(
      'itens',
      update,
      where: 'id = ?',
      whereArgs: [itemId],
    );

    await carregar();
  }

  Future<void> calcularEstoqueIa(int itemId) => calcularEstoqueBasico(itemId);

  String _sugerirLocalArmazenamento(Map<String, dynamic> item) {
    final localAtual = item['local_armazenamento']?.toString();
    if ((localAtual ?? '').isNotEmpty && item['tipo'] == 'primordial') {
      return localAtual!;
    }

    final categoria = item['categoria']?.toString().toLowerCase() ?? '';
    if (categoria.contains('quimioter')) {
      return 'Oncologia - Geladeira Especializada';
    }
    if (categoria.contains('trombol')) {
      return 'Emergência - Armário Refrigerado A';
    }
    if (categoria.contains('imunossup')) {
      return 'Hematologia - Refrigerador';
    }
    if (categoria.contains('neurol')) {
      return 'Neurologia Pediátrica - Geladeira';
    }
    if (categoria.contains('imunobiol')) {
      return 'Câmara Fria 01';
    }
    return localAtual ?? 'Farmácia Central A1';
  }

  // Dados mock para desenvolvimento (use antes de ter o banco populado)
  void carregarMock() {
    _itens = [
      {
        'id': 1,
        'nome': 'Soro Fisiológico 500ml',
        'tipo': 'primordial',
        'quantidade_atual': 18,
        'quantidade_minima': 100,
        'status': 'critico',
        'local_armazenamento': 'Farmácia Central A1',
      },
      {
        'id': 2,
        'nome': 'Seringa 10ml',
        'tipo': 'primordial',
        'quantidade_atual': 340,
        'quantidade_minima': 200,
        'status': 'atencao',
        'local_armazenamento': 'Almoxarifado Norte',
      },
      {
        'id': 3,
        'nome': 'Luva Estéril S',
        'tipo': 'primordial',
        'quantidade_atual': 820,
        'quantidade_minima': 100,
        'status': 'normal',
        'local_armazenamento': 'Almoxarifado Norte',
      },
      {
        'id': 4,
        'nome': 'Epinefrina 1mg/ml',
        'tipo': 'essencial_baixa_demanda',
        'quantidade_atual': 8,
        'quantidade_minima': 5,
        'quantidade_recomendada_ia': 22,
        'status': 'atencao',
        'local_armazenamento': 'Farmácia Central B2',
      },
      {
        'id': 5,
        'nome': 'Morfina 10mg/ml',
        'tipo': 'essencial_baixa_demanda',
        'quantidade_atual': 5,
        'quantidade_minima': 3,
        'quantidade_recomendada_ia': 15,
        'status': 'atencao',
        'local_armazenamento': null,
      },
    ];
    notifyListeners();
  }
}

class IaStore extends ChangeNotifier {
  final IaService ia;
  final EstoqueStore estoqueStore;
  final bool usarMockQuandoIaFalhar;

  Map<String, dynamic>? _analiseInterna;
  Map<String, dynamic>? _eventoAtivo;
  bool _carregando = false;
  String? _erro;

  IaStore({
    required this.ia,
    required this.estoqueStore,
    this.usarMockQuandoIaFalhar = false,
  });

  Map<String, dynamic>? get analiseInterna => _analiseInterna;
  Map<String, dynamic>? get analiseResiliencia => _analiseInterna;
  Map<String, dynamic>? get eventoAtivo => _eventoAtivo;
  bool get carregando => _carregando;
  String? get erro => _erro;

  int get scoreInterno => _analiseInterna?['scoreInterno'] as int? ?? 0;
  int get scoreResiliencia => scoreInterno;

  String get classificacaoInterna =>
      _analiseInterna?['classificacao'] as String? ?? 'Sem análise';

  List<Map<String, dynamic>> get recomendacoesInternas =>
      (_analiseInterna?['recomendacoes'] as List? ?? [])
          .cast<Map<String, dynamic>>();
  List<dynamic> get cenarios => recomendacoesInternas;

  Future<void> analisarOtimizacaoInterna() async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      final itens = estoqueStore.itensEssenciaisBaixaDemanda;
      final itensPrioritarios = estoqueStore.itens
          .where((i) => (i['tipo'] ?? '') == 'essencial_baixa_demanda')
          .toList();
      final itensSemLocal = itens
          .where((i) => (i['local_armazenamento'] ?? '').toString().isEmpty)
          .length;
      final itensCriticos = itens.where((i) => i['status'] == 'critico').length;
      final itensAtencao = itens.where((i) => i['status'] == 'atencao').length;

      final recomendacoes =
          itens.map((item) {
            final atual = item['quantidade_atual'] as int? ?? 0;
            final minimo = item['quantidade_minima'] as int? ?? 0;
            final recomendado =
                item['quantidade_recomendada_ia'] as int? ?? minimo;
            final local =
                item['local_armazenamento']?.toString() ?? 'Não definido';
            return {
              'item': item['nome'],
              'status': item['status'],
              'localAtual': local,
              'localSugerido': _sugerirLocal(item),
              'quantidade': atual,
              'quantidadeSugerida': max(recomendado, minimo),
              'prioridade': atual <= minimo ? 'alta' : 'media',
              'tempoTransferencia': _tempoTransferenciaEstimado(item),
              'motivo': _motivoInterno(item),
            };
          }).toList()..sort((a, b) {
            final prioridadeA = a['prioridade'] == 'alta' ? 0 : 1;
            final prioridadeB = b['prioridade'] == 'alta' ? 0 : 1;
            if (prioridadeA != prioridadeB) {
              return prioridadeA.compareTo(prioridadeB);
            }
            return (b['quantidadeSugerida'] as int).compareTo(
              a['quantidadeSugerida'] as int,
            );
          });

      final score = max(
        0,
        100 -
            (itensCriticos * 12) -
            (itensAtencao * 4) -
            (itensSemLocal * 8) -
            (itensPrioritarios.length * 2),
      );

      _analiseInterna = {
        'scoreInterno': score,
        'classificacao': score >= 85
            ? 'Otimizado'
            : score >= 65
            ? 'Controlado'
            : 'Atenção',
        'recomendacoes': recomendacoes.take(4).toList(),
        'itensCriticos': itensCriticos,
        'itensSemLocal': itensSemLocal,
        'itensPrioritarios': itensPrioritarios.length,
      };
    } catch (e) {
      _erro = e.toString();
      if (usarMockQuandoIaFalhar) {
        _carregarMockInterno();
      }
    }

    _carregando = false;
    notifyListeners();
  }

  Future<void> analisarResiliencia() => analisarOtimizacaoInterna();

  String _sugerirLocal(Map<String, dynamic> item) {
    final categoria = item['categoria']?.toString().toLowerCase() ?? '';
    if (categoria.contains('quimioter')) {
      return 'Oncologia - Geladeira Especializada';
    }
    if (categoria.contains('trombol')) {
      return 'Emergência - Armário Refrigerado A';
    }
    if (categoria.contains('imunossup')) {
      return 'Hematologia - Refrigerador';
    }
    if (categoria.contains('neurol')) {
      return 'Neurologia Pediátrica - Geladeira';
    }
    if (categoria.contains('imunobiol')) {
      return 'Câmara Fria 01';
    }
    return item['local_armazenamento']?.toString() ?? 'Farmácia Central A1';
  }

  int _tempoTransferenciaEstimado(Map<String, dynamic> item) {
    final status = item['status']?.toString() ?? 'normal';
    final base = switch (status) {
      'critico' => 20,
      'atencao' => 40,
      _ => 60,
    };
    return base;
  }

  String _motivoInterno(Map<String, dynamic> item) {
    final status = item['status']?.toString() ?? 'normal';
    return switch (status) {
      'critico' => 'Reposição imediata para reduzir tempo de transferência',
      'atencao' => 'Manter perto do ponto de uso e evitar retrabalho logístico',
      _ => 'Estoque estável, sem necessidade de movimentação urgente',
    };
  }

  void _carregarMockInterno() {
    _analiseInterna = {
      'scoreInterno': 88,
      'classificacao': 'Otimizado',
      'itensCriticos': 2,
      'itensSemLocal': 0,
      'transferenciasAtivas': 3,
      'recomendacoes': [
        {
          'item': 'Pembrolizumab 100mg (Keytruda)',
          'status': 'atencao',
          'localAtual': 'Oncologia - Geladeira Especializada',
          'localSugerido': 'Oncologia - Geladeira Especializada',
          'quantidade': 2,
          'quantidadeSugerida': 4,
          'prioridade': 'alta',
          'tempoTransferencia': 20,
          'motivo': 'Manter no ponto de uso reduz o tempo de resposta.',
        },
        {
          'item': 'Eculizumab 300mg (Soliris)',
          'status': 'critico',
          'localAtual': 'Hematologia - Refrigerador',
          'localSugerido': 'Hematologia - Refrigerador',
          'quantidade': 0,
          'quantidadeSugerida': 2,
          'prioridade': 'alta',
          'tempoTransferencia': 20,
          'motivo': 'Movimentação curta para reduzir indisponibilidade.',
        },
      ],
    };
  }
}

class LogisticaStore extends ChangeNotifier {
  String _abaAtiva = 'entregas';
  List<Map<String, dynamic>> _pedidos = [];
  List<Map<String, dynamic>> _transferencias = [];

  String get abaAtiva => _abaAtiva;
  List<Map<String, dynamic>> get pedidos => _pedidos;
  List<Map<String, dynamic>> get transferencias => _transferencias;

  int get pedidosAtrasados =>
      _pedidos.where((p) => p['status'] == 'atrasado').length;
  int get pedidosEmRota =>
      _pedidos.where((p) => p['status'] == 'em_rota').length;
  int get pedidosExtravioReembolso =>
      _pedidos.where((p) => p['status'] == 'extravio_reembolso').length;
  int get pedidosNaoEntregues =>
      _pedidos.where((p) => p['status'] == 'nao_entregue').length;

  Future<void> carregarDoBanco() async {
    final db = DatabaseService.instance;

    final fornecedores = await db.query('fornecedores');
    final fornecedorPorId = <int, String>{
      for (final f in fornecedores) (f['id'] as int): (f['nome'] as String),
    };

    final itens = await db.query('itens');
    final itemPorId = <int, String>{
      for (final i in itens) (i['id'] as int): (i['nome'] as String),
    };

    final hospitais = await db.query('hospitais_parceiros');
    final hospitalPorId = <int, String>{
      for (final h in hospitais) (h['id'] as int): (h['nome'] as String),
    };

    final pedidosDb = await db.query('pedidos', orderBy: 'id DESC');
    _pedidos = pedidosDb.map((p) {
      final status = (p['status'] ?? 'pendente').toString();
      final fornecedorId = p['fornecedor_id'] as int?;
      final itensPedido = (jsonDecode((p['itens'] ?? '[]').toString()) as List)
          .cast<Map<String, dynamic>>();
      final primeiroItem = itensPedido.isNotEmpty ? itensPedido.first : null;
      final itemId = primeiroItem?['item_id'] as int?;
      final itemNome = itemId != null ? (itemPorId[itemId] ?? 'Item') : 'Item';
      final qtd = primeiroItem?['quantidade'] ?? 0;

      return {
        'id': p['id'],
        'codigo': p['codigo'] ?? '#OG000',
        'fornecedor': fornecedorId != null
            ? (fornecedorPorId[fornecedorId] ?? 'Fornecedor')
            : 'Fornecedor',
        'status': status,
        'eta': p['data_eta'] != null ? 'previsto' : '--',
        'sla_excedido': status == 'atrasado' ? 'acima do SLA' : null,
        'hora_entrega': p['data_entrega'] != null ? 'entregue' : null,
        'valor_total': p['valor_total'] ?? 0,
        'motivo_ocorrencia': p['motivo_ocorrencia'],
        'valor_reembolso': p['valor_reembolso'] ?? 0,
        'reentrega_prevista_em': p['reentrega_prevista_em'],
        'item': '$itemNome · $qtd un',
      };
    }).toList();

    final transferenciasDb = await db.query(
      'transferencias',
      orderBy: 'id DESC',
    );
    _transferencias = transferenciasDb.map((t) {
      final origemId = t['hospital_origem_id'] as int?;
      final destinoId = t['hospital_destino_id'] as int?;
      final itemId = t['item_id'] as int?;

      return {
        'id': t['id'],
        'origem': origemId != null
            ? (hospitalPorId[origemId] ?? 'Hospital origem')
            : 'Hospital origem',
        'destino': destinoId != null
            ? (hospitalPorId[destinoId] ?? 'Hospital destino')
            : 'Hospital destino',
        'item': itemId != null ? (itemPorId[itemId] ?? 'Item') : 'Item',
        'quantidade': t['quantidade'] ?? 0,
        'urgencia': t['urgencia'] ?? 'moderada',
        'status': t['status'] ?? 'pendente',
        'sugerida_por_ia': (t['sugerida_por_ia'] ?? 0) == 1,
      };
    }).toList();

    notifyListeners();
  }

  void mudarAba(String aba) {
    _abaAtiva = aba;
    notifyListeners();
  }

  void carregarMock() {
    _pedidos = [
      {
        'id': 38, 'codigo': '#OG038', 'fornecedor': 'ForneceMed',
        'status': 'atrasado', 'eta': '12h00', 'sla_excedido': '2h10',
        'valor_total': 45000.0,
        'item': 'Soro Fisiológico 500ml',
        'lat': -22.9099, 'lng': -47.0626, // ForneceMed · Campinas
        'destinoLat': -22.8336, 'destinoLng': -47.0653, // HC Unicamp
      },
      {
        'id': 41, 'codigo': '#OG041', 'fornecedor': 'MediSupply',
        'status': 'em_rota', 'eta': '16h30', 'item': 'Seringa 5ml · 500 un',
        'valor_total': 32000.0,
        'lat': -23.5505, 'lng': -46.6333, // MediSupply · São Paulo
        'destinoLat': -22.8336, 'destinoLng': -47.0653, // HC Unicamp
      },
      {
        'id': 48,
        'codigo': '#OG048',
        'fornecedor': 'ForneceMed',
        'status': 'extravio_reembolso',
        'valor_total': 30000.0,
        'eta': 'reentrega em 48h',
        'sla_excedido': '12h50',
        'motivo_ocorrencia': 'Extravio confirmado em auditoria de rota',
        'valor_reembolso': 30000.0,
        'item': 'Daptomicina 500mg · 4 frascos',
        'lat': -22.9099,
        'lng': -47.0626,
        'destinoLat': -22.8336,
        'destinoLng': -47.0653,
      },
      {
        'id': 49,
        'codigo': '#OG049',
        'fornecedor': 'PharmaExpress',
        'status': 'nao_entregue',
        'valor_total': 180000.0,
        'eta': '--',
        'sla_excedido': '10h20',
        'motivo_ocorrencia': 'Nao entregue apos tentativas de reprogramacao',
        'valor_reembolso': 0.0,
        'item': 'Eculizumab 300mg · 1 frasco',
        'lat': -23.5505,
        'lng': -46.6333,
        'destinoLat': -22.8336,
        'destinoLng': -47.0653,
      },
      {
        'id': 39, 'codigo': '#OG039', 'fornecedor': 'ForneceMed',
        'status': 'entregue', 'hora_entrega': '13h44',
        'valor_total': 9800.0,
        'item': 'Luva Estéril P · 200 cx',
        'lat': -22.8951, 'lng': -47.0419, // ForneceMed (CD) · Campinas
        'destinoLat': -22.8336, 'destinoLng': -47.0653, // HC Unicamp
      },
    ];
    _transferencias = [
      {
        'id': 1, 'origem': 'Santa Casa – Campinas',
        'destino': 'HC Unicamp', 'item': 'Morfina 10mg/ml',
        'quantidade': 18, 'urgencia': 'imediata', 'status': 'pendente',
        'sugerida_por_ia': true,
        'origemLat': -22.9056, 'origemLng': -47.0608, // Santa Casa
        'destinoLat': -22.8336, 'destinoLng': -47.0653, // HC Unicamp
      },
      {
        'id': 2, 'origem': 'HC Unicamp',
        'destino': 'Santa Casa – Campinas', 'item': 'Epinefrina 1mg/ml',
        'quantidade': 10, 'urgencia': 'preventiva', 'status': 'pendente',
        'sugerida_por_ia': true,
        'origemLat': -22.8336, 'origemLng': -47.0653, // HC Unicamp
        'destinoLat': -22.9056, 'destinoLng': -47.0608, // Santa Casa
      },
    ];
    notifyListeners();
  }
}
