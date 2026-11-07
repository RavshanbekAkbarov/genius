// Genius Telegram boti (webhook).
// Oqim: avval "Ismni ulashish" (Telegram profilidan ism olinadi) -> "To'lov qilasizmi?" (karta raqami avtomatik)
// -> "Ilova haqida ma'lumot kerakmi?". Shuningdek ilovaga kirish (login) va to'lov cheklarini qabul qiladi.
// Bitta mustaqil fayl: Supabase dashboard'dagi web muharririga ham to'g'ridan-to'g'ri qo'yish mumkin.
import { createClient } from "npm:@supabase/supabase-js@2";

const TG_BOT_TOKEN = Deno.env.get("TG_BOT_TOKEN") ?? "";
const TG_WEBHOOK_SECRET = Deno.env.get("TG_WEBHOOK_SECRET") ?? "";
const ADMIN_CHAT_ID = (Deno.env.get("ADMIN_CHAT_ID") ?? "").trim();
const CLICK_QR_URL = (Deno.env.get("CLICK_QR_URL") ?? "").trim();
const PAY_TEXT = (Deno.env.get("PAY_TEXT") ?? "").trim();
// To'lov uchun karta raqami va egasining ismi (bot to'lovda avtomatik yuboradi).
// To'lovchilarga baribir ko'rsatiladi, shuning uchun koddagi qiymat; CARD_NUMBER / CARD_OWNER secret'i bo'lsa o'shani oladi.
const CARD_NUMBER = (Deno.env.get("CARD_NUMBER") || "9860040118741160").trim();
const CARD_OWNER = (Deno.env.get("CARD_OWNER") || "Ravshanbek Akbarov").trim();
// Ilovani yuklab olish havolasi (Play Market yoki boshqa) va ixtiyoriy qo'shimcha ma'lumot matni
const APP_URL = (Deno.env.get("APP_URL") ?? "").trim();
const APP_INFO = (Deno.env.get("APP_INFO") ?? "").trim();

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

