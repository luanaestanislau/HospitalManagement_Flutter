const { setGlobalOptions } = require("firebase-functions/v2");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const { defineSecret } = require('firebase-functions/params');

setGlobalOptions({ maxInstances: 10, region: "us-central1" });

const geminiApiKey = defineSecret('GEMINI_API_KEY');

function getGenAI(apiKey) {
  return new GoogleGenerativeAI(apiKey);
}

function clampNumber(value, min, max, fallback) {
  const n = Number(value);
  if (!Number.isFinite(n)) return fallback;
  return Math.min(max, Math.max(min, Math.round(n)));
}

function classificarResiliencia(score) {
  if (score >= 80) return 'Alto';
  if (score >= 60) return 'Moderado';
  return 'Baixo';
}

function heuristicaAnaliseResiliencia(data) {
  const estoque = Array.isArray(data.estoque) ? data.estoque : [];
  const diasAtraso = clampNumber(data.diasAtraso ?? 0, 0, 90, 0);

  const itensCriticos = estoque.filter((i) => i?.status === 'critico');
  const itensAtencao = estoque.filter((i) => i?.status === 'atencao');

  const scoreBase = 90 - (itensCriticos.length * 9) - (itensAtencao.length * 4) - (diasAtraso * 2);
  const scoreResiliencia = clampNumber(scoreBase, 0, 100, 50);

  const principal = itensCriticos[0] ?? itensAtencao[0] ?? estoque[0] ?? { nome: 'Item não identificado', quantidade: 0 };

  return {
    scoreResiliencia,
    classificacao: classificarResiliencia(scoreResiliencia),
    cenarios: [
      {
        tipo: 'atraso_entrega',
        titulo: 'Falha de entrega',
        probabilidade: clampNumber(20 + (diasAtraso * 8) + (itensCriticos.length * 5), 5, 95, 35),
        impactoFinanceiro: 12000 + (itensCriticos.length * 2500),
        diasCoberturaAtual: clampNumber((principal.quantidade ?? 0) / 8, 0, 20, 2),
        acaoRecomendada: `Manter estoque de segurança para ${principal.nome} e ativar fornecedor alternativo.`,
        estoqueSegurancaSugerido: clampNumber((principal.quantidade ?? 0) * 0.4 + 20, 5, 300, 30),
        prioridade: itensCriticos.length > 0 ? 'alta' : 'media',
      },
      {
        tipo: 'catastrofe',
        titulo: 'Demanda súbita regional',
        probabilidade: clampNumber(5 + itensCriticos.length * 2, 3, 35, 8),
        impactoFinanceiro: 40000,
        diasCoberturaAtual: clampNumber((principal.quantidade ?? 0) / 10, 0, 15, 1),
        acaoRecomendada: 'Criar plano de redistribuição com hospitais parceiros e reserva emergencial.',
        estoqueSegurancaSugerido: clampNumber((principal.quantidade ?? 0) * 0.7 + 40, 20, 500, 80),
        prioridade: 'media',
      },
    ],
    proximoPontoFraco: principal.nome,
  };
}

function heuristicaCalculoEstoque(data) {
  const atual = clampNumber(data.quantidadeAtual, 0, 100000, 0);
  const historico = Array.isArray(data.historico) ? data.historico.map((v) => Number(v)).filter(Number.isFinite) : [];
  const mediaConsumo = historico.length > 0 ? historico.reduce((a, b) => a + b, 0) / historico.length : Math.max(1, Math.round(atual * 0.08));
  const coberturaDias = 21;
  const quantidadeRecomendada = clampNumber((mediaConsumo * coberturaDias) * 1.15, 1, 100000, Math.max(1, atual));

  const locais = Array.isArray(data.locais) ? data.locais : [];
  const localIdeal = locais[0] || 'Farmácia Central A1';
  const diferenca = quantidadeRecomendada - atual;

  return {
    quantidadeRecomendada,
    localIdeal,
    recomendacao: diferenca > 0
      ? `Repor aproximadamente ${diferenca} unidades para manter cobertura de ${coberturaDias} dias.`
      : 'Estoque atual adequado para a janela prevista.',
    status: 'sucesso',
    timestamp: new Date().toISOString(),
  };
}

function heuristicaRedistribuicao(data) {
  const rede = Array.isArray(data.rede) ? data.rede : [];
  const item = data.item || 'Item crítico';

  const comExcedente = rede.filter((h) => (h?.status || '').toString().toLowerCase().includes('exced'));
  const comDemanda = rede.filter((h) => (h?.status || '').toString().toLowerCase().includes('demand'));

  const sugestoes = [];
  if (comExcedente.length > 0 && comDemanda.length > 0) {
    sugestoes.push({
      item,
      origem: comExcedente[0].nome || 'Hospital A',
      destino: comDemanda[0].nome || 'Hospital B',
      quantidade: 20,
      urgencia: 'imediata',
    });
  }

  return {
    item,
    sugestoes,
    status: 'sucesso',
    timestamp: new Date().toISOString(),
  };
}

