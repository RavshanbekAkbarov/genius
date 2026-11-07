/// Server (Supabase) va Telegram bot sozlamalari.
/// Bo'sh bo'lsa ilova serversiz ishlaydi: kirish va to'lov o'chiq, qolgani telefonda.
/// anon kalit ochiq kalit: u ilova ichida bo'lishi uchun mo'ljallangan (maxfiy service_role kaliti emas).
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

/// To'lov va kirish boti (@ belgisisiz).
const botUsername = String.fromEnvironment('BOT_USERNAME', defaultValue: 'GeniusAuraBot');

/// Play Market versiyasi: `--dart-define=STORE=play` bilan yig'iladi.
/// Google qoidasiga ko'ra bu versiyada ilova ichida sotib olish tugmalari, narxlar va
/// to'lovga yo'naltirish bo'lmaydi. Kitob va Premium markazda yoki botda olinadi va
/// hisobga bog'langani uchun ilovada o'zi ochiladi. Sayt va APK versiyasida tugmalar bor.
const storeBuild = String.fromEnvironment('STORE') == 'play';
const inAppPurchase = !storeBuild;

/// Play versiyasida pullik narsa haqida ko'rsatiladigan matn.
const askTeacherText =
    "Ochish uchun ustozingiz yoki markaz administratoriga murojaat qiling. Ochilgach, shu yerda o'zi paydo bo'ladi.";
const askTeacherTail =
    "ustozingiz yoki markaz administratoriga murojaat qiling. Ochilgach, shu yerda o'zi paydo bo'ladi.";

bool get cloudEnabled => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
