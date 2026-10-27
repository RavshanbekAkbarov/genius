# Genius serverini sozlash bo'yicha qo'llanma

Bu qo'llanma Genius ilovasining "server" qismini (hisob va progress nusxasi, Telegram orqali kirish, to'lovlar va
admin panel) ishga tushirish uchun. Dasturchi bo'lish shart emas — qadamlarni tartib bilan bajaring.
Hammasi bepul. Taxminan 1 soat vaqt ketadi.

Kerak bo'ladi:
- kompyuter va Google Chrome brauzeri;
- GitHub hisobingiz (genius repozitoriyasi turgan hisob);
- Telegram;
- Google hisobi (Gmail).

> 📝 Bir daftar yoki kompyuterda bitta yashirin matn fayli oching. Qadamlar davomida ko'p
> qiymatlar (parol, kalit, token) chiqadi — hammasini o'sha yerga yozib boring.
> Bu daftarni hech kimga ko'rsatmang.

---

## 1-qadam. Supabase loyihasini yaratish

1. [supabase.com](https://supabase.com) saytiga kiring va **Start your project** tugmasini bosing.
2. **Continue with GitHub** ni tanlang va GitHub hisobingiz bilan kiring.
3. **New project** tugmasini bosing.
4. Maydonlarni to'ldiring:
   - **Name:** `genius`
   - **Database Password:** **Generate a password** tugmasini bosing, chiqqan parolni **nusxalab daftarga yozing**
     ("DB parol" deb). Bu parol keyin kerak bo'ladi.
   - **Region:** **Central EU (Frankfurt)** — `eu-central-1` (O'zbekistonga eng yaqini).
5. **Create new project** ni bosing va 2–3 daqiqa kuting.

## 2-qadam. Supabase'dan kerakli qiymatlarni yozib olish

Loyiha ochilgach, chap pastdagi ⚙️ **Project Settings** bo'limiga kiring.

1. **Project URL** — `https://abcdefghijklmnop.supabase.co` ko'rinishidagi manzil.
   (**Project Settings → Data API** yoki **API** sahifasida turadi.)
2. **Project ref** — shu manzildagi `https://` dan keyingi va `.supabase.co` dan oldingi qism
   (misolda: `abcdefghijklmnop`). **Project Settings → General → Project ID** da ham yozilgan.
3. **anon kalit** — **Project Settings → API Keys** sahifasida:
   - **Publishable key** (`sb_publishable_...` bilan boshlanadi), yoki
   - **Legacy API Keys** yorlig'idagi **anon public** kalit (`eyJ...` bilan boshlanadi).
   Ikkalasidan birini oling (yangisi — Publishable key).
4. **DB parol** — 1-qadamda yozib olgan parolingiz. Agar yo'qotgan bo'lsangiz:
   **Project Settings → Database → Reset database password**.
5. **Access token** (GitHub uchun):
   [supabase.com/dashboard/account/tokens](https://supabase.com/dashboard/account/tokens) sahifasiga kiring →
   **Generate new token** → nomiga `github` deb yozing → chiqqan tokenni (`sbp_...`) daftarga yozing.
   U faqat bir marta ko'rsatiladi.

> ⚠️ Shu sahifalarda **service_role** (yoki **Secret key**, `sb_secret_...`) degan kalit ham bor.
> Uni **hech qayerga yozmang va hech kimga yubormang**. Bizga u kerak emas.

## 3-qadam. Telegram botini yaratish

1. Telegram'da [@BotFather](https://t.me/BotFather) ni oching va **/newbot** deb yozing.
2. Bot nomini so'raydi — masalan: `Genius`.
3. Bot username'ini so'raydi — oxiri `bot` bilan tugashi shart, masalan: `GeniusAuraBot`.
   Band bo'lsa, boshqasini o'ylab toping. **Username'ni daftarga yozing** (ilovaga kerak bo'ladi).
4. BotFather sizga **token** beradi (`1234567890:AAH...` ko'rinishida). **Daftarga yozing.**
   Bu token — botning paroli, hech kimga bermang.
5. (Ixtiyoriy) **/setuserpic** bilan botga rasm qo'ying.

Yana bir nechta qiymat tayyorlab qo'ying:

- **ADMIN_CHAT_ID** — sizning Telegram raqamli ID'ingiz. [@userinfobot](https://t.me/userinfobot) ga
  istalgan xabar yozing — u `Id: 123456789` deb javob beradi. Shu raqamni yozib oling.
  To'lov cheklari aynan shu Telegram hisobga keladi.
- **TG_WEBHOOK_SECRET** — o'zingiz o'ylab topadigan uzun maxfiy so'z: faqat lotin harflari va raqamlar,
  kamida 30 ta belgi, masalan `k7Hq2mZp9xLw4rTb8nVc3sYd6fGj1aQe`. Daftarga yozing.
- **PAY_TEXT** — to'lov haqida qo'shimcha matn, masalan:
  `Karta raqami: 8600 1234 5678 9012 (Aliyev Vali)`. Kerak bo'lmasa bo'sh qoldiring.
- **CLICK_QR_URL** — Click QR kodingiz rasmining internetdagi manzili. Uni Supabase'ga shunday yuklaysiz:
  1. Supabase → chapdagi **Storage** → **New bucket** → nomi `public`, **Public bucket** ni yoqing → **Create**.
  2. `public` ichiga kiring → **Upload file** → QR rasmni (`qr.png`) tanlang.
  3. Rasm ustidagi **⋯ → Get URL** (yoki **Copy URL**) ni bosing — chiqqan manzilni daftarga yozing.

  QR bo'lmasa, bu qiymatni bo'sh qoldiring — bot faqat matn yuboradi.

## 4-qadam. GitHub'ga secret'larni qo'shish va serverni ishga tushirish

1. GitHub'da **genius** repozitoriyasini oching.
2. **Settings → Secrets and variables → Actions** ga kiring.
3. Har biri uchun **New repository secret** ni bosib, **Name** va **Secret** ni kiriting:

   | Name | Qiymati |
   |---|---|
   | `SUPABASE_ACCESS_TOKEN` | 2-qadam, 5-band (`sbp_...`) |
   | `SUPABASE_PROJECT_REF` | 2-qadam, 2-band |
   | `SUPABASE_DB_PASSWORD` | DB parol |
   | `TG_BOT_TOKEN` | BotFather bergan token |
   | `TG_WEBHOOK_SECRET` | o'zingiz o'ylab topgan maxfiy so'z |
   | `ADMIN_CHAT_ID` | @userinfobot bergan raqam |
   | `CLICK_QR_URL` | QR rasm manzili (bo'lmasa qo'shmang) |
   | `PAY_TEXT` | to'lov matni (bo'lmasa qo'shmang) |

4. Yuqoridagi **Actions** yorlig'iga o'ting → chapdan **Deploy server** ni tanlang →
   **Run workflow** → **Run workflow** (yashil tugma).
5. 2–4 daqiqa kuting. Yashil ✅ belgi chiqsa — server tayyor.
   Qizil ❌ chiqsa, ustiga bosib qaysi qadam xato bo'lganini ko'ring (ko'pincha secret noto'g'ri yozilgan bo'ladi),
   tuzatib, yana **Run workflow** ni bosing.
6. Tekshirish: Telegram'da botingizni oching va **/start** yozing — bot o'zbekcha salom bilan javob berishi kerak.

> Keyinchalik serverga o'zgarish kiritilsa, bu ish avtomatik qayta ishlaydi.
> Secret'lardan birini o'zgartirsangiz, **Run workflow** ni qo'lda bosing.

## 5-qadam. Google orqali kirishni yoqish

**A. Google Cloud'da kalit olish**

1. [console.cloud.google.com](https://console.cloud.google.com) ga Gmail bilan kiring.
2. Yuqoridagi loyiha tanlagichdan **New project** → nomi `Genius` → **Create**. So'ng shu loyihani tanlang.
3. Qidiruvga **Google Auth Platform** (yoki **OAuth consent screen**) deb yozing va oching →
   **Get started**:
   - **App name:** `Genius`, **User support email:** emailingiz;
   - **Audience:** **External**;
   - **Contact information:** emailingiz → **Create**.
4. **Audience** bo'limida **Publish app** tugmasini bosing (aks holda faqat sinov foydalanuvchilari kira oladi).
5. **Clients** bo'limi → **Create client**:
   - **Application type:** **Web application**
   - **Name:** `Genius Supabase`
   - **Authorized redirect URIs** → **Add URI** →
     `https://<PROJECT_REF>.supabase.co/auth/v1/callback`
     (`<PROJECT_REF>` o'rniga o'zingizning project ref'ingizni yozing).
   - **Create** ni bosing.
6. Chiqqan **Client ID** va **Client secret** ni daftarga yozing.

**B. Supabase'da yoqish**

1. Supabase → **Authentication → Sign In / Providers** (yoki **Providers**) → **Google** →
   **Enable** ni yoqing → **Client ID** va **Client Secret** ni qo'ying → **Save**.
2. **Authentication → URL Configuration** → **Redirect URLs** → **Add URL** →
   `uz.auraacademy.genius://login-callback` → **Save URLs**.
3. Shu yerda **Email** provayderi yoqilgan holda qolsin (u admin kirishi va Telegram orqali kirish uchun kerak).

## 6-qadam. Admin (o'zingiz uchun) hisob yaratish

1. Supabase → **Authentication → Users** → **Add user → Create new user**.
2. Emailingiz va yangi parol kiriting, **Auto Confirm User** belgisini qo'ying → **Create user**.
3. Chapdagi **SQL Editor** → **New query** ga quyidagini yozing (emailni o'zingiznikiga almashtiring):

   ```sql
   insert into admins(user_id) select id from auth.users where email = 'sizning@email.uz';
   ```

4. **Run** ni bosing. `Success. 1 row` chiqishi kerak.
   (Bu 4-qadamdan keyin bajariladi, chunki jadvallar o'shanda yaratiladi.)

## 7-qadam. Admin panelni ochish

1. GitHub'da genius repozitoriyasida `admin/index.html` faylini oching → o'ng tepadagi
   **Download raw file** (⬇️) tugmasini bosib kompyuteringizga yuklab oling.
2. Faylni **Bloknot (Notepad)** bilan oching (sichqonchaning o'ng tugmasi → **Open with → Notepad**).
3. Pastroqda shu ikki qatorni toping:

   ```js
   const SUPABASE_URL = 'PASTE_SUPABASE_URL_HERE';
   const SUPABASE_ANON_KEY = 'PASTE_SUPABASE_ANON_KEY_HERE';
   ```

   `PASTE_...` o'rniga Project URL va anon kalitni qo'ying (qo'shtirnoqlar `'` qolsin). Saqlang (**Ctrl+S**).
4. Faylni ikki marta bosing — Chrome'da ochiladi. 6-qadamdagi email va parol bilan kiring.
5. Panelda:
   - **To'lovlar** — chekni ko'rib, ✅ Tasdiqlash yoki ❌ Rad etish;
   - **Kitoblar** — markaz kitoblarini qo'shish, narx qo'yish, ilovada ko'rsatish;
   - **So'z qo'shish** — kitob va bo'limni tanlab, so'zlarni qo'yish va **Ilovaga yuborish**;
   - **Foydalanuvchilar** — ro'yxat, qidiruv va qo'lda Premium berish.

> To'lov cheklari Telegram'da ham sizga keladi — u yerdagi ✅ / ❌ tugmalari ham ishlaydi.

## 8-qadam. Zaxira nusxa (backup) uchun yopiq repozitoriya

Bu qadam ma'lumotlar yo'qolib qolmasligi va bepul loyiha "uxlab qolmasligi" uchun kerak.

1. GitHub → o'ng tepada **+ → New repository**.
   - **Repository name:** `genius-backup`
   - **Private** ni albatta tanlang! (Zaxirada o'quvchilar va to'lovlar ma'lumotlari bo'ladi.)
   - **Create repository**.
2. Yangi repoda **Add file → Create new file** ni bosing. Fayl nomiga aynan shuni yozing:
   `.github/workflows/backup.yml`
3. genius repozitoriyasidagi `supabase/github/backup.yml` faylini oching, ichidagi hamma matnni nusxalab,
   shu yangi faylga qo'ying → **Commit changes**.
4. `genius-backup` → **Settings → Secrets and variables → Actions** → quyidagi 3 ta secret'ni qo'shing:

   | Name | Qiymati |
   |---|---|
   | `SUPABASE_URL` | Project URL |
   | `SUPABASE_ANON_KEY` | anon kalit |
   | `SUPABASE_DB_URL` | quyida qarang |

   `SUPABASE_DB_URL` ni olish: Supabase loyihangiz tepasidagi **Connect** tugmasi →
   **Session pooler** bo'limidagi manzilni nusxalang (`postgresql://postgres.<ref>:[YOUR-PASSWORD]@...pooler.supabase.com:5432/postgres`)
   va `[YOUR-PASSWORD]` o'rniga DB parolni yozing (kvadrat qavslarsiz).
5. **Actions** → **Genius backup** → **Run workflow**. Yashil ✅ bo'lgach, repoda `backups` papkasi
   paydo bo'ladi. Shundan keyin u har kuni tunda o'zi ishlaydi va oxirgi 30 kunlik nusxani saqlaydi.

## 9-qadam. Claude'ga nimalarni yuborish kerak

Ilovani serverga ulash uchun Claude'ga faqat shu **3 ta** narsani yuboring:

1. **Project URL** (`https://....supabase.co`)
2. **anon (publishable) kalit**
3. **Bot username** (masalan `GeniusAuraBot`)

anon kalitni yuborish xavfsiz: u ataylab ochiq qilib yaratilgan va baribir ilova ichida turadi.
Ma'lumotlarni bazadagi himoya qoidalari (RLS) qo'riqlaydi.

> ⛔ Hech qachon chatga (Claude'ga ham, boshqa hech kimga ham) yubormang:
> - **service_role / Secret key**,
> - **DB parol** va `SUPABASE_DB_URL`,
> - **bot tokeni**,
> - **Access token** (`sbp_...`), Google **Client secret**, **TG_WEBHOOK_SECRET**.
>
> Bular faqat GitHub secret'lari va Supabase sozlamalarida turadi.

## Muammolar

- **Ilova serverga ulanmayapti, Supabase'da "Project paused" yozuvi turibdi.** Bepul loyiha 7 kun ishlatilmasa
  to'xtatiladi. Supabase'ga kiring va **Restore project** tugmasini bosing (bir necha daqiqa). 8-qadamdagi zaxira
  ishi har kuni so'rov yuborib, bunga yo'l qo'ymaydi — u yashil ishlayotganini vaqti-vaqti bilan tekshirib turing.
- **Bot javob bermayapti.** genius repo → **Actions → Deploy server → Run workflow** ni qayta bosing.
  Xato sababini Supabase → **Edge Functions → bot → Logs** da ko'rish mumkin.
- **Admin panelda "Bu hisob administrator emas".** 6-qadamdagi SQL buyrug'ini to'g'ri email bilan bajaring.
- **Admin panel ochilmayapti yoki "PASTE" haqida yozyapti.** 7-qadamni qayta tekshiring (URL va kalit to'g'ri qo'yilganmi).
- **Google bilan kirishda `redirect_uri_mismatch` xatosi.** 5-qadam A-5 dagi manzilni tekshiring:
  `https://<PROJECT_REF>.supabase.co/auth/v1/callback` — bo'sh joy va ortiqcha `/` bo'lmasin.
- **Bepul tarif chegaralari:** baza hajmi ~500 MB, oyiga ~50 000 faol foydalanuvchi, 1 GB fayl xotirasi.
  O'quv markazi uchun bu yetarli. Hajmni Supabase → **Reports** (yoki **Usage**) da ko'rish mumkin.
