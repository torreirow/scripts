# Design

## Context

Zie `proposal.md` — Why. Wat de aanpak vormt:

- `egh-preken` bevat een werkende pijplijn (`preek-transcribe.sh`,
  `preek-inspiratie.sh`, `lib/render-inspirations.awk`) die zich heeft bewezen
  op tientallen preken. Het is een aparte repository, dus code delen kan niet;
  overnemen wel.
- De renderer is het waardevolle deel: die haalt de quote letterlijk uit de
  TSV en rekent tijdcodes, duur, waarschuwingen en de montagevolgorde zelf.
  Die blijft ongewijzigd op de documentkoppen na.
- Beide analyse-CLI's zijn lokaal aanwezig en hebben dezelfde vorm: prompt via
  stdin, platte tekst op stdout. Geverifieerd:
  - `claude -p --output-format text` leest stdin, schrijft alleen de respons
    naar stdout.
  - `opencode run` zonder message-argument leest stdin, schrijft de respons
    naar stdout en de banner (`> build · <model>`) naar stderr.
- Er is geen downloadstap, dus geen `audio.info.json`, geen video-ID en dus
  geen deeplinks. De renderer ondersteunt dat al: zonder `VIDEO_ID` toont hij
  alleen tijdcode.

## Goals / Non-Goals

**Goals:**

- Twee zelfstandig bruikbare stappen (transcriberen, analyseren) plus een
  orchestrator, met dezelfde scheiding als in `egh-preken`.
- De analyse-backend is een implementatiedetail achter één functie, zodat de
  rest van de keten niet weet welke CLI draait.
- Uitvoer is deterministisch genoeg om te vergelijken: geen projectcontext,
  geen tools, geen netwerk tijdens de analyse.

**Non-Goals:**

- Delen van code met `egh-preken` of dat project aanpassen.
- Video knippen, ondertitels branden, of een PDF-generator meenemen.
- Meerdere video's in één run (batch).
- Een GUI of configuratiebestand; omgevingsvariabelen en flags volstaan.

## Decisions

### Drie scripts, geen plugin-architectuur

```
vid-transcribe.sh <bestand> [--taal auto|nl|...] [--van T] [--tot T] [--uit MAP]
vid-inspire.sh    <bestand|werkmap> [--backend ...] [--model ...] [--rubriek FILE]
vid.sh            <bestand> [flags van beide]
```

De scheiding volgt de kostenverdeling: transcriptie is duur en zeldzaam,
analyse is goedkoop en wordt tientallen keren bijgesteld. Bestanden op schijf
zijn de cache; geen vlaggenstelsel nodig.

*Alternatief:* één script met `--alleen-transcribe`. Verworpen — dan moet elke
rubriek-iteratie door dezelfde vertakking en zijn de stappen niet los
aanroepbaar.

### Werkmap per bronbestand

Standaard `<map van bron>/<bestandsnaam zonder extensie>/`, te overschrijven
met `--uit`. Daarbinnen dezelfde namen als in `egh-preken`
(`transcript.*`, `inspirations.md`), zodat de renderer en de documentatie
één-op-één meeverhuizen en een eventuele `-knip`-stap later dezelfde paden
kan gebruiken.

*Alternatief:* artefacts naast het bronbestand. Verworpen — vijf
transcriptformaten in `~/Videos` is rommel en de bestandsnaam moet dan overal
als prefix mee.

### Backend als één functie in `lib/common.sh`

```bash
analyseer() {          # leest stdin, schrijft stdout
    case "$BACKEND" in
        claude)   claude -p --output-format text ${MODEL:+--model "$MODEL"} ;;
        opencode) ( cd "$NEUTRALE_MAP" && opencode run ${MODEL:+-m "$MODEL"} ) ;;
    esac
}
```

`BACKEND=auto` kiest `claude` als die bestaat, anders `opencode`, anders
stopt het script met een melding die beide noemt. `--backend` wint altijd.
Eén modelvariabele (`--model` / `VID_MODEL`); de waarde gaat letterlijk door,
want `claude` verwacht een alias en `opencode` een `provider/model`-pad.

Zonder model kiest `claude` zijn eigen standaard. Voor `opencode` ligt dat
anders: het algemene provider-model valt buiten het abonnement en faalt met
een saldomelding. Daarom krijgt `opencode` een eigen standaard,
`opencode-go/deepseek-v4.1-flash`, te overschrijven met `VID_OPENCODE_MODEL`.
Die keuze is in deze sessie op de echte analyse getest en levert dezelfde
documentstructuur als `claude`.

`require_tools` toetst alleen de gekozen backend. Anders weigert het script op
een machine waar precies één van de twee staat.

