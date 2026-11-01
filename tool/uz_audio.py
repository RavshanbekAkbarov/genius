"""O'zbekcha so'zlar uchun ovoz fayllarini yaratish (GitHub Actions'da ishga tushadi).

assets/data/words.json dagi har bir o'zbekcha tarjima uchun bitta mp3 yaratiladi:
assets/audio/uz/<kalit>.mp3. Kalit ilovadagi uzAudioKey() bilan bir xil hisoblanadi.
Bor fayllar qayta yaratilmaydi, shuning uchun yangi so'z qo'shilganda faqat o'shalari yoziladi.
"""

import asyncio
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile

import edge_tts

VOICE = os.environ.get("UZ_VOICE", "uz-UZ-MadinaNeural")
OUT = "assets/audio/uz"
PARALLEL = 6


def key(text: str) -> str:
    """Ilovadagi uzAudioKey bilan bir xil: bo'shliqlar qisqartirilgan matnning sha1 (12 belgi)."""
    norm = re.sub(r"\s+", " ", text.strip())
    return hashlib.sha1(norm.encode("utf-8")).hexdigest()[:12]


def speakable(text: str) -> str:
    """Ovoz dvigateli to'g'ri o'qishi uchun o' va g' ni oʻ, gʻ ga, qolgan apostrofni ʼ ga almashtiramiz."""
    t = re.sub(r"[ʻʼ‘’`´']", "'", text)
    t = re.sub(r"([oOgG])'", lambda m: m.group(1) + "ʻ", t)
    t = t.replace("'", "ʼ")
    return t.replace(";", ",")


async def make(text: str, path: str, sem: asyncio.Semaphore) -> bool:
    async with sem:
        for attempt in range(4):
            try:
                with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as tmp:
                    raw = tmp.name
                await edge_tts.Communicate(speakable(text), VOICE).save(raw)
                # Kichikroq fayl: mono, 22 kHz, 24 kbit/s; boshidagi va oxiridagi jimlik kesiladi.
                subprocess.run(
                    ["ffmpeg", "-loglevel", "error", "-y", "-i", raw,
                     "-af", "silenceremove=start_periods=1:start_threshold=-50dB,areverse,"
                            "silenceremove=start_periods=1:start_threshold=-50dB,areverse",
                     "-ac", "1", "-ar", "22050", "-b:a", "24k", path],
                    check=True,
                )
                os.unlink(raw)
                return True
            except Exception as e:  # tarmoq uzilishi va hokazo: biroz kutib qayta urinamiz
                print(f"Qayta urinish ({attempt + 1}): {text!r}: {e}", file=sys.stderr)
                await asyncio.sleep(2 * (attempt + 1))
        return False


async def main() -> int:
    words = json.load(open("assets/data/words.json", encoding="utf-8"))
    texts = sorted({w["uz"].strip() for unit in words.values() for w in unit if w["uz"].strip()})
    os.makedirs(OUT, exist_ok=True)
    todo = [(t, os.path.join(OUT, key(t) + ".mp3")) for t in texts]
    todo = [(t, p) for t, p in todo if not os.path.exists(p)]
    print(f"Jami {len(texts)} ta, yaratiladi: {len(todo)} ta")
    sem = asyncio.Semaphore(PARALLEL)
    results = await asyncio.gather(*(make(t, p, sem) for t, p in todo))
    failed = [t for (t, _), ok in zip(todo, results) if not ok]
    print(f"Tayyor: {len(todo) - len(failed)}, xato: {len(failed)}")
    for t in failed[:20]:
        print("  xato:", t)
    return 1 if len(failed) > len(todo) // 10 else 0


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
