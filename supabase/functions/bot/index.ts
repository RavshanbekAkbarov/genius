// Genius Telegram boti (webhook). Kirish (login) va to'lov cheklarini qabul qiladi.
// Bitta mustaqil fayl: Supabase dashboard'dagi web muharririga ham to'g'ridan-to'g'ri qo'yish mumkin.
import { createClient } from "npm:@supabase/supabase-js@2";

const TG_BOT_TOKEN = Deno.env.get("TG_BOT_TOKEN") ?? "";
const TG_WEBHOOK_SECRET = Deno.env.get("TG_WEBHOOK_SECRET") ?? "";
const ADMIN_CHAT_ID = (Deno.env.get("ADMIN_CHAT_ID") ?? "").trim();
const CLICK_QR_URL = (Deno.env.get("CLICK_QR_URL") ?? "").trim();
const PAY_TEXT = (Deno.env.get("PAY_TEXT") ?? "").trim();

const db = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false, autoRefreshToken: false } },
);

// deno-lint-ignore no-explicit-any
type Any = any;

// ---------- Telegram yordamchilari ----------

async function tg(method: string, body: Record<string, unknown>): Promise<Any> {
  const res = await fetch(`https://api.telegram.org/bot${TG_BOT_TOKEN}/${method}`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  });
  const data = await res.json().catch(() => ({}));
  if (!data.ok) console.error(`Telegram ${method} xatosi:`, JSON.stringify(data));
  return data;
}

function send(chatId: number | string, text: string, extra: Record<string, unknown> = {}) {
  return tg("sendMessage", { chat_id: chatId, text, ...extra });
}

function money(n: number): string {
  return String(Math.round(n)).replace(/\B(?=(\d{3})+(?!\d))/g, " ") + " so'm";
}

// "2026-11-16" -> "16.11.2026"
function dmy(iso: string | null | undefined): string {
  if (!iso) return "";
  const [y, m, d] = String(iso).slice(0, 10).split("-");
  return `${d}.${m}.${y}`;
}

async function kindLabel(kind: string): Promise<string> {
  if (kind === "premium") return "Genius Premium (30 kun)";
  if (kind.startsWith("book:")) {
    const id = kind.slice(5);
    const { data } = await db.from("books").select("title").eq("id", id).maybeSingle();
    return `«${data?.title ?? id}» kitobi`;
  }
  return kind;
}

function isAdminChat(cq: Any): boolean {
  if (!ADMIN_CHAT_ID) return false;
  return String(cq.from?.id) === ADMIN_CHAT_ID || String(cq.message?.chat?.id) === ADMIN_CHAT_ID;
}

const WELCOME = "Assalomu alaykum! 👋\n\n" +
  "Bu — Genius ilovasining rasmiy boti.\n" +
  "U ikki narsa uchun kerak:\n" +
  "• Genius ilovasiga Telegram orqali kirish\n" +
  "• Premium yoki kitob uchun to'lov chekini yuborish\n\n" +
  "Buning uchun Genius ilovasini oching va kerakli tugmani bosing — ilova sizni shu yerga o'zi olib keladi.";

// ---------- /start login_<code> ----------

async function startLogin(chatId: number, code: string) {
  if (!/^[A-Za-z0-9_-]{6,58}$/.test(code)) {
    await send(chatId, "Bu havola noto'g'ri. Genius ilovasidan qaytadan urinib ko'ring.");
    return;
  }
  await send(
    chatId,
    "🔐 Genius ilovasiga kirishni tasdiqlaysizmi?\n\n" +
      "⚠️ Agar bu havolani o'zingiz Genius ilovasida bosmagan bo'lsangiz, TASDIQLAMANG! " +
      "Aks holda boshqa odam sizning hisobingizga kirib oladi.",
    {
      reply_markup: {
        inline_keyboard: [[{ text: "✅ Ha, kiraman", callback_data: `login:${code}` }]],
      },
    },
  );
}

async function confirmLogin(cq: Any, code: string) {
  const from = cq.from;
  const { data: row } = await db.from("tg_logins").select("tg_id, confirmed").eq("code", code).maybeSingle();
  if (row && row.confirmed && row.tg_id && Number(row.tg_id) !== Number(from.id)) {
    await tg("answerCallbackQuery", {
      callback_query_id: cq.id,
      text: "Bu kod allaqachon ishlatilgan.",
      show_alert: true,
    });
    return;
  }
  const { error } = await db.from("tg_logins").upsert(
    { code, tg_id: from.id, tg_username: from.username ?? null, confirmed: true },
    { onConflict: "code" },
  );
  if (error) {
    console.error("tg_logins upsert:", error);
    await tg("answerCallbackQuery", { callback_query_id: cq.id, text: "Xatolik yuz berdi, qaytadan urinib ko'ring." });
    return;
  }
  await tg("answerCallbackQuery", { callback_query_id: cq.id });
  // Eski (1 kundan oshgan) kirish kodlarini tozalab qo'yamiz
  await db.from("tg_logins").delete().lt("created_at", new Date(Date.now() - 24 * 3600 * 1000).toISOString());
  if (cq.message) {
    await tg("editMessageText", {
      chat_id: cq.message.chat.id,
      message_id: cq.message.message_id,
      text: "✅ Tayyor! Genius ilovasiga qayting.",
    });
  }
}

