import 'dart:convert';

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
      final res = await database.query('usuarios', where: 'email = ?', whereArgs: [email]);
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
        'descricao': 'Qtd: ${item['quantidade_atual']} · Mín: ${item['quantidade_minima']}',
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
        'id': 1, 'tipo': 'estoque_critico', 'prioridade': 'critico',
        'titulo': 'Soro Fisiológico 500ml',
        'descricao': 'Qtd: 18 un · Mín: 100 · Setor: UTI',
        'item_id': 1, 'acoes': ['Repor', 'Ver', 'Redistribuir'],
      },
      {
        'id': 2, 'tipo': 'estoque_critico', 'prioridade': 'critico',
        'titulo': 'Luva Estéril P',
        'descricao': 'Qtd: 5 cx · Mín: 30 · Setor: CC',
        'item_id': 3, 'acoes': ['Repor', 'Rastrear'],
      },
      {
        'id': 3, 'tipo': 'validade', 'prioridade': 'atencao',
        'titulo': 'Seringa 5ml',
        'descricao': 'Lote MN-2024 · Vence em 12 dias',
        'item_id': 2, 'acoes': ['Descartar', 'Redistribuir'],
      },
      {
        'id': 4, 'tipo': 'atraso_entrega', 'prioridade': 'atencao',
        'titulo': 'Entrega #OG38 atrasada',
        'descricao': 'ForneceMed · SLA excedido em 2h',
        'pedido_id': 38, 'acoes': ['Rastrear', 'Contatar'],
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

  Future<void> calcularEstoqueIa(int itemId) async {
    final item = _itens.firstWhere((i) => i['id'] == itemId);
    final historico = (jsonDecode(item['historico_consumo'] ?? '[]') as List)
        .map((e) => e as int)
        .toList();

    try {
      final resultado = await ia.calcularEstoqueEssencial(
        nomeItem: item['nome'],
        quantidadeAtual: item['quantidade_atual'],
        historicoConsumo30dias: historico,
        locaisDisponiveis: ['Farmácia Central A1', 'Farmácia Central B2', 'Almoxarifado Norte'],
        especialidadeHospital: 'Hospital geral universitário',
      );

      await database.update('itens', {
        'quantidade_recomendada_ia': resultado['quantidadeRecomendada'],
        'local_armazenamento': resultado['localIdeal'],
        'ultima_atualizacao': DateTime.now().toIso8601String(),
      }, where: 'id = ?', whereArgs: [itemId]);

      await carregar();
    } catch (e) {
      _erro = 'Erro ao calcular com IA: $e';
      notifyListeners();
    }
  }

  // Dados mock para desenvolvimento (use antes de ter o banco populado)
  void carregarMock() {
    _itens = [
      {
        'id': 1, 'nome': 'Soro Fisiológico 500ml', 'tipo': 'primordial',
        'quantidade_atual': 18, 'quantidade_minima': 100, 'status': 'critico',
        'local_armazenamento': 'Farmácia Central A1',
      },
      {
        'id': 2, 'nome': 'Seringa 10ml', 'tipo': 'primordial',
        'quantidade_atual': 340, 'quantidade_minima': 200, 'status': 'atencao',
        'local_armazenamento': 'Almoxarifado Norte',
      },
      {
        'id': 3, 'nome': 'Luva Estéril S', 'tipo': 'primordial',
        'quantidade_atual': 820, 'quantidade_minima': 100, 'status': 'normal',
        'local_armazenamento': 'Almoxarifado Norte',
      },
      {
        'id': 4, 'nome': 'Epinefrina 1mg/ml', 'tipo': 'essencial_baixa_demanda',
        'quantidade_atual': 8, 'quantidade_minima': 5,
        'quantidade_recomendada_ia': 22, 'status': 'atencao',
        'local_armazenamento': 'Farmácia Central B2',
      },
      {
        'id': 5, 'nome': 'Morfina 10mg/ml', 'tipo': 'essencial_baixa_demanda',
        'quantidade_atual': 5, 'quantidade_minima': 3,
        'quantidade_recomendada_ia': 15, 'status': 'atencao',
        'local_armazenamento': null,
      },
    ];
    notifyListeners();
  }
}

class IaStore extends ChangeNotifier {
  final IaService ia;
  final EstoqueStore estoqueStore;

