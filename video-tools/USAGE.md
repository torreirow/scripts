# Video-inspiraties — gebruiksinstructies

## Doel

Van een lokaal mediabestand naar een inspirations-document: een transcript
plus een reeks **samengestelde shorts** met tijdcode, functie en letterlijke
quote — klaar om te monteren.

Geen download, geen YouTube-ID, geen deeplinks. Je geeft een bestand op dat
`ffmpeg` kan lezen en krijgt een map met alles erin.

```
interview.mp4  ──▶  interview/transcript.tsv  ──▶  interview/inspirations.md
```

## Snel beginnen

```bash
./vid.sh interview.mp4
```

Dat doet achter elkaar:

| Stap | Script             | Duurt   | Levert                          |
|------|--------------------|---------|---------------------------------|
| 1    | `vid-transcribe.sh`| minuten | `transcript.tsv` en vier andere formaten |
| 2    | `vid-inspire.sh`   | seconden| `inspirations.md`               |

Elke stap slaat over wat er al ligt, dus een afgebroken run pak je op met
hetzelfde commando.

## Mapstructuur

```
interview/
  transcript.tsv      segmenten met milliseconden — voedt de analyse
  transcript.txt      leesbaar transcript
  transcript.json     inclusief woord-timestamps
  transcript.srt      ondertitels
  transcript.vtt      ondertitels
  inspirations.md     ← de knipopdracht
```

Standaard ontstaat die map naast de bron, genoemd naar het bestand zonder
extensie. Met `--uit` kies je een eigen werkmap:

```bash
./vid.sh --uit /tmp/analyse interview.mp4
```

## Losse stappen

Handig als je alleen de analyse opnieuw wilt draaien, bijvoorbeeld nadat je
de rubriek hebt aangepast:

```bash
./vid-transcribe.sh interview.mp4     # alleen transcriberen
./vid-inspire.sh    interview/        # alleen analyseren
```

De analyse draait altijd opnieuw en kost seconden. De transcriptie hoeft
daar niet voor over.

Elk script heeft `--help`.

## De analyse-backend

De analyse gaat via de Claude Code CLI of de OpenCode CLI. Zonder keuze kiest
het script `claude` als die bestaat, anders `opencode`.

```bash
./vid-inspire.sh --backend claude   interview/
./vid-inspire.sh --backend opencode interview/
```

De modelwaarde gaat **ongewijzigd** naar de CLI, en de notatie verschilt per
backend:

| Backend | Modelnotatie | Standaard |
|---------|--------------|-----------|
| `claude` | alias | het model van de CLI zelf |
| `opencode` | `provider/model` | `opencode-go/deepseek-v4.1-flash` |

Zonder model gebruikt `opencode` dus altijd een model van de provider
`opencode-go`. Het algemene provider-model valt buiten het abonnement en
faalt met een saldomelding. Een ander model kiezen kan met `--model`, of met
`VID_OPENCODE_MODEL` als je een andere standaard wilt.

```bash
./vid-inspire.sh --backend opencode \
                 --model opencode-go/deepseek-v4.1-flash interview/
```

De CLI draait vanuit een lege tijdelijke map. Daardoor komen `AGENTS.md`,
`CLAUDE.md` en projectregels uit de map waar je staat niet in de analyse
terecht.

## Wat er in het document staat

Elke short is **opgebouwd uit meerdere fragmenten** die verspreid door de
bron liggen. De tabel staat in montagevolgorde, die bewust mag afwijken van
de volgorde in de bron. Elk fragment heeft een functie:

| Functie | Wat het doet |
|---------------|-----------------------------------------------|
| Hook | opent en trekt de kijker binnen |
| Kernboodschap | de stelling waar alles om draait |
| Verdieping | geeft de grond onder die stelling |
| Punchline | de zin die blijft hangen |

Het taalmodel levert alleen de tijdgrenzen. De quote komt letterlijk uit het
transcript en de tijdcode, duur en waarschuwing worden door het script
berekend. Een quote kan dus niet opgepoetst worden.

Tijdcodes liggen op zinsgrenzen uit een automatische transcriptie, niet op
woordgrenzen: trim de in- en uitpunten op gehoor bij, reken op ongeveer een
halve seconde speling.

## Alleen een deel van de opname

Staat er een lange opname waarin maar een deel telt, geef dan het tijdvak op:

```bash
./vid.sh --van 0:47:02 --tot 1:25:55 dienst.mp4
```

Tijden mogen als `u:mm:ss`, `mm:ss` of een kaal aantal seconden. De
tijdcodes in het transcript blijven gerekend **vanaf het begin van het hele
bestand**, dus de knippunten kloppen gewoon.

## De taal

Standaard laat het script de taal detecteren:

```bash
./vid.sh gesprek.mkv
```

Weet je het zeker, zet hem dan vast. Dat is bij lange opnames met muziek
of achtergrondgeluid betrouwbaarder:

```bash
./vid.sh --taal nl interview.mp4
```

## Bijstellen

### De duur van de shorts

