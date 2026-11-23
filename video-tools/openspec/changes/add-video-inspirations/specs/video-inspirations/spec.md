# Spec Delta

## Purpose

Maakt van een lokaal mediabestand een inspirations-document: een transcript
plus een reeks samengestelde shorts met tijdcode, functie en letterlijke
quote, klaar om te monteren.

## ADDED Requirements

### Requirement: Transcriptie van een lokaal mediabestand

Het systeem SHALL elk mediabestand accepteren dat `ffmpeg` kan lezen en
daarvan een transcript maken met start- en eindtijd in milliseconden per
segment.

#### Scenario: Video als invoer
- **WHEN** de gebruiker een `.mp4`, `.mkv` of `.webm` bestand opgeeft
- **THEN** schrijft het systeem `transcript.tsv`, `transcript.txt`,
  `transcript.json`, `transcript.srt` en `transcript.vtt` in de werkmap

#### Scenario: Audio als invoer
- **WHEN** de gebruiker een `.m4a`, `.wav` of `.mp3` bestand opgeeft
- **THEN** verloopt de transcriptie identiek aan die van een videobestand

#### Scenario: Onleesbaar bestand
- **WHEN** `ffmpeg` het bestand niet kan openen
- **THEN** stopt het systeem met een foutmelding die het bestandspad noemt

### Requirement: Werkmappen per bronbestand

Het systeem SHALL per bronbestand één werkmap gebruiken en daar alle
artefacten in plaatsen, zodat twee video's met dezelfde naam elkaar niet
overschrijven.

#### Scenario: Standaard werkmap
- **WHEN** de gebruiker `interview.mp4` in `~/Videos` analyseert
- **THEN** staat de uitvoer in `~/Videos/interview/`

#### Scenario: Eigen werkmap
- **WHEN** de gebruiker `--uit /tmp/analyse` opgeeft
- **THEN** staat alle uitvoer in `/tmp/analyse`

### Requirement: Taalkeuze bij transcriptie

Het systeem SHALL de transcriptietaal kunnen vastzetten en SHALL zonder
opgave automatisch detecteren.

#### Scenario: Automatische detectie
- **WHEN** de gebruiker geen taal opgeeft
- **THEN** laat het systeem de taal door Whisper detecteren

#### Scenario: Vaste taal
- **WHEN** de gebruiker `--taal nl` opgeeft
- **THEN** transcribeert het systeem als Nederlands, ongeacht de detectie

### Requirement: Samengestelde shorts in het inspirations-document

Het systeem SHALL een `inspirations.md` opleveren met shorts die elk uit
meerdere fragmenten bestaan, in montagevolgorde, met per fragment een functie
uit Hook, Kernboodschap, Verdieping of Punchline.

#### Scenario: Short met meerdere fragmenten
- **WHEN** de analyse slaagt
- **THEN** bevat elke short een tabel met start, stop, duur, functie en
  fragmenttekst, in de volgorde waarin gemonteerd moet worden

#### Scenario: Montage wijkt af van de bronvolgorde
- **WHEN** een fragment later in de short eerder in de bron voorkomt
- **THEN** vermeldt het document boven de tabel dat de montagevolgorde
  afwijkt van de bronvolgorde

### Requirement: Letterlijke quote en berekende tijdcodes

Het systeem SHALL de quote tekst letterlijk uit het transcript halen en SHALL
tijdcodes, duur en functie zelf berekenen; het taalmodel levert uitsluitend
tijdgrenzen.

#### Scenario: Quote komt uit het transcript
- **WHEN** het model een fragment met grenzen `[[724320-736880]]` aanwijst
- **THEN** komt de tekst in het document woordelijk uit de transcriptsegmenten
  binnen dat bereik, zonder herschrijven door het model

#### Scenario: Tijdcode en duur
- **WHEN** een fragment de grenzen 724320 en 736880 ms heeft
- **THEN** toont het document `00:12:04.320` als start en `12,6 s` als duur

### Requirement: Duurgrenzen met waarschuwing

Het systeem SHALL een instelbare onder- en bovengrens voor de totale shortduur
hanteren en SHALL een short buiten die grenzen opnemen met een zichtbare
waarschuwing.

#### Scenario: Short te lang
- **WHEN** een short langer is dan de bovengrens
- **THEN** blijft de short in het document staan met een waarschuwing dat hij
  te lang is

#### Scenario: Eigen grenzen
- **WHEN** de gebruiker de grenzen op 20 en 60 seconden zet
- **THEN** gebruikt het systeem die grenzen bij de beoordeling en de
  waarschuwing

### Requirement: Keuze van analyse-backend

Het systeem SHALL de analyse kunnen uitvoeren met de Claude Code CLI of de
OpenCode CLI, SHALL een expliciete keuze respecteren en SHALL zonder keuze
automatisch een beschikbare backend kiezen.

#### Scenario: Expliciete backend
- **WHEN** de gebruiker `--backend opencode` opgeeft terwijl ook `claude`
  geïnstalleerd is
- **THEN** verloopt de analyse via `opencode`

#### Scenario: Automatische keuze
- **WHEN** de gebruiker geen backend opgeeft en alleen `opencode` is
  geïnstalleerd
- **THEN** verloopt de analyse via `opencode` zonder foutmelding

#### Scenario: Geen backend beschikbaar
- **WHEN** geen van beide CLI's geïnstalleerd is
- **THEN** stopt het systeem met een melding die beide opties noemt en de
  transcriptie ongemoeid laat

### Requirement: Modelkeuze per backend

Het systeem SHALL één modelinstelling doorgeven aan de gekozen backend, zonder
de waarde te herschrijven.

#### Scenario: Model met providerprefix
- **WHEN** de gebruiker `--model opencode-go/deepseek-v4.1-flash` opgeeft bij
  backend `opencode`
- **THEN** gaat die waarde ongewijzigd mee naar de CLI

#### Scenario: Geen model opgegeven bij opencode
- **WHEN** de gebruiker de backend `opencode` kiest zonder model
- **THEN** gebruikt het systeem een model van de provider `opencode-go`

#### Scenario: Geen model opgegeven bij claude
- **WHEN** de gebruiker de backend `claude` kiest zonder model
- **THEN** gebruikt de CLI zijn eigen standaardmodel

#### Scenario: Eigen standaardmodel voor opencode
- **WHEN** de gebruiker `VID_OPENCODE_MODEL` zet
- **THEN** gebruikt het systeem die waarde zodra de backend `opencode` is en er
  geen model is opgegeven

### Requirement: Analyse draait zonder projectcontext

Het systeem SHALL de analyse-backend zodanig aanroepen dat projectbestanden en
projectinstructies uit de huidige map de uitvoer niet beïnvloeden.

#### Scenario: OpenCode in een projectmap
- **WHEN** de gebruiker het script vanuit een repository met `AGENTS.md` draait
- **THEN** bevat de analyse geen regels uit dat bestand

### Requirement: Hervatbaar zonder verlies

Het systeem SHALL een bestaand transcript hergebruiken en SHALL een bestaand
`inspirations.md` niet overschrijven wanneer de analyse mislukt of geen
herkenbare shorts oplevert.

#### Scenario: Transcript bestaat al
- **WHEN** de werkmap al een `transcript.tsv` bevat
- **THEN** slaat het systeem de transcriptie over en gaat het door naar de
  analyse

#### Scenario: Analyse levert niets bruikbaars
- **WHEN** de backend geen shortblokken teruggeeft
- **THEN** blijft een bestaand `inspirations.md` ongewijzigd en meldt het
  systeem de fout
