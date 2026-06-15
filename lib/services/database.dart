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

    await db.execute('''
      CREATE TABLE casos_clinicos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        especialidade TEXT NOT NULL,
        -- oncologia | cardiologia | neurologia | ortopedia | emergencia
        descricao TEXT NOT NULL,
        item_id INTEGER NOT NULL,
        quantidade_necessaria INTEGER NOT NULL,
        custo_estimado REAL NOT NULL,
        prioridade TEXT NOT NULL DEFAULT 'media',
        -- alta | media | baixa
        frequencia_anual INTEGER DEFAULT 0,
        -- quantos casos similares acontecem por ano
        hospital_id INTEGER,
        data_criacao TEXT NOT NULL
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

    //Fornecedores
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
    await dbClient.insert('fornecedores', {
      'id': 3,
      'nome': 'PharmaExpress',
      'cnpj': '00.000.000/0001-30',
      'contato': 'vendas@pharmaexpress.com',
      'score_confiabilidade': 78,
      'historico_atrasos': 5,
      'ativo': 1,
    });

    //Básicos
    await dbClient.insert('itens', {
      'id': 1,
      'nome': 'Soro Fisiológico 500ml',
      'categoria': 'Insumos Básicos',
      'quantidade_atual': 850,
      'quantidade_minima': 100,
      'quantidade_maxima': 1000,
      'quantidade_recomendada_ia': null,
      'local_armazenamento': 'Farmácia Central A1',
      'unidade_medida': 'un',
      'data_validade': '2027-01-30',
      'lote': 'SF-2026-01',
      'fornecedor_id': 1,
      'tipo': 'primordial',
      'status': 'normal',
      'ultima_atualizacao': now,
      'historico_consumo': jsonEncode([80, 75, 82, 90, 78, 85, 88, 92, 87, 83]),
    });

    await dbClient.insert('itens', {
      'id': 2,
      'nome': 'Seringa 10ml Descartável',
      'categoria': 'Insumos Básicos',
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
      'nome': 'Vacina Influenza',
      'categoria': 'Imunobiológicos',
      'quantidade_atual': 120,
      'quantidade_minima': 50,
      'quantidade_maxima': 200,
      'quantidade_recomendada_ia': null,
      'local_armazenamento': 'Câmara Fria 01',
      'unidade_medida': 'doses',
      'data_validade': '2026-08-15',
      'lote': 'VF-2025-12',
      'fornecedor_id': 2,
      'tipo': 'primordial',
      'status': 'atencao',
      'ultima_atualizacao': now,
      'historico_consumo': jsonEncode([10, 8, 12, 9, 11, 10, 9, 8, 10, 11]),
    });

    //itens caros
    await dbClient.insert('itens', {
      'id': 4,
      'nome': 'Pembrolizumab 100mg (Keytruda)',
      'categoria': 'Quimioterápicos',
      'quantidade_atual': 2,
      'quantidade_minima': 1,
      'quantidade_maxima': 8,
      'quantidade_recomendada_ia': 4,
      'local_armazenamento': 'Oncologia - Geladeira Especializada',
      'unidade_medida': 'frascos',
      'data_validade': '2027-03-20',
      'lote': 'PEM-2026-08',
      'fornecedor_id': 3,
      'tipo': 'essencial_baixa_demanda',
      'status': 'atencao',
      'ultima_atualizacao': now,
      'historico_consumo': jsonEncode([0, 1, 0, 2, 1, 0, 1, 0, 1, 2]),
    });

    await dbClient.insert('itens', {
      'id': 5,
      'nome': 'Alteplase 50mg (tPA)',
      'categoria': 'Trombolíticos',
      'quantidade_atual': 1,
      'quantidade_minima': 2,
      'quantidade_maxima': 6,
      'quantidade_recomendada_ia': 5,
      'local_armazenamento': 'Emergência - Armário Refrigerado A',
      'unidade_medida': 'frascos',
      'data_validade': '2026-11-10',
      'lote': 'ALT-2026-03',
      'fornecedor_id': 1,
      'tipo': 'essencial_baixa_demanda',
      'status': 'critico',
      'ultima_atualizacao': now,
      'historico_consumo': jsonEncode([1, 0, 1, 1, 0, 2, 1, 0, 1, 0]),
    });

    await dbClient.insert('itens', {
      'id': 6,
      'nome': 'Eculizumab 300mg (Soliris)',
      'categoria': 'Imunossupressores',
      'quantidade_atual': 0,
      'quantidade_minima': 1,
      'quantidade_maxima': 3,
      'quantidade_recomendada_ia': 2,
      'local_armazenamento': 'Hematologia - Refrigerador',
      'unidade_medida': 'frascos',
      'data_validade': '2027-06-30',
      'lote': 'ECU-2026-01',
      'fornecedor_id': 3,
      'tipo': 'essencial_baixa_demanda',
      'status': 'critico',
      'ultima_atualizacao': now,
      'historico_consumo': jsonEncode([0, 1, 0, 0, 1, 0, 0, 1, 0, 0]),
    });

    await dbClient.insert('itens', {
      'id': 7,
      'nome': 'Nusinersen 12mg (Spinraza)',
      'categoria': 'Neurológicos',
      'quantidade_atual': 1,
      'quantidade_minima': 1,
      'quantidade_maxima': 4,
      'quantidade_recomendada_ia': 3,
      'local_armazenamento': 'Neurologia Pediátrica - Geladeira',
      'unidade_medida': 'frascos',
      'data_validade': '2026-12-01',
      'lote': 'NUS-2026-05',
      'fornecedor_id': 2,
      'tipo': 'essencial_baixa_demanda',
      'status': 'atencao',
      'ultima_atualizacao': now,
      'historico_consumo': jsonEncode([0, 0, 1, 0, 1, 0, 0, 1, 0, 1]),
    });

    await dbClient.insert('itens', {
      'id': 8,
      'nome': 'Nivolumab 40mg (Opdivo)',
      'categoria': 'Quimioterápicos',
      'quantidade_atual': 3,
      'quantidade_minima': 2,
      'quantidade_maxima': 10,
      'quantidade_recomendada_ia': 6,
      'local_armazenamento': 'Oncologia - Geladeira Especializada',
      'unidade_medida': 'frascos',
      'data_validade': '2026-09-18',
      'lote': 'NIV-2026-02',
      'fornecedor_id': 1,
      'tipo': 'essencial_baixa_demanda',
      'status': 'atencao',
      'ultima_atualizacao': now,
      'historico_consumo': jsonEncode([1, 2, 1, 0, 1, 2, 1, 1, 0, 2]),
    });

    await dbClient.insert('itens', {
      'id': 9,
      'nome': 'Tocilizumabe 400mg (Actemra)',
      'categoria': 'Imunobiológicos',
      'quantidade_atual': 4,
      'quantidade_minima': 2,
      'quantidade_maxima': 8,
      'quantidade_recomendada_ia': 5,
      'local_armazenamento': 'Reumatologia - Câmara Fria',
      'unidade_medida': 'frascos',
      'data_validade': '2027-05-15',
      'lote': 'TOC-2026-04',
      'fornecedor_id': 2,
      'tipo': 'essencial_baixa_demanda',
      'status': 'normal',
      'ultima_atualizacao': now,
      'historico_consumo': jsonEncode([1, 1, 2, 1, 0, 1, 2, 1, 1, 0]),
    });

    await dbClient.insert('itens', {
      'id': 10,
      'nome': 'Daptomicina 500mg',
      'categoria': 'Antibióticos Especiais',
      'quantidade_atual': 8,
      'quantidade_minima': 5,
      'quantidade_maxima': 15,
      'quantidade_recomendada_ia': 12,
      'local_armazenamento': 'Infectologia - Prateleira C',
      'unidade_medida': 'frascos',
      'data_validade': '2027-02-28',
      'lote': 'DAP-2026-07',
      'fornecedor_id': 3,
      'tipo': 'essencial_baixa_demanda',
      'status': 'normal',
      'ultima_atualizacao': now,
      'historico_consumo': jsonEncode([2, 1, 2, 3, 2, 1, 2, 3, 2, 1]),
    });

    //Hospitais
    await dbClient.insert('hospitais_parceiros', {
      'id': 1,
      'nome': 'HC Unicamp',
      'cidade': 'Campinas',
      'latitude': -22.821,
      'longitude': -47.064,
      'contato': '(19) 3521-7000',
      'ativo': 1,
    });
    await dbClient.insert('hospitais_parceiros', {
      'id': 2,
      'nome': 'Santa Casa de Campinas',
      'cidade': 'Campinas',
      'latitude': -22.903,
      'longitude': -47.062,
      'contato': '(19) 3756-6000',
      'ativo': 1,
    });
    await dbClient.insert('hospitais_parceiros', {
      'id': 3,
      'nome': 'Hospital Mário Gatti',
      'cidade': 'Campinas',
      'latitude': -22.886,
      'longitude': -47.046,
      'contato': '(19) 3772-5700',
      'ativo': 1,
    });
    await dbClient.insert('hospitais_parceiros', {
      'id': 4,
      'nome': 'Hospital São Luiz',
      'cidade': 'Campinas',
      'latitude': -22.830,
      'longitude': -47.053,
      'contato': '(19) 3729-8000',
      'ativo': 1,
    });

    //Casos
    await dbClient.insert('casos_clinicos', {
      'especialidade': 'oncologia',
      'descricao': 'Melanoma metastático stage IV - tratamento imunoterápico primeira linha',
      'item_id': 4,
      'quantidade_necessaria': 4,
      'custo_estimado': 42000.00,
      'prioridade': 'alta',
      'frequencia_anual': 12,
      'hospital_id': 1,
      'data_criacao': now,
    });

    await dbClient.insert('casos_clinicos', {
      'especialidade': 'oncologia',
      'descricao': 'Carcinoma pulmonar não pequenas células PD-L1+ > 50%',
      'item_id': 8,  // Nivolumab
      'quantidade_necessaria': 6,
      'custo_estimado': 38000.00,
      'prioridade': 'alta',
      'frequencia_anual': 18,
      'hospital_id': 1,
      'data_criacao': now,
    });

    await dbClient.insert('casos_clinicos', {
      'especialidade': 'neurologia',
      'descricao': 'AVC isquêmico agudo < 4.5h - candidato trombólise',
      'item_id': 5,
      'quantidade_necessaria': 1,
      'custo_estimado': 15000.00,
      'prioridade': 'alta',
      'frequencia_anual': 48,
      'hospital_id': 1,
      'data_criacao': now,
    });

    await dbClient.insert('casos_clinicos', {
      'especialidade': 'hematologia',
      'descricao': 'Hemoglobinúria paroxística noturna (HPN) - profilaxia infecções',
      'item_id': 6,
      'quantidade_necessaria': 2,
      'custo_estimado': 180000.00,
      'prioridade': 'alta',
      'frequencia_anual': 4,
      'hospital_id': 1,
      'data_criacao': now,
    });

    await dbClient.insert('casos_clinicos', {
      'especialidade': 'neurologia',
      'descricao': 'Atrofia muscular espinhal (AME) tipo1 - tratamento modificador doença',
      'item_id': 7,
      'quantidade_necessaria': 6,
      'custo_estimado': 320000.00,
      'prioridade': 'alta',
      'frequencia_anual': 3,
      'hospital_id': 3,
      'data_criacao': now,
    });

    await dbClient.insert('casos_clinicos', {
      'especialidade': 'reumatologia',
      'descricao': 'Artrite reumatoide severa refratária - biológico anti-IL6',
      'item_id': 9,
      'quantidade_necessaria': 4,
      'custo_estimado': 12000.00,
      'prioridade': 'media',
      'frequencia_anual': 24,
      'hospital_id': 2,
      'data_criacao': now,
    });

    await dbClient.insert('casos_clinicos', {
      'especialidade': 'infectologia',
      'descricao': 'Endocardite MRSA - antibiótico reserva',
      'item_id': 10,
      'quantidade_necessaria': 14,
      'custo_estimado': 8000.00,
      'prioridade': 'alta',
      'frequencia_anual': 8,
      'hospital_id': 1,
      'data_criacao': now,
    });

    // PEDIDOS
    await dbClient.insert('pedidos', {
      'codigo': '#OG038',
      'fornecedor_id': 1,
      'status': 'atrasado',
      'data_pedido': now,
      'data_eta': now,
      'data_entrega': null,
      'valor_total': 45000.00,
      'itens': jsonEncode([
        {'item_id': 5, 'quantidade': 3, 'valor_unitario': 15000},
      ]),
      'sla_horas': 24,
      'motivo_atraso': 'Atraso logístico no fornecedor',
    });

    await dbClient.insert('pedidos', {
      'codigo': '#OG042',
      'fornecedor_id': 3,
      'status': 'em_rota',
      'data_pedido': now,
      'data_eta': now,
      'data_entrega': null,
      'valor_total': 180000.00,
      'itens': jsonEncode([
        {'item_id': 6, 'quantidade': 1, 'valor_unitario': 180000},
      ]),
      'sla_horas': 48,
      'motivo_atraso': null,
    });

    await dbClient.insert('pedidos', {
      'codigo': '#OG045',
      'fornecedor_id': 2,
      'status': 'pendente',
      'data_pedido': now,
      'data_eta': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
      'data_entrega': null,
      'valor_total': 84000.00,
      'itens': jsonEncode([
        {'item_id': 4, 'quantidade': 2, 'valor_unitario': 42000},
      ]),
      'sla_horas': 72,
      'motivo_atraso': null,
    });

    // TRANSFERÊNCIAS
    await dbClient.insert('transferencias', {
      'hospital_origem_id': 2,
      'hospital_destino_id': 1,
      'item_id': 5,
      'quantidade': 2,
      'status': 'pendente',
      'urgencia': 'imediata',
      'sugerida_por_ia': 1,
      'data_criacao': now,
      'data_conclusao': null,
      'justificativa': 'HC necessita tPA para pacientes AVC. Hospital São Luiz tem excedente.',
    });

    await dbClient.insert('transferencias', {
      'hospital_origem_id': 3,
      'hospital_destino_id': 1,
      'item_id': 8,
      'quantidade': 3,
      'status': 'aprovada',
      'urgencia': 'moderada',
      'sugerida_por_ia': 1,
      'data_criacao': now,
      'data_conclusao': null,
      'justificativa': 'Redistribuição oncologia - otimizar estoque rede',
    });

    await dbClient.insert('transferencias', {
      'hospital_origem_id': 4,
      'hospital_destino_id': 2,
      'item_id': 9,
      'quantidade': 2,
      'status': 'em_transito',
      'urgencia': 'moderada',
      'sugerida_por_ia': 1,
      'data_criacao': now,
      'data_conclusao': null,
      'justificativa': 'Balanceamento reumatologia entre hospitais parceiros',
    });
  }
}