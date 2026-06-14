import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hospital.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT,
        email TEXT UNIQUE,
        senha TEXT,
        matricula TEXT,
        cargo TEXT,
        departamento TEXT, 
        registro TEXT, 
        hospital TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE itens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        categoria TEXT NOT NULL,
        quantidade_atual INTEGER NOT NULL DEFAULT 0,
        quantidade_minima INTEGER NOT NULL DEFAULT 0,
        quantidade_maxima INTEGER NOT NULL DEFAULT 0,
        quantidade_recomendada_ia INTEGER,
        local_armazenamento TEXT,
        unidade_medida TEXT NOT NULL DEFAULT 'un',
        data_validade TEXT,
        lote TEXT,
        fornecedor_id INTEGER,
        tipo TEXT NOT NULL DEFAULT 'primordial',
        -- tipo: 'primordial' | 'essencial_baixa_demanda'
        status TEXT NOT NULL DEFAULT 'normal',
        -- status: 'normal' | 'atencao' | 'critico'
        ultima_atualizacao TEXT NOT NULL,
        historico_consumo TEXT DEFAULT '[]'
        -- JSON: lista de consumo diário dos últimos 30 dias
      )
    ''');

    await db.execute('''
      CREATE TABLE fornecedores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        cnpj TEXT,
        contato TEXT,
        score_confiabilidade INTEGER DEFAULT 100,
        historico_atrasos INTEGER DEFAULT 0,
        ativo INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE pedidos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT NOT NULL,
        fornecedor_id INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'pendente',
        -- pendente | em_rota | atrasado | entregue | cancelado
        data_pedido TEXT NOT NULL,
        data_eta TEXT,
        data_entrega TEXT,
        valor_total REAL,
        itens TEXT NOT NULL DEFAULT '[]',
        -- JSON: [{item_id, quantidade, valor_unitario}]
        sla_horas INTEGER DEFAULT 48,
        motivo_atraso TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE alertas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        -- estoque_critico | validade | atraso_entrega | fraude | catastrofe | ia
        titulo TEXT NOT NULL,
        descricao TEXT NOT NULL,
        item_id INTEGER,
        pedido_id INTEGER,
        prioridade TEXT NOT NULL DEFAULT 'atencao',
        -- critico | atencao | info
        status TEXT NOT NULL DEFAULT 'ativo',
        -- ativo | resolvido | ignorado
        data_criacao TEXT NOT NULL,
        data_resolucao TEXT,
        acao_tomada TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE eventos_risco (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        descricao TEXT NOT NULL,
        data_inicio TEXT NOT NULL,
        data_fim TEXT,
        status TEXT NOT NULL DEFAULT 'ativo',
        -- ativo | resolvido
        prejuizo_real REAL DEFAULT 0,
        prejuizo_projetado_sem_ia REAL DEFAULT 0,
        pacientes_afetados INTEGER DEFAULT 0,
        acoes_executadas TEXT DEFAULT '[]',
        relatorio_ia TEXT
        -- JSON com o relatório gerado pela IA pós-evento
      )
    ''');

    await db.execute('''
      CREATE TABLE hospitais_parceiros (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        cidade TEXT,
        latitude REAL,
        longitude REAL,
        contato TEXT,
        ativo INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE transferencias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hospital_origem_id INTEGER NOT NULL,
        hospital_destino_id INTEGER NOT NULL,
        item_id INTEGER NOT NULL,
        quantidade INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'pendente',
        -- pendente | aprovada | em_transito | concluida | recusada
        urgencia TEXT NOT NULL DEFAULT 'moderada',
        sugerida_por_ia INTEGER DEFAULT 1,
        data_criacao TEXT NOT NULL,
        data_conclusao TEXT,
        justificativa TEXT
      )
    ''');

  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final dbClient = await database;
    return await dbClient.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> query(
      String table, {
        String? where,
        List<dynamic>? whereArgs,
        String? orderBy,
        int? limit,
      }) async {
    final dbClient = await database;
    return await dbClient.query(table,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit);
  }

  Future<int> update(
      String table,
      Map<String, dynamic> data, {
        required String where,
        required List<dynamic> whereArgs,
      }) async {
    final dbClient = await database;
    return await dbClient.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
      String table, {
        required String where,
        required List<dynamic> whereArgs,
      }) async {
    final dbClient = await database;
    return await dbClient.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<void> seedInitialDataIfEmpty() async {
    final dbClient = await database;
    final itens = await dbClient.query('itens', limit: 1);
    if (itens.isNotEmpty) return;

    final now = DateTime.now().toIso8601String();

    await dbClient.insert('fornecedores', {
      'id': 1,
      'nome': 'ForneceMed',
      'cnpj': '00.000.000/0001-10',
      'contato': 'contato@fornecemed.com',
      'score_confiabilidade': 82,
      'historico_atrasos': 3,
      'ativo': 1,
    });
    await dbClient.insert('fornecedores', {
      'id': 2,
      'nome': 'MediSupply',
      'cnpj': '00.000.000/0001-20',
      'contato': 'suporte@medisupply.com',
      'score_confiabilidade': 94,
      'historico_atrasos': 1,
      'ativo': 1,
    });

    await dbClient.insert('itens', {
      'id': 1,
      'nome': 'Soro Fisiológico 500ml',
      'categoria': 'Insumos',
      'quantidade_atual': 18,
      'quantidade_minima': 100,
      'quantidade_maxima': 300,
      'quantidade_recomendada_ia': null,
      'local_armazenamento': 'Farmácia Central A1',
      'unidade_medida': 'un',
      'data_validade': '2027-01-30',
      'lote': 'SF-2026-01',
      'fornecedor_id': 1,
      'tipo': 'primordial',
      'status': 'critico',
      'ultima_atualizacao': now,
      'historico_consumo': jsonEncode([10, 12, 8, 9, 11, 10, 12, 14, 13, 9]),
    });
    await dbClient.insert('itens', {
      'id': 2,
      'nome': 'Seringa 10ml',
      'categoria': 'Descartáveis',
      'quantidade_atual': 340,
      'quantidade_minima': 200,
      'quantidade_maxima': 600,
      'quantidade_recomendada_ia': null,
      'local_armazenamento': 'Almoxarifado Norte',
      'unidade_medida': 'un',
      'data_validade': '2028-09-01',
      'lote': 'SR-2026-09',
      'fornecedor_id': 2,
      'tipo': 'primordial',
      'status': 'normal',
      'ultima_atualizacao': now,
      'historico_consumo': jsonEncode([20, 19, 22, 23, 18, 17, 21, 24, 20, 19]),
    });
    await dbClient.insert('itens', {
      'id': 3,
      'nome': 'Morfina 10mg/ml',
      'categoria': 'Controlados',
      'quantidade_atual': 5,
      'quantidade_minima': 3,
      'quantidade_maxima': 20,
      'quantidade_recomendada_ia': 15,
      'local_armazenamento': 'Farmácia Central B2',
      'unidade_medida': 'un',
      'data_validade': '2026-12-15',
      'lote': 'MF-2026-04',
      'fornecedor_id': 1,
      'tipo': 'essencial_baixa_demanda',
      'status': 'atencao',
      'ultima_atualizacao': now,
      'historico_consumo': jsonEncode([1, 0, 1, 2, 1, 0, 1, 2, 1, 1]),
    });

    await dbClient.insert('hospitais_parceiros', {
      'id': 1,
      'nome': 'HC Unicamp',
      'cidade': 'Campinas',
      'latitude': -22.821,
      'longitude': -47.064,
      'contato': '(19) 0000-0001',
      'ativo': 1,
    });
    await dbClient.insert('hospitais_parceiros', {
      'id': 2,
      'nome': 'Santa Casa – Campinas',
      'cidade': 'Campinas',
      'latitude': -22.903,
      'longitude': -47.062,
      'contato': '(19) 0000-0002',
      'ativo': 1,
    });

    await dbClient.insert('pedidos', {
      'codigo': '#OG038',
      'fornecedor_id': 1,
      'status': 'atrasado',
      'data_pedido': now,
      'data_eta': now,
      'data_entrega': null,
      'valor_total': 3200,
      'itens': jsonEncode([
        {'item_id': 1, 'quantidade': 200, 'valor_unitario': 8},
      ]),
      'sla_horas': 48,
      'motivo_atraso': 'Atraso logístico no fornecedor',
    });

    await dbClient.insert('transferencias', {
      'hospital_origem_id': 2,
      'hospital_destino_id': 1,
      'item_id': 3,
      'quantidade': 18,
      'status': 'pendente',
      'urgencia': 'imediata',
      'sugerida_por_ia': 1,
      'data_criacao': now,
      'data_conclusao': null,
      'justificativa': 'Redistribuição recomendada por IA',
    });
  }
}