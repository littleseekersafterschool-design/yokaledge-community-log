function send(res, status, body) {
  res.statusCode = status;
  res.setHeader("Content-Type", "application/json; charset=utf-8");
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  res.end(JSON.stringify(body));
}

async function readBody(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  const text = Buffer.concat(chunks).toString("utf8");
  return text ? JSON.parse(text) : {};
}

function outputText(data) {
  if (typeof data.output_text === "string") return data.output_text;
  if (!Array.isArray(data.output)) return "";
  return data.output
    .flatMap((item) => item.content || [])
    .map((content) => content.text || "")
    .join("\n");
}

module.exports = async function handler(req, res) {
  if (req.method === "OPTIONS") return send(res, 204, {});
  if (req.method !== "POST") return send(res, 405, { error: "Method not allowed" });

  try {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      return send(res, 500, { error: "OPENAI_API_KEY is not set." });
    }

    const { facilityName, periodLabel, records } = await readBody(req);
    if (!Array.isArray(records) || records.length === 0) {
      return send(res, 400, { error: "records is required." });
    }

    const compactRecords = records.slice(0, 250).map((record) => ({
      date: String(record.date || ""),
      staff: String(record.staff || ""),
      goal: String(record.goal || ""),
      score: Number(record.score || 0),
      comment: String(record.comment || ""),
    }));

    const response = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: process.env.OPENAI_MODEL || "gpt-5.5",
        input: [
          {
            role: "system",
            content:
              "You support after-school childcare staff reflection. " +
              "Summarize records for operational review, not for blaming individuals. " +
              "Write the final report in Japanese. Be practical, warm, and concise. " +
              "Do not make unsupported diagnoses. Focus on observed trends, useful questions, " +
              "positive signs, concerns, and next actions.",
          },
          {
            role: "user",
            content: JSON.stringify({
              facilityName: facilityName || "facility",
              periodLabel: periodLabel || "selected period",
              records: compactRecords,
              requestedFormat: [
                "1. 全体サマリー",
                "2. 評価項目ごとの傾向",
                "3. コメントから見える具体的な様子",
                "4. 次の週に向けた支援ポイント",
                "5. 確認しておきたいこと",
              ],
            }),
          },
        ],
      }),
    });

    if (!response.ok) {
      const details = await response.text();
      return send(res, 500, {
        error: `OpenAI API request failed: ${response.status} ${details}`,
      });
    }

    const data = await response.json();
    return send(res, 200, { report: outputText(data).trim() });
  } catch (error) {
    return send(res, 500, { error: error.message || String(error) });
  }
};
