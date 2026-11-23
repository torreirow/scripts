# Proposal

## Why

De inspirations-pijplijn levert samengestelde shorts, maar geen losse
uitspraken die je als quote-kaart of caption op social media kunt zetten. En
een quote is pas bruikbaar als hij de kern van de video raakt, niet als hij
toevallig mooi klinkt: daarom moet de selectie op een samenvatting rusten.

## What Changes

- **Nieuw:** een samenvattingsstap die uit het transcript een
  `samenvatting.md` maakt met de kernboodschap en de opbouw van de video.
- **Nieuw:** een quote-stap die op basis van die samenvatting en het
  transcript maximaal twintig losse uitspraken selecteert.
- **Nieuw:** een `quotes.md` met per quote tijdcode, duur, letterlijke tekst
  en één regel waarom die quote de kern raakt.
- **Nieuw:** de orchestrator `vid.sh` krijgt de samenvatting en de quotes
  erbij, met dezelfde overslaan-en-hervatten-logica.
- **Niet in scope:** quote-kaarten als afbeelding renderen, publiceren naar
  een platform, of vertalen van de quote.

## Capabilities

### New Capabilities

- `video-summary`: van een transcript naar een samenvatting met
  kernboodschap en opbouw, herbruikbaar als context voor latere analyses.
- `social-quotes`: van een samenvatting plus transcript naar een
  gereedschapsdocument met losse, zelfstandig leesbare quotes met tijdcode.

### Modified Capabilities

Geen. `video-inspirations` blijft ongewijzigd; de nieuwe stappen staan ernaast.

## Impact

- Nieuwe bestanden: `vid-summarize.sh`, `vid-quotes.sh`,
  `prompts/samenvatting.md`, `prompts/quotes.md`, `lib/render-quotes.awk`.
- `vid.sh` krijgt twee extra stappen; bestaande vlaggen blijven werken.
- Geen nieuwe externe afhankelijkheden: dezelfde transcriptie, `awk` en de
  al gekozen analyse-backend.