// ---------- /start pay_<code> ----------

async function startPay(msg: Any, code: string) {
  const chatId = msg.chat.id;
  const from = msg.from;
  const since = new Date(Date.now() - 24 * 3600 * 1000).toISOString();
  const { data: pay } = await db
    .from("payments")
    .select("id, user_id, kind, amount")
    .eq("code", code)
    .eq("status", "awaiting_receipt")
    .gt("created_at", since)
    .maybeSingle();

  if (!pay) {
    await send(
      chatId,
      "Bu to'lov havolasi topilmadi yoki muddati o'tgan (24 soat). 🙁\n\n" +
        "Iltimos, Genius ilovasida xaridni qaytadan boshlang.",
    );
    return;
  }

  await db.from("payments").update({ tg_id: from.id }).eq("id", pay.id);

  // Profilga Telegram'ni bog'lash (agar hali bog'lanmagan bo'lsa). Takroriy tg_id xatosini e'tiborsiz qoldiramiz.
  const { error: linkErr } = await db
    .from("profiles")
    .update({ tg_id: from.id, tg_username: from.username ?? null })
    .eq("id", pay.user_id)
    .is("tg_id", null);
  if (linkErr) console.log("profil tg_id bog'lanmadi:", linkErr.message);

  const what = await kindLabel(pay.kind);
  let caption = `🧾 Xarid: ${what}\n💰 Summa: ${money(pay.amount)}\n\n`;
  caption += CLICK_QR_URL ? "Yuqoridagi QR kodni Click ilovasida skanerlab to'lang.\n" : "";
  if (PAY_TEXT) caption += `${PAY_TEXT}\n`;
  caption += "\nTo'lagach, chek rasmini (skrinshot) shu yerga yuboring.";

  if (CLICK_QR_URL) {
    const r = await tg("sendPhoto", { chat_id: chatId, photo: CLICK_QR_URL, caption: caption.slice(0, 1024) });
    if (r.ok) return;
  }
  await send(chatId, caption);
}

// ---------- Chek (rasm yoki fayl) ----------

async function receipt(msg: Any) {
  const chatId = msg.chat.id;
  const from = msg.from;

  let fileId = "";
  let isPhoto = false;
  if (Array.isArray(msg.photo) && msg.photo.length) {
    const best = msg.photo.reduce((a: Any, b: Any) =>
      (b.width ?? 0) * (b.height ?? 0) > (a.width ?? 0) * (a.height ?? 0) ? b : a
    );
    fileId = best.file_id;
    isPhoto = true;
  } else if (msg.document?.file_id) {
    fileId = msg.document.file_id;
  }
  if (!fileId) return;

  const { data: pay } = await db
    .from("payments")
    .select("id, user_id, kind, amount")
    .eq("tg_id", from.id)
    .eq("status", "awaiting_receipt")
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (!pay) {
    const { count } = await db
      .from("payments")
      .select("id", { count: "exact", head: true })
      .eq("tg_id", from.id)
      .eq("status", "pending");
    if (count && count > 0) {
      await send(chatId, "Chekingiz allaqachon qabul qilingan va tekshirilmoqda ⏳");
    } else {
      await send(
        chatId,
        "Hozir kutilayotgan to'lov topilmadi. 🙁\n\n" +
          "Iltimos, avval Genius ilovasida xaridni boshlang (Premium yoki kitob tugmasini bosing), " +
          "so'ng chekni shu yerga yuboring.",
      );
    }
    return;
  }

  const { data: upd, error } = await db
    .from("payments")
    .update({ receipt_file_id: fileId, status: "pending" })
    .eq("id", pay.id)
    .eq("status", "awaiting_receipt")
    .select("id")
    .maybeSingle();
  if (error || !upd) {
    console.error("chekni saqlab bo'lmadi:", error);
    await send(chatId, "Xatolik yuz berdi. Iltimos, chekni yana bir bor yuboring.");
    return;
  }

  await send(chatId, "Chek qabul qilindi, tez orada tasdiqlanadi ⏳");

  if (!ADMIN_CHAT_ID) {
    console.error("ADMIN_CHAT_ID sozlanmagan");
    return;
  }
  const { data: prof } = await db.from("profiles").select("nickname").eq("id", pay.user_id).maybeSingle();
  const who = (prof?.nickname ?? "?") + (from.username ? ` (@${from.username})` : "");
  const caption = `🧾 Yangi to'lov #${pay.id}\n` +
    `👤 ${who}\n` +
    `📦 ${await kindLabel(pay.kind)}\n` +
    `💰 ${money(pay.amount)}`;
  const markup = {
    inline_keyboard: [[
      { text: "✅ Tasdiqlash", callback_data: `ok:${pay.id}` },
      { text: "❌ Rad etish", callback_data: `no:${pay.id}` },
    ]],
  };
  if (isPhoto) {
    await tg("sendPhoto", { chat_id: ADMIN_CHAT_ID, photo: fileId, caption, reply_markup: markup });
  } else {
    await tg("sendDocument", { chat_id: ADMIN_CHAT_ID, document: fileId, caption, reply_markup: markup });
  }
}

