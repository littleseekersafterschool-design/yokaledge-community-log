const TABLES = {
  facilities: "facility_id",
  staff: "staff_id",
  goals: "goal_id",
  daily_logs: "log_id",
};

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

function supabaseRequest(path, init = {}) {
  const url = process.env.SUPABASE_URL;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !serviceKey) {
    throw new Error("SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY is not set.");
  }

  return fetch(`${url}/rest/v1/${path}`, {
    ...init,
    headers: {
      apikey: serviceKey,
      Authorization: `Bearer ${serviceKey}`,
      "Content-Type": "application/json",
      ...(init.headers || {}),
    },
  });
}

async function fetchTable(table) {
  const response = await supabaseRequest(`${table}?select=*`);
  if (!response.ok) {
    throw new Error(`Supabase read failed: ${table} ${response.status}`);
  }
  return response.json();
}

async function bootstrap() {
  const [facilities, staff, goals, dailyLogs] = await Promise.all([
    fetchTable("facilities"),
    fetchTable("staff"),
    fetchTable("goals"),
    fetchTable("daily_logs"),
  ]);

  return {
    facilities,
    staff,
    goals,
    daily_logs: dailyLogs,
  };
}

async function upsert({ table, idColumn, data }) {
  if (!TABLES[table] || TABLES[table] !== idColumn || !data) {
    throw new Error("Invalid upsert request.");
  }

  const id = data[idColumn];
  if (!id) throw new Error("Missing row id.");

  const response = await supabaseRequest(
    `${table}?${idColumn}=eq.${encodeURIComponent(id)}`,
    {
      method: "PATCH",
      headers: { Prefer: "return=representation" },
      body: JSON.stringify(data),
    }
  );

  if (!response.ok) {
    throw new Error(`Supabase upsert update failed: ${response.status}`);
  }

  const updated = await response.json();
  if (Array.isArray(updated) && updated.length > 0) {
    return { row: updated[0] };
  }

  const insertedResponse = await supabaseRequest(table, {
    method: "POST",
    headers: { Prefer: "return=representation" },
    body: JSON.stringify(data),
  });

  if (!insertedResponse.ok) {
    const details = await insertedResponse.text();
    throw new Error(`Supabase insert failed: ${insertedResponse.status} ${details}`);
  }

  const inserted = await insertedResponse.json();
  return { row: Array.isArray(inserted) ? inserted[0] : inserted };
}

async function deleteRow({ table, idColumn, id }) {
  if (!TABLES[table] || TABLES[table] !== idColumn || !id) {
    throw new Error("Invalid delete request.");
  }

  const response = await supabaseRequest(
    `${table}?${idColumn}=eq.${encodeURIComponent(id)}`,
    { method: "DELETE" }
  );

  if (!response.ok) {
    throw new Error(`Supabase delete failed: ${response.status}`);
  }

  return { ok: true };
}

module.exports = async function handler(req, res) {
  if (req.method === "OPTIONS") return send(res, 204, {});
  if (req.method !== "POST") return send(res, 405, { error: "Method not allowed" });

  try {
    const body = await readBody(req);
    if (body.action === "bootstrap") {
      return send(res, 200, await bootstrap());
    }
    if (body.action === "upsert") {
      return send(res, 200, await upsert(body));
    }
    if (body.action === "delete") {
      return send(res, 200, await deleteRow(body));
    }
    return send(res, 400, { error: "Unknown action" });
  } catch (error) {
    return send(res, 500, { error: error.message || String(error) });
  }
};
