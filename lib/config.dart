/// Server (Supabase) va Telegram bot sozlamalari.
/// Bo'sh bo'lsa ilova serversiz ishlaydi: kirish va to'lov o'chiq, qolgani telefonda.
/// anon kalit ochiq kalit: u ilova ichida bo'lishi uchun mo'ljallangan (maxfiy service_role kaliti emas).
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

/// To'lov va kirish boti (@ belgisisiz).
const botUsername = String.fromEnvironment('BOT_USERNAME', defaultValue: 'GeniusAuraBot');

/// Google bilan kirgandan keyin ilovaga qaytish manzili (AndroidManifest.xml dagi bilan bir xil).
const authRedirect = 'uz.auraacademy.genius://login-callback';

bool get cloudEnabled => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