function esc(t: string): string {
  return t.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

// "8600 1234 5678 9012" ko'rinishida
function cardFmt(c: string): string {
  const d = c.replace(/\D/g, "");
  return d.length === 16 ? d.replace(/(\d{4})(?=\d)/g, "$1 ") : c;
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

const APP_ABOUT = "📱 Genius — Aura Academy o'quv markazining inglizcha so'z yodlash ilovasi.\n\n" +
  "• 4000 Essential English Words (1–6) — bepul\n" +
  "• Markaz kitoblari (Beginner, Foundation, Pre-IELTS va boshqalar) — pullik\n" +
  "• Kartalar va yozish mashqlari, takrorlash jadvali (1, 3, 7, 15, 30 kun)\n" +
  "• Unit hikoyalari: istalgan so'zni bosib tarjimasini ko'rish, tinglash\n" +
  "• O'zingizning so'zlaringiz, kunlik eslatmalar, kunning so'zi\n" +
  "• Premium (10 000 so'm/oy): reklamasiz va cheklovsiz\n\n" +
  "Ilovaga «Telegram bilan kirish» tugmasi orqali kiriladi — xaridlaringiz shu Telegram hisobingizga bog'lanadi.";

// ---------- Telegram foydalanuvchisi (ism ulashish) ----------

type TgUser = { tg_id: number; first_name: string | null; shared_at: string | null; pending_start: string | null };

async function getTgUser(id: number): Promise<TgUser | null> {
  const { data, error } = await db.from("tg_users").select("tg_id, first_name, shared_at, pending_start").eq("tg_id", id)
    .maybeSingle();
  if (error) console.error("tg_users o'qish:", error);
  return data ?? null;
}

async function askShare(msg: Any, pending: string | null) {
  const from = msg.from;
  const { error } = await db.from("tg_users").upsert(
    { tg_id: from.id, tg_username: from.username ?? null, pending_start: pending, updated_at: new Date().toISOString() },
    { onConflict: "tg_id" },
  );
  if (error) console.error("tg_users yozish:", error);
  await send(
    msg.chat.id,
    "Assalomu alaykum! 👋\n\nBu — Genius ilovasining rasmiy boti (Aura Academy).\n\n" +
      "Davom etish uchun pastdagi «📱 Ismni ulashish» tugmasini bosing — ismingizni Telegram profilingizdan olamiz.",
    {
      reply_markup: {
        keyboard: [[{ text: "📱 Ismni ulashish", request_contact: true }]],
        resize_keyboard: true,
        one_time_keyboard: true,
      },
    },
  );
}

async function onContact(msg: Any) {
  const from = msg.from;
  const c = msg.contact;
  if (!c || Number(c.user_id) !== Number(from.id)) {
    await send(msg.chat.id, "Iltimos, o'zingizning profilingizni ulashing: pastdagi «📱 Ismni ulashish» tugmasini bosing.");
    return;
  }
  const pending = (await getTgUser(from.id))?.pending_start ?? "";
  const first = String(c.first_name ?? from.first_name ?? "").trim();
  const { error } = await db.from("tg_users").upsert(
    {
      tg_id: from.id,
      first_name: first || null,
      last_name: c.last_name ?? from.last_name ?? null,
      phone: c.phone_number ?? null,
      tg_username: from.username ?? null,
      shared_at: new Date().toISOString(),
      pending_start: null,
      updated_at: new Date().toISOString(),
    },
    { onConflict: "tg_id" },
  );
  if (error) {
    console.error("tg_users yozish:", error);
    await send(msg.chat.id, "Xatolik yuz berdi, iltimos, yana bir bor urinib ko'ring.");
    return;
  }
  await send(msg.chat.id, `Rahmat${first ? ", " + first : ""}! 😊`, { reply_markup: { remove_keyboard: true } });

  if (pending.startsWith("login_")) return startLogin(msg.chat.id, pending.slice(6));
  if (pending.startsWith("pay_")) return startPay(msg, pending.slice(4));
  await askPay(msg.chat.id);
}

// Telegram foydalanuvchisiga ilova hisobi: bor bo'lsa topamiz, bo'lmasa yaratamiz (ilovaga Telegram bilan
// kirganda ham xuddi shu hisob ochiladi, chunki u ham tg_id bo'yicha qidiradi).
async function ensureAccount(from: Any): Promise<string> {
  const { data: prof, error: pErr } = await db.from("profiles").select("id").eq("tg_id", from.id).maybeSingle();
  if (pErr) throw pErr;
  if (prof) return prof.id;

  const email = `tg${from.id}@telegram.genius.local`;
  let uid: string | null = null;
  const { data: created, error: cErr } = await db.auth.admin.createUser({
    email,
    email_confirm: true,
    user_metadata: { tg_id: from.id, tg_username: from.username ?? null },
  });
  if (cErr) {
    if (!/already|exists|registered/i.test(cErr.message)) throw cErr;
    const { data: link, error: lErr } = await db.auth.admin.generateLink({ type: "magiclink", email });
    if (lErr) throw lErr;
    uid = link.user?.id ?? null;
  } else {
    uid = created.user?.id ?? null;
  }
  if (!uid) throw new Error("foydalanuvchi yaratilmadi");

  const tu = await getTgUser(from.id);
  const patch: Record<string, unknown> = { tg_id: from.id, tg_username: from.username ?? null };
  const nick = [...String(tu?.first_name ?? from.username ?? "").trim()].slice(0, 20).join("");
  if ([...nick].length >= 2) patch.nickname = nick;
  const { error: uErr } = await db.from("profiles").update(patch).eq("id", uid);
  if (uErr) console.error("profilga tg_id yozilmadi:", uErr);
  return uid;
}

// ---------- To'lov qilasizmi? -> karta raqami ----------

async function askPay(chatId: number) {
  await send(chatId, "💳 Pullik kitoblar yoki Premium uchun to'lov qilasizmi?", {
    reply_markup: {
      inline_keyboard: [[
        { text: "✅ Ha, to'lov qilaman", callback_data: "pay:yes" },
        { text: "Yo'q", callback_data: "pay:no" },
      ]],
    },
  });
}

async function askInfo(chatId: number) {
  await send(chatId, "📱 Genius ilovasi haqida ma'lumot kerakmi?", {
    reply_markup: {
      inline_keyboard: [[
        { text: "Ha, kerak", callback_data: "info:yes" },
        { text: "Yo'q, rahmat", callback_data: "info:no" },
      ]],
    },
  });
}

// Bosilgan savol ostidagi tugmalarni olib, tanlovni yozib qo'yamiz
async function closeQuestion(cq: Any, answer: string) {
  await tg("answerCallbackQuery", { callback_query_id: cq.id });
  if (!cq.message) return;
  await tg("editMessageText", {
    chat_id: cq.message.chat.id,
    message_id: cq.message.message_id,
    text: `${cq.message.text ?? ""}\n\n» ${answer}`,
    reply_markup: { inline_keyboard: [] },
  });
}

async function payYes(cq: Any) {
  const chatId = cq.message?.chat?.id ?? cq.from.id;
  await closeQuestion(cq, "Ha, to'lov qilaman");
  let uid: string;
  try {
    uid = await ensureAccount(cq.from);
  } catch (e) {
    console.error("hisob ochilmadi:", e);
    await send(chatId, "Xatolik yuz berdi, birozdan keyin /start ni bosib qaytadan urinib ko'ring.");
    return;
  }
  const [{ data: books }, { data: owned }] = await Promise.all([
    db.from("books").select("id, title, price").eq("published", true).gt("price", 0).order("sort"),
    db.from("purchases").select("book_id").eq("user_id", uid),
  ]);
  const have = new Set((owned ?? []).map((r: Any) => r.book_id));
  const rows: Any[] = [[{ text: `⭐ Premium (30 kun) — ${money(10000)}`, callback_data: "buy:premium" }]];
  for (const b of books ?? []) {
    if (have.has(b.id)) continue;
    const cb = `buy:book:${b.id}`;
    if (new TextEncoder().encode(cb).length > 64) continue;
    rows.push([{ text: `📘 ${b.title} — ${money(b.price)}`, callback_data: cb }]);
  }
  rows.push([{ text: "Bekor qilish", callback_data: "buy:cancel" }]);
  await send(chatId, "Nima uchun to'lov qilasiz?", { reply_markup: { inline_keyboard: rows } });
}

async function buy(cq: Any, kind: string) {
  const chatId = cq.message?.chat?.id ?? cq.from.id;
  if (kind === "cancel") {
    await closeQuestion(cq, "Bekor qilindi");
    await askInfo(chatId);
    return;
  }
  let code: string;
  let uid: string;
  try {
    uid = await ensureAccount(cq.from);
    const { data, error } = await db.rpc("create_pay_code_for", { p_uid: uid, p_kind: kind });
    if (error) throw error;
    code = data as string;
  } catch (e) {
    const m = e instanceof Error ? e.message : String((e as Any)?.message ?? e);
    console.error("to'lov kodi:", m);
    await tg("answerCallbackQuery", {
      callback_query_id: cq.id,
      text: /already_purchased/.test(m) ? "Bu kitob allaqachon sotib olingan ✅" : "Xatolik yuz berdi, qaytadan urinib ko'ring.",
      show_alert: true,
    });
    return;
  }
  const what = await kindLabel(kind);
  await closeQuestion(cq, what);
  const { data: pay } = await db.from("payments").update({ tg_id: cq.from.id }).eq("code", code)
    .select("amount").maybeSingle();
  await payInstructions(chatId, kind, pay?.amount ?? 0);
  await askInfo(chatId);
}

// Karta raqami, summa va chek yuborish haqida ko'rsatma
async function payInstructions(chatId: number, kind: string, amount: number) {
  const what = await kindLabel(kind);
  let t = `🧾 Xarid: ${esc(what)}\n💰 Summa: <b>${money(amount)}</b>\n\n`;
  if (CARD_NUMBER) {
    t += `💳 Karta raqami (bosib nusxa oling):\n<code>${esc(cardFmt(CARD_NUMBER))}</code>\n`;
    if (CARD_OWNER) t += `👤 ${esc(CARD_OWNER)}\n`;
    t += "\n";
  }
  if (PAY_TEXT) t += `${esc(PAY_TEXT)}\n\n`;
  t += "To'lagach, chek rasmini (skrinshot) shu yerga yuboring — tekshirib, tez orada ochib beramiz.";
  if (!CARD_NUMBER && CLICK_QR_URL) {
    const r = await tg("sendPhoto", { chat_id: chatId, photo: CLICK_QR_URL, caption: t.slice(0, 1024), parse_mode: "HTML" });
    if (r.ok) return;
  }
  await send(chatId, t, { parse_mode: "HTML" });
}

async function infoYes(cq: Any) {
  const chatId = cq.message?.chat?.id ?? cq.from.id;
  await closeQuestion(cq, "Ha, kerak");
  const text = APP_ABOUT + (APP_INFO ? `\n\n${APP_INFO}` : "");
  const extra = APP_URL
    ? { reply_markup: { inline_keyboard: [[{ text: "📲 Ilovani yuklab olish", url: APP_URL }]] } }
    : {};
  await send(chatId, text, extra);
}

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

  await payInstructions(chatId, pay.kind, pay.amount);
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
    if (data === "pay:yes") return payYes(cq);
    if (data === "pay:no") {
      await closeQuestion(cq, "Yo'q");
      return askInfo(cq.message?.chat?.id ?? cq.from.id);
    }
    if (data.startsWith("buy:")) return buy(cq, data.slice(4));
    if (data === "info:yes") return infoYes(cq);
    if (data === "info:no") {
      await closeQuestion(cq, "Yo'q, rahmat");
      return send(cq.message?.chat?.id ?? cq.from.id, "Yaxshi! Savolingiz bo'lsa, shu yerga yozing yoki /start ni bosing. 🙂");
    }
    const m = data.match(/^(ok|no):(\d+)$/);
    if (m) return decide(cq, Number(m[2]), m[1] === "ok");
    await tg("answerCallbackQuery", { callback_query_id: cq.id });
    return;
  }

  const msg = update.message;
  if (!msg || !msg.from || msg.chat?.type !== "private") return;

  if (msg.contact) return onContact(msg);

  const text: string = msg.text ?? "";
  const arg = text.startsWith("/start") ? (text.split(/\s+/)[1] ?? "") : "";

  // Avval ism ulashilishi kerak (bosilgan havola eslab qolinadi va ulashgandan keyin davom etadi)
  const tu = await getTgUser(msg.from.id);
  if (!tu?.shared_at) {
    const keep = /^(login|pay)_/.test(arg) ? arg : (tu?.pending_start ?? null);
    return askShare(msg, keep);
  }

  if (arg.startsWith("login_")) return startLogin(msg.chat.id, arg.slice(6));
  if (arg.startsWith("pay_")) return startPay(msg, arg.slice(4));

  if ((Array.isArray(msg.photo) && msg.photo.length) || msg.document) return receipt(msg);

  if (text.startsWith("/start")) {
    await send(msg.chat.id, `Assalomu alaykum${tu.first_name ? ", " + tu.first_name : ""}! 👋`);
  }
  await askPay(msg.chat.id);
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