De band staat standaard op 30 tot 90 seconden. Shorts daarbuiten blijven in
het document staan maar krijgen een ⚠-markering.

```bash
VID_SHORT_MAX=60 ./vid-inspire.sh interview/
```

### Wat er geselecteerd wordt

`prompts/algemeen.md` bevat de selectierubriek. Dit is het bestand dat je
bijschaaft. Een eigen rubriek gaat met `--rubriek`:

```bash
./vid-inspire.sh --rubriek prompts/mijn-rubriek.md interview/
```

`--profiel NAAM` is een korte vorm voor `prompts/NAAM.md`:

```bash
./vid-inspire.sh --profiel interview interview/
```

Na een wijziging hoef je alleen de analyse opnieuw te draaien.

### De naam van de spreker

De titels volgen de huisstijl "quote — naam spreker". Die naam is niet uit
het bestand te halen, dus geef hem zelf op:

```bash
./vid-inspire.sh --auteur "Jan Jansen" interview/
```

Laat je hem weg, dan blijft de naam uit de titels. Geen naam is beter dan de
verkeerde naam onder iemands woorden.

### De titel van de bron

Geef je een titel op, dan weegt het model die mee bij het kiezen van
fragmenten en ziet de editor bovenaan waar het over ging:

```bash
./vid-inspire.sh --auteur "Jan Jansen" --titel "Over verwachtingen" interview/
```

### Namen die Whisper verhaspelt

Een vocabulairebestand gaat als context mee naar Whisper. Verstaat hij een
naam verkeerd, zet die er dan bij en transcribeer opnieuw:

```bash
VID_VOCAB=prompts/vocabulaire.txt ./vid-transcribe.sh --force interview.mp4
```

Houd het bestand kort: Whisper kapt af rond 150 woorden.

## Omgevingsvariabelen

| Variabele                 | Standaard         | Wat het doet                          |
|---------------------------|-------------------|---------------------------------------|
| `VID_UIT`                 | leeg              | Werkmap                               |
| `VID_TAAL`                | `auto`            | Taal van de audio                     |
| `VID_WHISPER_BACKEND`     | `cpp`             | `cpp`, `ctranslate2` of `openai`      |
| `VID_WHISPER_MODEL`       | `large-v3`        | Whisper-model                         |
| `VID_WHISPER_THREADS`     | alle cores        | CPU-threads                           |
| `VID_COMPUTE_TYPE`        | `float32`         | Alleen bij `ctranslate2`              |
| `VID_SILENCE_THRESHOLD`   | `2`               | Stiltedrempel in seconden             |
| `VID_VOCAB`               | leeg              | Vocabulairebestand voor Whisper       |
| `VID_CARRY_PROMPT`        | `false`           | Vocabulaire bij elk venster (cpp)     |
| `VID_CPP_MODEL_DIR`       | `~/.cache/whisper-cpp` | Map met ggml-modellen            |
| `VID_SPEED_FACTOR`        | per backend       | Factor tijdsindicatie                 |
| `VID_ANALYSE_BACKEND`     | `auto`            | `claude`, `opencode` of `auto`        |
| `VID_MODEL`               | leeg              | Model voor de analyse-CLI             |
| `VID_OPENCODE_MODEL`      | `opencode-go/deepseek-v4.1-flash` | Standaardmodel bij backend opencode |
| `VID_ANALYSE_TIMEOUT`     | `600`             | Timeout in seconden                   |
| `VID_SHORT_MIN`           | `30`              | Ondergrens shortduur in seconden      |
| `VID_SHORT_MAX`           | `90`              | Bovengrens shortduur in seconden      |
| `VID_PROFIEL`             | `algemeen`        | Rubriek uit `prompts/<naam>.md`       |
| `VID_RUBRIEK`             | leeg              | Pad naar een eigen rubriek            |
| `VID_AUTEUR`              | leeg              | Naam van de spreker                   |
| `VID_TITEL`               | leeg              | Titel van de bron                     |

## Vereisten

```bash
ffmpeg -version      # audio omzetten en knippen
ffprobe -version     # duur uitlezen (onderdeel van ffmpeg)
whisper-cli -h       # transcriberen (whisper.cpp)
claude --version     # analyse, of:
opencode --version   # analyse
awk --version        # de renderer
```

`whisper-cli` mag ontbreken als `nix` beschikbaar is; dan haalt het script
whisper.cpp uit nixpkgs. Voor de andere transcriptie-backends zijn `whisper`
(openai-whisper) of `whisper-ctranslate2` nodig.

## Waarom het zo werkt

- **Transcriberen en analyseren zijn gescheiden** omdat je de rubriek
  tientallen keren bijstelt en de transcriptie lang kost.
- **Het model schrijft de quotetekst niet zelf.** Het levert alleen
  tijdgrenzen; het script haalt de tekst letterlijk uit het transcript.
- **Het model rekent geen tijdcodes uit.** Het kopieert milliseconden; het
  script maakt daar tijdcodes en duren van.
- **De analyse-CLI draait in een lege map**, zodat projectcontext de uitslag
  niet beïnvloedt.
