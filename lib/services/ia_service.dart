import 'package:cloud_functions/cloud_functions.dart';

class IaService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Método genérico privado para chamadas ao Firebase
  Future<Map<String, dynamic>> _chamarIA(String nomeFuncao, Map<String, dynamic> dados) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable(nomeFuncao);
      final response = await callable.call(dados);
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Erro ao processar IA no Firebase ($nomeFuncao): $e');
    }
  }

  // 1. CÁLCULO DE ESTOQUE (Mapeia para a função 'calcularEstoque' no index.js)
  Future<Map<String, dynamic>> calcularEstoqueEssencial({
    required String nomeItem,
    required int quantidadeAtual,
    required List<int> historicoConsumo30dias,
    required List<String> locaisDisponiveis,
    required String especialidadeHospital,
  }) async {
    return await _chamarIA('calcularEstoque', {
      'nomeItem': nomeItem,
      'quantidadeAtual': quantidadeAtual,
      'historico': historicoConsumo30dias,
      'locais': locaisDisponiveis,
      'especialidade': especialidadeHospital,
    });
  }

  // 2. ANÁLISE DE RESILIÊNCIA
  Future<Map<String, dynamic>> analisarResiliencia({
    required List<Map<String, dynamic>> estoqueAtual,
    required List<Map<String, dynamic>> historicoPedidos,
    required List<String> fornecedoresAtivos,
    required int diasSemEntrega,
  }) async {
    return await _chamarIA('analisarResiliencia', {
      'estoque': estoqueAtual,
      'pedidos': historicoPedidos,
      'fornecedores': fornecedoresAtivos,
      'diasAtraso': diasSemEntrega,
    });
  }

  // 3. SUGESTÃO DE REDISTRIBUIÇÃO
  Future<Map<String, dynamic>> sugerirRedistribuicao({
    required List<Map<String, dynamic>> estadoHospitaisRede,
    required String itemCritico,
  }) async {
    return await _chamarIA('sugerirRedistribuicao', {
      'rede': estadoHospitaisRede,
      'item': itemCritico,
    });
  }
}