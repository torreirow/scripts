# Spec Delta

## Purpose

Maakt van een transcript een samenvatting met de kernboodschap en de opbouw,
zodat latere analyses op de inhoud kunnen sturen in plaats van op losse
treffers.

## ADDED Requirements

### Requirement: Samenvatting uit het transcript

Het systeem SHALL uit een transcript een `samenvatting.md` maken met de
kernboodschap, de opbouw en de belangrijkste punten van de video.

#### Scenario: Video met duidelijke opbouw
- **WHEN** de gebruiker een werkmap met een transcript analyseert
- **THEN** bevat `samenvatting.md` een sectie kernboodschap en een sectie
  opbouw met de punten in de volgorde van de video

#### Scenario: Korte opname
- **WHEN** het transcript minder dan twintig segmenten bevat
- **THEN** maakt het systeem een beknopte samenvatting zonder verzonnen
  opbouw

### Requirement: Samenvatting is een eigen artefact

Het systeem SHALL de samenvatting als bestand bewaren en hergebruiken, zodat
een latere stap hem kan lezen zonder opnieuw te summariseren.

#### Scenario: Samenvatting bestaat al
- **WHEN** `samenvatting.md` al in de werkmap staat
- **THEN** slaat het systeem de summarisatie over en meldt dat

#### Scenario: Opnieuw samenvatten
- **WHEN** de gebruiker `--force` opgeeft
- **THEN** wordt `samenvatting.md` opnieuw gemaakt

### Requirement: Samenvatting schrijft niets bij mislukking

Het systeem SHALL een bestaande samenvatting niet vervangen wanneer de
analyse-backend faalt of lege uitvoer geeft.

#### Scenario: Backend faalt
- **WHEN** de analyse-backend een foutcode teruggeeft
- **THEN** blijft een bestaande `samenvatting.md` ongewijzigd en stopt het
  systeem met een melding

### Requirement: Metadata gaat mee als context

Het systeem SHALL titel, spreker en duur aan de samenvatting meegeven en in
de kop van het document opnemen wanneer ze bekend zijn.

#### Scenario: Spreker en titel opgegeven
- **WHEN** de gebruiker `--titel` en `--auteur` opgeeft
- **THEN** staan beide in de kop van `samenvatting.md` en wegen ze mee in de
  samenvatting