*Alternatief:* de analyse in Python met de SDK's. Verworpen — de rest van de
keten is bash, en beide CLI's doen exact wat nodig is.

### OpenCode vanuit een neutrale map

`opencode run` ontdekt `AGENTS.md` en projectregels in de huidige map en kan
uit zichzelf bestanden openen. Voor een reproduceerbare analyse draait de
aanroep daarom in een tijdelijke lege map (`cd "$NEUTRALE_MAP" && opencode run
...`). De prompt komt volledig via stdin, dus er is geen pad nodig.

Zelfde reden om `claude` niet vanuit de projectmap te draaien: `CLAUDE.md`
zou meegenomen worden. Beide backends krijgen dus dezelfde neutrale map.

*Alternatief:* een eigen minimale OpenCode-agent zonder tools. Verworpen —
  extra configuratie die de gebruiker moet onderhouden, terwijl de lege map
  hetzelfde bereikt zonder installatiestap.

### Transcriptie via whisper.cpp, met dezelfde terugvalpaden

De transcriptiestap is een verbatim overname van `preek-transcribe.sh` met
deze wijzigingen:

| Wijziging | Reden |
|---|---|
| invoer is een willekeurig mediabestand, niet `audio.m4a` | geen vaste downloadnaam meer |
| taal standaard `auto` in plaats van `nl` | willekeurige video's |
| vocabulaire optioneel | geen namenlijst per kanaal |
| `audio.info.json` vervalt | geen yt-dlp |
| `--uit` bepaalt de werkmap | mappenstructuur los van de bron |

De backends `cpp`, `ctranslate2` en `openai` blijven bestaan, met `cpp` als
standaard. `lib/shift-timestamps.py` wordt alleen bij `ctranslate2` gebruikt,
omdat die backend vooraf knipt.

### Rubriek algemeen, profiel verwisselbaar

`prompts/algemeen.md` is de standaard: dezelfde fragmentdefinitie (afgeronde
uitspraak, zelfstandig te begrijpen, geen aanloop), dezelfde vier rollen en
dezelfde uitvoervorm `## Short N` / `TITEL:` / `WAAROM:` / `FRAGMENT:`.
Wat verdwijnt is de theologische lens en de preekwoordenschat; wat blijft is
de eis dat een fragment een bewering doet en zonder context te volgen is.

`--rubriek FILE` laat een eigen bestand gebruiken; `--profiel preek` is een
gereserveerde naam voor een later toe te voegen rubriek. Het contract met de
renderer is de uitvoervorm, niet de inhoud van de rubriek.

### Renderer overgenomen, koppen geneutraliseerd

`lib/render-inspirations.awk` wordt gekopieerd. Wijzigingen blijven beperkt tot
de vaste documentteksten: "preek" → "bron", "de preek" → "de bron". De
roltabel, de controle op halve zinnen, de duurberekening en de
montagewaarschuwing blijven identiek.

### Schrijven is atomair

`inspirations.md` wordt naar een tijdelijk bestand geschreven en pas met `mv`
vervangen als de analyse herkenbare shortblokken opleverde. Mislukt de
backend of is de uitvoer leeg, dan blijft het bestaande document staan. Dat
is hetzelfde patroon als in `egh-preken`.

## Risks / Trade-offs

| Risico | Mitigatie |
|---|---|
| Whisper hallucineert bij muziek en stilte | stiltedrempel, `--condition_on_previous_text` uit, duidelijke waarschuwing in de documentatie |
| Automatische taaldetectie faalt op lange opnames met muziek | `--taal` blijft expliciet te zetten; de detectie is de gemaksstandaard, niet de enige weg |
| OpenCode leest toch projectcontext of opent bestanden | neutrale map; de prompt bevat alle invoer via stdin |
| Modelnotatie verschilt per CLI en geeft een cryptische fout | één variabele, documentatie met een voorbeeld per backend, en de fout van de CLI ongefilterd doorgeven |
| `opencode run` kan lang hangen of om bevestiging vragen | `--auto` waar nodig, en de aanroep krijgt een timeout met een duidelijke melding |
| Een lange video levert een enorm transcript en dus veel tokens | de TSV is de magerste vorm; bij afkapping is `--van`/`--tot` het antwoord |
| De renderer verwacht exact `## Short N` | de prompt schrijft dat letterlijk voor en het script controleert erop vóór het schrijft |

## Migration Plan

Nieuw project, geen migratie. `egh-preken` blijft ongewijzigd; de preek-rubriek
kan later als `prompts/preek.md` en `--profiel preek` worden toegevoegd.

## Open Questions

Geen.
