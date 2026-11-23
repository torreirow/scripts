# Proposal

## Why

De pijplijn in `egh-preken` levert sterke inspirations — samengestelde shorts
met een hook, kernboodschap, verdieping en punchline — maar zit vast aan
preken: YouTube als bron, Nederlands als taal, een theologische lens en
preek-specifieke woordkeuze in het document. Voor ander videomateriaal
(interviews, lezingen, podcasts, eigen opnames) is er niets.

Er is behoefte aan dezelfde analyse op een **lokaal mediabestand**: één
commando dat transcribeert en daar quotevoorstellen met tijdcode uit haalt,
zonder downloadstap en zonder iets te weten over de herkomst van de video.

## What Changes

- **Nieuw:** een transcriptiestap die elk door `ffmpeg` leesbaar bestand
  aankan, met instelbare of automatisch gedetecteerde taal.
- **Nieuw:** een analysestap die met een algemene rubriek inspirations
  oplevert: shorts opgebouwd uit losse fragmenten met de rollen Hook,
  Kernboodschap, Verdieping en Punchline.
- **Nieuw:** keuze tussen de **Claude Code CLI** en de **OpenCode CLI** als
  analyse-backend, met automatische detectie als standaard.
- **Nieuw:** een orchestrator die beide stappen ketent en overslaat wat er al
  ligt.
- **Overgenomen, niet gedeeld:** de bestaande renderer die de quote letterlijk
  uit het transcript haalt en tijdcodes, duur en waarschuwingen berekent.
- **Niet in scope:** downloaden van YouTube, deeplinks naar de bronvideo,
  video knippen, en de preek-rubriek als standaard.

## Capabilities

### New Capabilities

- `video-inspirations`: van een lokaal mediabestand naar een
  inspirations-document met samengestelde shorts, inclusief transcriptie,
  backend-keuze voor de analyse en de garanties rond tijdcode en letterlijke
  tekst.

### Modified Capabilities

Geen. `video-tools` heeft nog geen specs.

## Impact

- Nieuwe bestanden in `video-tools`: `vid.sh`, `vid-transcribe.sh`,
  `vid-inspire.sh`, `lib/`, `prompts/algemeen.md` en documentatie.
- Externe afhankelijkheden: `ffmpeg`/`ffprobe`, `whisper-cli` (of
  `whisper-ctranslate2`), `awk`, en minimaal één van `claude` of `opencode`.
- Geen wijziging aan `egh-preken`; dat blijft een zelfstandige repo. De
  preek-rubriek kan later als profiel worden toegevoegd.