  Map<String, dynamic>? _analiseResiliencia;
  Map<String, dynamic>? _eventoAtivo;
  bool _carregando = false;
  String? _erro;

  IaStore({required this.ia, required this.estoqueStore});

  Map<String, dynamic>? get analiseResiliencia => _analiseResiliencia;
  Map<String, dynamic>? get eventoAtivo => _eventoAtivo;
  bool get carregando => _carregando;
  String? get erro => _erro;

  int get scoreResiliencia =>
      _analiseResiliencia?['scoreResiliencia'] as int? ?? 0;

  List<dynamic> get cenarios =>
      _analiseResiliencia?['cenarios'] as List? ?? [];

  Future<void> analisarResiliencia() async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      final estoqueData = estoqueStore.itens.map((i) => {
        'nome': i['nome'],
        'quantidade': i['quantidade_atual'],
        'minimo': i['quantidade_minima'],
        'status': i['status'],
      }).toList();

      _analiseResiliencia = await ia.analisarResiliencia(
        estoqueAtual: estoqueData,
        historicoPedidos: [],
        fornecedoresAtivos: ['ForneceMed', 'MediSupply', 'HospitalFarma'],
        diasSemEntrega: 2,
      );
    } catch (e) {
      _erro = e.toString();
      // Carrega mock se a API falhar (útil em desenvolvimento)
      _carregarMockResiliencia();
    }

    _carregando = false;
    notifyListeners();
  }

  void _carregarMockResiliencia() {
    _analiseResiliencia = {
      'scoreResiliencia': 72,
      'classificacao': 'Moderado',
      'cenarios': [
        {
          'tipo': 'atraso_entrega',
          'titulo': 'Falha de entrega',
          'probabilidade': 34,
          'impactoFinanceiro': 12800,
          'diasCoberturaAtual': 2,
          'acaoRecomendada': 'Manter estoque de segurança de 38 un de Soro Fisiológico.',
          'estoqueSegurancaSugerido': 38,
          'prioridade': 'alta',
        },
        {
          'tipo': 'fraude',
          'titulo': 'Fraude ou golpe',
          'probabilidade': 8,
          'impactoFinanceiro': 12400,
          'diasCoberturaAtual': 6,
          'acaoRecomendada': 'Ativar dupla verificação de lotes para 3 fornecedores.',
          'estoqueSegurancaSugerido': 0,
          'prioridade': 'alta',
        },
        {
          'tipo': 'catastrofe',
          'titulo': 'Catástrofe / demanda súbita',
          'probabilidade': 5,
          'impactoFinanceiro': 45000,
          'diasCoberturaAtual': 3,
          'acaoRecomendada': 'Plano emergencial ativa redistribuição com 4 hospitais parceiros.',
          'estoqueSegurancaSugerido': 120,
          'prioridade': 'media',
        },
      ],
      'proximoPontoFraco': 'Morfina 10mg/ml',
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

  void mudarAba(String aba) {
    _abaAtiva = aba;
    notifyListeners();
  }

  void carregarMock() {
    // Coordenadas (lat/lng) do fornecedor de cada pedido e do hospital de
    // destino (HC Unicamp). Os pontos do mapa de Logística são gerados a
    // partir desses dados — nenhum dado de localização de pacientes é usado.
    _pedidos = [
      {
        'id': 38, 'codigo': '#OG038', 'fornecedor': 'ForneceMed',
        'status': 'atrasado', 'eta': '12h00', 'sla_excedido': '2h10',
        'item': 'Soro Fisiológico 500ml',
        'lat': -22.9099, 'lng': -47.0626, // ForneceMed · Campinas
        'destinoLat': -22.8336, 'destinoLng': -47.0653, // HC Unicamp
      },
      {
        'id': 41, 'codigo': '#OG041', 'fornecedor': 'MediSupply',
        'status': 'em_rota', 'eta': '16h30', 'item': 'Seringa 5ml · 500 un',
        'lat': -23.5505, 'lng': -46.6333, // MediSupply · São Paulo
        'destinoLat': -22.8336, 'destinoLng': -47.0653, // HC Unicamp
      },
      {
        'id': 39, 'codigo': '#OG039', 'fornecedor': 'ForneceMed',
        'status': 'entregue', 'hora_entrega': '13h44',
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

