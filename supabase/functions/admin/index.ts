// Admin panel uchun funksiya: to'lovni tasdiqlash/rad etish, chekni ko'rish, statistika.
// Faqat admins jadvalidagi foydalanuvchilar chaqira oladi.
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

const TG_BOT_TOKEN = Deno.env.get("TG_BOT_TOKEN") ?? "";

const db = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false, autoRefreshToken: false } },
);

// deno-lint-ignore no-explicit-any
type Any = any;

async function tg(method: string, body: Record<string, unknown>): Promise<Any> {
  if (!TG_BOT_TOKEN) return { ok: false };
  const res = await fetch(`https://api.telegram.org/bot${TG_BOT_TOKEN}/${method}`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  });
  const data = await res.json().catch(() => ({}));
  if (!data.ok) console.error(`Telegram ${method} xatosi:`, JSON.stringify(data));
  return data;
}

function dmy(iso: string | null | undefined): string {
  if (!iso) return "";
  const [y, m, d] = String(iso).slice(0, 10).split("-");
  return `${d}.${m}.${y}`;
}

// Toshkent vaqti (UTC+5, yozgi vaqt yo'q)
function tashkentToday(): string {
  return new Date(Date.now() + 5 * 3600 * 1000).toISOString().slice(0, 10);
}

async function notifyUser(res: Any) {
  if (!res?.tg_id) return;
  let text: string;
  if (res.approved) {
    text = res.kind === "premium"
      ? `✅ To'lov tasdiqlandi! Premium ${dmy(res.premium_until)} gacha yoqildi. Ilovani oching.`
      : `✅ To'lov tasdiqlandi! «${res.book_title ?? String(res.kind).slice(5)}» kitobi ochildi. Ilovani oching.`;
  } else {
    text = "❌ Afsuski, to'lov chekingiz qabul qilinmadi.\n\n" +
      "Agar to'lov qilgan bo'lsangiz, iltimos, o'quv markazi administratori bilan bog'laning.";
  }
  await tg("sendMessage", { chat_id: res.tg_id, text });
}

function toBase64(bytes: Uint8Array): string {
  let bin = "";
  const chunk = 0x8000;
  for (let i = 0; i < bytes.length; i += chunk) {
    bin += String.fromCharCode(...bytes.subarray(i, i + chunk));
  }
  return btoa(bin);
}

function mimeFromPath(path: string): string {
  const ext = path.split(".").pop()?.toLowerCase() ?? "";
  const map: Record<string, string> = {
    jpg: "image/jpeg",
    jpeg: "image/jpeg",
    png: "image/png",
    webp: "image/webp",
    gif: "image/gif",
    pdf: "application/pdf",
  };
  return map[ext] ?? "application/octet-stream";
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  try {
    // Kim chaqiryapti? JWT dan foydalanuvchini aniqlaymiz va admins jadvalini tekshiramiz
    const jwt = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
    if (!jwt) return json({ error: "unauthorized" }, 401);
    const { data: who, error: whoErr } = await db.auth.getUser(jwt);
    if (whoErr || !who.user) return json({ error: "unauthorized" }, 401);
    const { data: adm } = await db.from("admins").select("user_id").eq("user_id", who.user.id).maybeSingle();
    if (!adm) return json({ error: "forbidden" }, 403);

    const body = await req.json().catch(() => ({}));
    const action = String(body?.action ?? "");

    if (action === "approve" || action === "reject") {
      const id = Number(body?.id);
      if (!Number.isInteger(id) || id <= 0) return json({ error: "bad_id" }, 400);
      const { data: res, error } = await db.rpc("decide_payment", { p_id: id, p_approve: action === "approve" });
      if (error) throw error;
      if (!res?.ok) return json({ ok: false, status: res?.status ?? null });
      await notifyUser(res);
      return json({ ok: true, result: res });
    }

    if (action === "receipt") {
      const id = Number(body?.id);
      const { data: pay, error } = await db.from("payments").select("receipt_file_id").eq("id", id).maybeSingle();
      if (error) throw error;
      if (!pay?.receipt_file_id) return json({ error: "no_receipt" }, 404);
      const f = await tg("getFile", { file_id: pay.receipt_file_id });
      if (!f.ok || !f.result?.file_path) return json({ error: "telegram_getfile_failed" }, 502);
      // Telegram fayl manzilida bot tokeni bor, shuning uchun uni brauzerga bermaymiz:
      // faylni shu yerda yuklab, data: URL ko'rinishida qaytaramiz.
      const fileRes = await fetch(`https://api.telegram.org/file/bot${TG_BOT_TOKEN}/${f.result.file_path}`);
      if (!fileRes.ok) return json({ error: "telegram_download_failed" }, 502);
      const bytes = new Uint8Array(await fileRes.arrayBuffer());
      const headerType = fileRes.headers.get("content-type") ?? "";
      const mime = headerType && headerType !== "application/octet-stream"
        ? headerType.split(";")[0]
        : mimeFromPath(f.result.file_path);
      return json({ url: `data:${mime};base64,${toBase64(bytes)}`, mime });
    }

    if (action === "stats") {
      const today = tashkentToday();
      const monthStart = `${today.slice(0, 7)}-01T00:00:00+05:00`;
      const [users, premium, pending, approved] = await Promise.all([
        db.from("profiles").select("id", { count: "exact", head: true }),
        db.from("profiles").select("id", { count: "exact", head: true }).gte("premium_until", today),
        db.from("payments").select("id", { count: "exact", head: true }).eq("status", "pending"),
        db.from("payments").select("amount").eq("status", "approved").gte("decided_at", monthStart),
      ]);
      for (const r of [users, premium, pending, approved]) if (r.error) throw r.error;
      const revenue = (approved.data ?? []).reduce((s: number, r: Any) => s + (r.amount ?? 0), 0);
      return json({
        users: users.count ?? 0,
        premium: premium.count ?? 0,
        revenue_month: revenue,
        pending: pending.count ?? 0,
      });
    }

    return json({ error: "unknown_action" }, 400);
  } catch (e) {
    console.error("admin xatosi:", e);
    return json({ error: e instanceof Error ? e.message : String(e) }, 500);
  }
});
