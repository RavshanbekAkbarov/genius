// Telegram orqali kirish: ilova {code} yuboradi, bot tasdiqlagan bo'lsa magic-link token qaytaramiz.
// Ilova keyin supabase.auth.verifyOTP({ type: 'magiclink', tokenHash }) ni chaqiradi.
// Bitta mustaqil fayl: Supabase dashboard'dagi web muharririga ham qo'yish mumkin.
import { createClient } from "npm:@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "content-type": "application/json" },
  });
}

const db = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false, autoRefreshToken: false } },
);

const TTL_MS = 10 * 60 * 1000; // kod 10 daqiqa amal qiladi

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  try {
    const body = await req.json().catch(() => ({}));
    const code = typeof body?.code === "string" ? body.code.trim() : "";
    if (!code || code.length > 64) return json({ status: "expired" });

    const { data: row, error: rowErr } = await db
      .from("tg_logins")
      .select("code, tg_id, tg_username, confirmed, created_at")
      .eq("code", code)
      .maybeSingle();
    if (rowErr) throw rowErr;
    if (!row) return json({ status: "expired" });

    if (Date.now() - new Date(row.created_at).getTime() > TTL_MS) {
      await db.from("tg_logins").delete().eq("code", code);
      return json({ status: "expired" });
    }
    if (!row.confirmed || !row.tg_id) return json({ status: "waiting" });

    const tgId = Number(row.tg_id);
    const tgUsername: string | null = row.tg_username ?? null;

    // Bu Telegram hisobiga bog'langan foydalanuvchi bormi?
    const { data: prof, error: profErr } = await db
      .from("profiles")
      .select("id")
      .eq("tg_id", tgId)
      .maybeSingle();
    if (profErr) throw profErr;

    let email: string;
    let userId: string | null = null;
    let isNew = false;

    if (prof) {
      userId = prof.id;
      const { data: u, error: uErr } = await db.auth.admin.getUserById(prof.id);
      if (uErr) throw uErr;
      if (!u.user?.email) throw new Error("foydalanuvchida email yo'q");
      email = u.user.email;
    } else {
      email = `tg${tgId}@telegram.genius.local`;
      const { data: created, error: cErr } = await db.auth.admin.createUser({
        email,
        email_confirm: true,
        user_metadata: { tg_id: tgId, tg_username: tgUsername },
      });
      if (cErr) {
        // Foydalanuvchi oldin yaratilgan bo'lishi mumkin (profil tg_id si bo'shab qolgan) - davom etamiz
        if (!/already|exists|registered/i.test(cErr.message)) throw cErr;
      } else {
        userId = created.user?.id ?? null;
        isNew = true;
      }
    }

    const { data: link, error: lErr } = await db.auth.admin.generateLink({ type: "magiclink", email });
    if (lErr) throw lErr;
    userId = userId ?? link.user?.id ?? null;
    const tokenHash = link.properties?.hashed_token;
    if (!tokenHash) throw new Error("hashed_token yo'q");

    if (userId && !prof) {
      // Profilga Telegram ma'lumotlarini yozamiz (profilni trigger yaratgan)
      const patch: Record<string, unknown> = { tg_id: tgId, tg_username: tgUsername };
      if (isNew && tgUsername && [...tgUsername].length >= 2 && [...tgUsername].length <= 20) {
        patch.nickname = tgUsername;
      }
      const { error: pErr } = await db.from("profiles").update(patch).eq("id", userId);
      if (pErr) console.error("profilni yangilab bo'lmadi:", pErr);
    }

    await db.from("tg_logins").delete().eq("code", code);
    return json({ status: "ok", email, token_hash: tokenHash });
  } catch (e) {
    console.error("tg-login xatosi:", e);
    return json({ status: "error", error: e instanceof Error ? e.message : String(e) }, 500);
  }
});
