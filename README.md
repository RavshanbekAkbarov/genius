# Genius · Aura Academy

Aura Academy o'quvchilari uchun inglizcha so'z yodlash ilovasi (Flutter: Android, iOS, web).

## Nima bor

- **Kitoblar:** 4000 Essential English Words 1–6, Beginner, Foundation, Pre-IELTS va shaxsiy ★ "Mening so'zlarim".
- **Mashq:** kartalar (bosilsa inglizchasi o'qiladi, faqat inglizcha tomonda) yoki yozish (uz→en, en→uz). Baholar faqat Qiyin va Oson.
- **Takror:** 1 · 3 · 7 · 15 · 30 kunlik takrorlar, takror jadvali, "Bugungi takrorlar".
- **Olov (streak):** o'tkazib yuborilgan kunni 3 ta reklama bilan saqlash. 20:00 da mashq qilinmasa "Marrangiz kuyadi" ogohlantirishi chiqadi.
- **Limit va Premium:** bepulda kuniga 8 ta mashq, takrorlar doim bepul. Premium 10 000 so'm/oy, Telegram bot orqali (Click/Payme).
- **Boshqa bo'limlar:** do'kon (IELTS kitoblari), do'st taklifi, ota-ona hisoboti, faollik jadvali.

Hamma ma'lumot telefonda saqlanadi (`shared_preferences`).

## Ishga tushirish

```bash
flutter pub get
flutter run            # ulangan telefon yoki emulyatorda
flutter run -d chrome  # brauzerda
flutter test
```

## Telefonda sinash (APK)

Har push'dan keyin GitHub Actions APK yig'adi: **Actions → Build → oxirgi ishga tushish → Artifacts → genius-apk**. Zip ichidagi `app-release.apk` ni Android telefonga o'rnating ("noma'lum manbalardan o'rnatish"ga ruxsat bering).

## Tuzilma

| Yo'l | Nima |
|---|---|
| `lib/data/catalog.dart` | kitoblar, narxlar, oraliqlar, unvonlar |
| `assets/data/words.json` | kitob so'zlari: `"kitob\|unit": [{en, uz, ipa, ex}]` |
| `lib/state/app_state.dart` | butun holat va mantiq (takror, olov, limit, Premium) |
| `lib/screens/` | ekranlar |
| `lib/services/ads.dart` | reklama joylari |
| `lib/services/reminders.dart` | kunlik eslatmalar (09:00, 14:00, 20:00) |
| `lib/services/speech.dart` | inglizcha talaffuz (telefonning ovoz dvigateli) |

## Keyingi qadamlar

- [x] Essential 1-6 so'zlari `assets/data/words.json` da (3600 so'z, tarjima va talaffuz bilan).
- [ ] Beginner, Foundation, Pre-IELTS so'zlarini qo'shish.
- [x] AdMob ulandi (`lib/services/ads.dart`): Android'da haqiqiy ID lar.
- [ ] iOS uchun AdMob ilova va ID lar (`ads.dart`, `Info.plist`).
- [x] Eslatmalar: `lib/services/reminders.dart`, qat'iy 09:00, 14:00, 20:00 (Toshkent vaqti).
- [ ] Server (Railway): Telegram bot orqali Click/Payme to'lovini tasdiqlash, ota-ona hisoboti.
- [ ] Profil "Sinab ko'rish uchun" bo'limini (kunni surish) chiqarishdan oldin olib tashlash.
