# Tasks

## 1. Fundament

- [x] 1.1 Kopieer `lib/common.sh` uit `egh-preken` naar `video-tools` en pas `require_tools` aan zodat alleen de gekozen analyse-backend en de gebruikte transcriptie-backend getoetst worden; verifieer met `bash -n lib/common.sh` en door het script te sourcen met een ontbrekende tool.
- [x] 1.2 Voeg in `lib/common.sh` de helpers `werkmap_voor <bestand>` (pad zonder extensie naast de bron) en `neutrale_map` (tijdelijke lege map) toe; verifieer met een testbestand dat de eerste het verwachte pad geeft en de tweede leeg is.
- [x] 1.3 Voeg de gedeelde argumenthelper voor `--uit`, `--taal`, `--van`, `--tot` en `--force` toe; verifieer met `--help` op een stubscript dat alle opties Parseerbaar zijn.

## 2. Transcriptie

- [x] 2.1 Kopieer `lib/shift-timestamps.py` ongewijzigd en verifieer dat `python3 lib/shift-timestamps.py` zonder argumenten de docstring op stderr toont.
- [x] 2.2 Implementeer `vid-transcribe.sh` met invoer als mediabestand, `--taal auto` als standaard, `--uit` voor de werkmap en `--van`/`--tot`; verifieer met een kort wav-bestand dat `transcript.tsv` ontstaat met de kopregel `start<TAB>end<TAB>text` en oplopende tijden.
- [x] 2.3 Voeg de `cpp`-backend toe (whisper.cpp, `large-v3`, optioneel model downloaden naar `~/.cache/whisper-cpp`); verifieer dat een run zonder GPU een waarschuwing geeft en toch een transcript oplevert.
- [x] 2.4 Voeg de `ctranslate2`- en `openai`-backends toe, inclusief het terugschuiven van tijdcodes via `shift-timestamps.py` bij `ctranslate2`; verifieer met `--van` dat de eerste tijdcode in de buurt van de offset ligt.
- [x] 2.5 Implementeer het overslaan van een bestaand `transcript.tsv` en `--force`; verifieer dat een tweede run meldt dat het transcript overgeslagen wordt en de bestandstijd niet wijzigt.

## 3. Analyse-backend

- [x] 3.1 Implementeer in `lib/common.sh` de functie `analyseer` met `BACKEND=claude` en `BACKEND=opencode`, beide lezend van stdin en schrijvend naar stdout; verifieer met een prompt die `## Short 1` terugvraagt dat stdout alleen die regel bevat.
- [x] 3.2 Implementeer `auto`-detectie en de foutmelding wanneer geen van beide CLI's bestaat; verifieer met een `PATH` zonder beide binaries dat de melding beide namen noemt en exitcode 1 geeft.
- [x] 3.3 Laat de aanroep vanuit een neutrale tijdelijke map draaien en geef `--model`/`VID_MODEL` ongewijzigd door; verifieer met een `AGENTS.md` in de huidige map dat de respons er geen regel uit overneemt.
- [x] 3.4 Voeg een timeout met duidelijke melding toe rond de CLI-aanroep; verifieer met een stub-CLI die blijft hangen dat het script na de ingestelde tijd stopt.

## 4. Inspirations

- [x] 4.1 Kopieer `lib/render-inspirations.awk` en neutraliseer de vaste documentteksten (`preek` → `bron`); verifieer met een klein transcript en een handgemaakte analyse dat de tabel, de duur en de tijdcode kloppen.
- [x] 4.2 Voeg ondersteuning voor een lege `VIDEO_ID` toe en verifieer dat de startkolom alleen `uu:mm:ss.mmm` toont zonder link.
- [x] 4.3 Schrijf `prompts/algemeen.md` met dezelfde uitvoervorm (`## Short N`, `TITEL:`, `WAAROM:`, `FRAGMENT: [[start-eind]] | rol`) en zonder theologische lens; verifieer dat een run op een transcript shortblokken oplevert die de renderer herkent.
- [x] 4.4 Implementeer `vid-inspire.sh` met `--rubriek`, `--profiel`, `--backend`, `--model`, `--auteur`, `--titel` en duurgrenzen via omgevingsvariabelen; verifieer dat een run `inspirations.md` schrijft met minstens één short en de gekozen grenzen toepast.
- [x] 4.5 Implementeer de controle vóór het schrijven (minstens één `## Short`, niet-lege uitvoer) en het atomair vervangen van `inspirations.md`; verifieer met een stub-backend die rommel teruggeeft dat een bestaand document ongewijzigd blijft.

## 5. Orchestrator

- [x] 5.1 Implementeer `vid.sh` die transcriptie en analyse ketent, met dezelfde werkmap en hetzelfde `--uit`; verifieer dat één run vanaf een mediabestand `transcript.tsv` en `inspirations.md` oplevert.
- [x] 5.2 Zorg dat elke stap overslaat wat er ligt en dat `--force-*` per stap werkt; verifieer met een tweede run dat beide stappen overslaan en met `--force-analyse` dat alleen de analyse opnieuw draait.

## 6. Integratie en documentatie

- [x] 6.1 Schrijf `USAGE.md` met de werkwijze, de backend-keuze (inclusief modelnotatie per CLI), de omgevingsvariabelen en de mapstructuur; verifieer dat elk gedocumenteerd commando bestaat en `--help` geeft.
- [x] 6.2 Verifieer de volledige keten op één echt mediabestand met beide backends en vergelijk de documentstructuur; leg vast dat alleen de gekozen fragmenten verschillen en niet het formaat.
- [x] 6.3 Verifieer de foutpaden: onleesbaar bestand, ontbrekend transcript, geen backend, en een backend die niet-JSON/rommel teruggeeft; elk moet een begrijpelijke melding geven en geen half document achterlaten.

## Workflow follow-up

- Archiveer de change nadat de review en de integratiecheck zijn afgerond.