// ---------- Admin: tasdiqlash / rad etish ----------

async function decide(cq: Any, id: number, approve: boolean) {
  if (!isAdminChat(cq)) {
    await tg("answerCallbackQuery", { callback_query_id: cq.id, text: "Bu tugma faqat administrator uchun." });
    return;
  }
  const { data: res, error } = await db.rpc("decide_payment", { p_id: id, p_approve: approve });
  if (error) {
    console.error("decide_payment:", error);
    await tg("answerCallbackQuery", { callback_query_id: cq.id, text: "Xatolik: " + error.message, show_alert: true });
    return;
  }

  const oldCaption: string = cq.message?.caption ?? cq.message?.text ?? `To'lov #${id}`;
  let resultLine: string;
  if (!res?.ok) {
    const st = res?.status;
    resultLine = st === "approved"
      ? "✅ Allaqachon tasdiqlangan"
      : st === "rejected"
      ? "❌ Allaqachon rad etilgan"
      : "⚠️ Bu to'lov tekshirish holatida emas";
    await tg("answerCallbackQuery", { callback_query_id: cq.id, text: resultLine });
  } else {
    resultLine = approve ? "✅ TASDIQLANDI" : "❌ RAD ETILDI";
    await tg("answerCallbackQuery", { callback_query_id: cq.id, text: resultLine });
    await notifyUser(res);
  }

  if (cq.message) {
    const text = `${oldCaption}\n\n${resultLine}`.slice(0, 1024);
    const method = cq.message.caption !== undefined || cq.message.photo || cq.message.document
      ? "editMessageCaption"
      : "editMessageText";
    await tg(method, {
      chat_id: cq.message.chat.id,
      message_id: cq.message.message_id,
      ...(method === "editMessageCaption" ? { caption: text } : { text }),
      reply_markup: { inline_keyboard: [] },
    });
  }
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
  await send(res.tg_id, text);
}

// ---------- Asosiy ishlov ----------

async function handle(update: Any) {
  if (update.callback_query) {
    const cq = update.callback_query;
    const data: string = cq.data ?? "";
    if (data.startsWith("login:")) return confirmLogin(cq, data.slice(6));
    const m = data.match(/^(ok|no):(\d+)$/);
    if (m) return decide(cq, Number(m[2]), m[1] === "ok");
    await tg("answerCallbackQuery", { callback_query_id: cq.id });
    return;
  }

  const msg = update.message;
  if (!msg || !msg.from || msg.chat?.type !== "private") return;

  const text: string = msg.text ?? "";
  if (text.startsWith("/start")) {
    const arg = text.split(/\s+/)[1] ?? "";
    if (arg.startsWith("login_")) return startLogin(msg.chat.id, arg.slice(6));
    if (arg.startsWith("pay_")) return startPay(msg, arg.slice(4));
    await send(msg.chat.id, WELCOME);
    return;
  }

  if ((Array.isArray(msg.photo) && msg.photo.length) || msg.document) return receipt(msg);

  await send(msg.chat.id, WELCOME);
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("ok");
  if (!TG_WEBHOOK_SECRET || req.headers.get("X-Telegram-Bot-Api-Secret-Token") !== TG_WEBHOOK_SECRET) {
    return new Response("forbidden", { status: 401 });
  }
  try {
    const update = await req.json();
    await handle(update);
  } catch (e) {
    console.error("bot xatosi:", e);
  }
  // Telegram'ga har doim 200 qaytaramiz, aks holda u xabarni qayta-qayta yuboradi
  return new Response("ok");
});
