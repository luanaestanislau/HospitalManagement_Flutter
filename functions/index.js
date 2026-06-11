const { setGlobalOptions } = require("firebase-functions/v2");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const { defineSecret } = require('firebase-functions/params');

setGlobalOptions({ maxInstances: 10, region: "us-central1" });

const geminiApiKey = defineSecret('GEMINI_API_KEY');

function getGenAI(apiKey) {
  return new GoogleGenerativeAI(apiKey);
}

exports.analisarResiliencia = onCall({ secrets: [geminiApiKey] }, async (request) => {
  return { status: "em_implementacao" };
});

exports.sugerirRedistribuicao = onCall({ secrets: [geminiApiKey] }, async (request) => {
  return { status: "em_implementacao" };
});

exports.calcularEstoque = onCall({ secrets: [geminiApiKey] }, async (request) => {
  const data = request.data;

  const apiKey = geminiApiKey.value();
  const genAI = getGenAI(apiKey);

  if (!data.nomeItem || data.quantidadeAtual === undefined) {
    throw new HttpsError("invalid-argument", "Os campos 'nomeItem' e 'quantidadeAtual' são obrigatórios.");
  }

  try {
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

    const prompt = `Você é um gestor hospitalar experiente.
                    Analise o estoque do item: ${data.nomeItem}.
                    Quantidade atual em estoque: ${data.quantidadeAtual}.
                    Considere se este item é crítico.
                    Dê uma recomendação muito curta (máximo 2 frases) se deve ou não repor agora e o motivo técnico.`;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    return {
      resultado: text,
      timestamp: new Date().toISOString(),
      status: "sucesso"
    };
  } catch (error) {
    console.error("Erro na chamada da API Gemini:", error);
    throw new HttpsError("internal", "Erro interno ao processar a análise da IA.");
  }
});