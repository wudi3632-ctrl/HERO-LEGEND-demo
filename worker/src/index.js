const JEV_URL = "https://api.typesafe.ai/v1/systemone";
const ALLOWED_ACTIONS = new Set([
  "pressure", "fast_attack", "heavy_attack", "jump_attack", "roll", "block",
]);
const ALLOWED_RANGES = new Set(["melee", "close", "mid", "far"]);

function cors(origin, allowedOrigin) {
  return {
    "Access-Control-Allow-Origin": origin === allowedOrigin ? origin : allowedOrigin,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Max-Age": "86400",
    "Vary": "Origin",
  };
}

function json(data, status, headers) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...headers, "Content-Type": "application/json", "Cache-Control": "no-store" },
  });
}

export default {
  async fetch(request, env) {
    const origin = request.headers.get("Origin") || "";
    const allowedOrigin = env.ALLOWED_ORIGIN || "https://wudi3632-ctrl.github.io";
    const headers = cors(origin, allowedOrigin);

    if (request.method === "OPTIONS") {
      return origin === allowedOrigin ? new Response(null, { status: 204, headers }) : new Response(null, { status: 403 });
    }
    if (request.method !== "POST" || new URL(request.url).pathname !== "/decision") {
      return json({ error: "not_found" }, 404, headers);
    }
    if (origin !== allowedOrigin) {
      return json({ error: "origin_denied" }, 403, headers);
    }

    const contentLength = Number(request.headers.get("Content-Length") || 0);
    if (contentLength > 2048) return json({ error: "request_too_large" }, 413, headers);

    let input;
    try { input = await request.json(); } catch { return json({ error: "invalid_json" }, 400, headers); }
    const phase = Number(input.phase);
    const bossHp = Number(input.boss_hp);
    const playerHp = Number(input.player_hp);
    const range = String(input.range || "");
    const playerAttacking = input.player_attacking === true;
    const legal = Array.isArray(input.legal_actions)
      ? input.legal_actions.map(String).filter((x) => ALLOWED_ACTIONS.has(x)).slice(0, 6)
      : [];
    const recent = Array.isArray(input.recent)
      ? input.recent.map(String).filter((x) => ALLOWED_ACTIONS.has(x)).slice(-3)
      : [];
    if (![1, 2].includes(phase) || !ALLOWED_RANGES.has(range) || legal.length < 2 ||
        !Number.isFinite(bossHp) || bossHp < 0 || bossHp > 1 ||
        !Number.isFinite(playerHp) || playerHp < 0 || playerHp > 1) {
      return json({ error: "invalid_state" }, 400, headers);
    }

    const criteria = {};
    const descriptions = {
      pressure: "Close space aggressively and deny recovery",
      fast_attack: "Quick interrupt that punishes current commitment",
      heavy_attack: "Slow deceptive strike that punishes defensive timing",
      jump_attack: "Catch retreat, landing, or predictable movement",
      roll: "Evade the imminent attack and reposition for a counter",
      block: "Block an imminent attack and retain close-range advantage",
    };
    for (const action of legal) criteria[action] = descriptions[action];

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 1800);
    let upstream;
    try {
      upstream = await fetch(JEV_URL, {
        method: "POST",
        signal: controller.signal,
        headers: { "Authorization": `Bearer ${env.TYPESAFE_API_KEY}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          model: "jev-latest",
          state: JSON.stringify({ phase, boss_hp: bossHp, player_hp: playerHp, range, player_attacking: playerAttacking, recent }),
          questions: { next_tactic: {
            type: "choice",
            instructions: "Act as an expert aggressive action-game boss. Select only a legal move. Maximize pressure, punish commitment, vary recent actions, and remain fair.",
            criteria,
          } },
        }),
      });
    } catch {
      clearTimeout(timeout);
      return json({ error: "jev_timeout" }, 504, headers);
    }
    clearTimeout(timeout);
    if (!upstream.ok) return json({ error: "jev_unavailable" }, 502, headers);

    const result = await upstream.json();
    const decision = result?.answers?.next_tactic || {};
    const action = String(decision.choice || "");
    if (!legal.includes(action)) return json({ error: "invalid_decision" }, 502, headers);
    return json({ action, confidence: Number(decision.confidence || 0) }, 200, headers);
  },
};