exports.analisarResiliencia = onCall({ secrets: [geminiApiKey] }, async (request) => {
  const data = request.data || {};

  if (!Array.isArray(data.estoque)) {
    throw new HttpsError('invalid-argument', "O campo 'estoque' deve ser uma lista.");
  }

  try {
    const apiKey = geminiApiKey.value();
    const genAI = getGenAI(apiKey);
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

    const prompt = `Você é um analista de risco hospitalar.
Retorne SOMENTE JSON válido com as chaves:
scoreResiliencia (0-100), classificacao (Alto|Moderado|Baixo),
cenarios (lista de objetos com: tipo, titulo, probabilidade, impactoFinanceiro, diasCoberturaAtual, acaoRecomendada, estoqueSegurancaSugerido, prioridade),
proximoPontoFraco.

Dados:
${JSON.stringify(data)}`;

    const result = await model.generateContent(prompt);
    const text = (await result.response).text();
    const parsed = JSON.parse(text.replace(/```json|```/g, '').trim());

    return {
      scoreResiliencia: clampNumber(parsed.scoreResiliencia, 0, 100, 50),
      classificacao: parsed.classificacao || classificarResiliencia(clampNumber(parsed.scoreResiliencia, 0, 100, 50)),
      cenarios: Array.isArray(parsed.cenarios) ? parsed.cenarios : [],
      proximoPontoFraco: parsed.proximoPontoFraco || 'N/A',
    };
  } catch (error) {
    console.error('Erro na IA (analisarResiliencia), usando heurística:', error);
    return heuristicaAnaliseResiliencia(data);
  }
});

exports.sugerirRedistribuicao = onCall({ secrets: [geminiApiKey] }, async (request) => {
  const data = request.data || {};
  if (!Array.isArray(data.rede)) {
    throw new HttpsError('invalid-argument', "O campo 'rede' deve ser uma lista.");
  }

  try {
    const apiKey = geminiApiKey.value();
    const genAI = getGenAI(apiKey);
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
    const prompt = `Você coordena redistribuição hospitalar.
Retorne SOMENTE JSON válido com as chaves: item, sugestoes (lista de {origem,destino,quantidade,urgencia}), status.
Dados: ${JSON.stringify(data)}`;

    const result = await model.generateContent(prompt);
    const text = (await result.response).text();
    const parsed = JSON.parse(text.replace(/```json|```/g, '').trim());

    return {
      item: parsed.item || data.item || 'Item crítico',
      sugestoes: Array.isArray(parsed.sugestoes) ? parsed.sugestoes : [],
      status: parsed.status || 'sucesso',
      timestamp: new Date().toISOString(),
    };
  } catch (error) {
    console.error('Erro na IA (sugerirRedistribuicao), usando heurística:', error);
    return heuristicaRedistribuicao(data);
  }
});

exports.calcularEstoque = onCall({ secrets: [geminiApiKey] }, async (request) => {
  const data = request.data;

  const apiKey = geminiApiKey.value();
  const genAI = getGenAI(apiKey);

  if (!data.nomeItem || data.quantidadeAtual === undefined) {
    throw new HttpsError("invalid-argument", "Os campos 'nomeItem' e 'quantidadeAtual' são obrigatórios.");
  }

  try {
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

    const prompt = `Você é um gestor hospitalar.
Retorne SOMENTE JSON válido com as chaves: quantidadeRecomendada (número), localIdeal (string), recomendacao (string).
Dados: ${JSON.stringify(data)}`;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();
    const parsed = JSON.parse(text.replace(/```json|```/g, '').trim());

    return {
      quantidadeRecomendada: clampNumber(parsed.quantidadeRecomendada, 1, 100000, clampNumber(data.quantidadeAtual, 1, 100000, 1)),
      localIdeal: parsed.localIdeal || (Array.isArray(data.locais) ? data.locais[0] : 'Farmácia Central A1'),
      recomendacao: parsed.recomendacao || 'Sugestão gerada com base no histórico de consumo.',
      timestamp: new Date().toISOString(),
      status: 'sucesso',
    };
  } catch (error) {
    console.error('Erro na chamada da API Gemini (calcularEstoque), usando heurística:', error);
    return heuristicaCalculoEstoque(data);
  }
});