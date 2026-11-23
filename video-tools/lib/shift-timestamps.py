#!/usr/bin/env python3
"""Schuift alle tijdcodes in Whisper-uitvoer op met een offset.

Nodig wanneer de audio vooraf is ingekort: het transcript begint dan bij nul
terwijl de tijden moeten kloppen met het originele bestand, zodat deeplinks
en knippunten naar het juiste moment wijzen.

    shift-timestamps.py <map> <offset-in-ms>
"""
import json
import re
import sys
from pathlib import Path


def tc(ms: int, sep: str) -> str:
    h, rest = divmod(ms, 3600_000)
    m, rest = divmod(rest, 60_000)
    s, ms = divmod(rest, 1000)
    return f"{h:02d}:{m:02d}:{s:02d}{sep}{ms:03d}"


def shift_tsv(p: Path, off: int) -> None:
    regels = p.read_text().splitlines()
    uit = [regels[0]] if regels else []
    for regel in regels[1:]:
        velden = regel.split("\t")
        if len(velden) >= 3 and velden[0].isdigit() and velden[1].isdigit():
            velden[0] = str(int(velden[0]) + off)
            velden[1] = str(int(velden[1]) + off)
        uit.append("\t".join(velden))
    p.write_text("\n".join(uit) + "\n")


def shift_json(p: Path, off: int) -> None:
    data = json.loads(p.read_text())
    sec = off / 1000

    def bump(d):
        for sleutel in ("start", "end"):
            if isinstance(d.get(sleutel), (int, float)):
                d[sleutel] = round(d[sleutel] + sec, 3)

    for segment in data.get("segments", []):
        bump(segment)
        for woord in segment.get("words", []) or []:
            bump(woord)
    p.write_text(json.dumps(data, ensure_ascii=False))


def shift_ondertitels(p: Path, off: int, sep: str) -> None:
    patroon = re.compile(r"(\d{2}):(\d{2}):(\d{2})[.,](\d{3})")

    def vervang(m):
        ms = (int(m[1]) * 3600_000 + int(m[2]) * 60_000
              + int(m[3]) * 1000 + int(m[4]) + off)
        return tc(max(ms, 0), sep)

    p.write_text(patroon.sub(vervang, p.read_text()))


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2

    map_, off = Path(sys.argv[1]), int(sys.argv[2])
    if off == 0:
        return 0

    gedaan = []
    for naam, functie in (
        ("transcript.tsv",  lambda p: shift_tsv(p, off)),
        ("transcript.json", lambda p: shift_json(p, off)),
        ("transcript.srt",  lambda p: shift_ondertitels(p, off, ",")),
        ("transcript.vtt",  lambda p: shift_ondertitels(p, off, ".")),
    ):
        p = map_ / naam
        if p.exists():
            functie(p)
            gedaan.append(naam)

    print(f"tijdcodes opgeschoven met {off} ms: {', '.join(gedaan)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
