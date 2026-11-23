# Spec Delta

## Purpose

Levert losse, zelfstandig leesbare uitspraken met tijdcode, geselecteerd op
de kern van de video, zodat ze als quote-kaart of caption op social media
kunnen dienen.

## ADDED Requirements

### Requirement: Quotes rusten op de samenvatting

Het systeem SHALL de samenvatting en het transcript samen aan de analyse
geven, en SHALL elke quote laten aansluiten op een punt uit de samenvatting.

#### Scenario: Samenvatting aanwezig
- **WHEN** de gebruiker `vid-quotes.sh` draait op een werkmap met
  `samenvatting.md` en `transcript.tsv`
- **THEN** bevat elke quote in `quotes.md` een regel waarom die quote bij de
  kernboodschap of een genoemd punt hoort

#### Scenario: Samenvatting ontbreekt
- **WHEN** `samenvatting.md` niet bestaat
- **THEN** maakt het systeem die eerst aan en gaat daarna verder met de
  quotes

### Requirement: Maximaal twintig quotes

Het systeem SHALL hoogstens twintig quotes opleveren en SHALL er minder
leveren wanneer de bron er niet meer draagt.

#### Scenario: Rijke bron
- **WHEN** de analyse twintig of meer kandidaten oplevert
- **THEN** bevat `quotes.md` precies twintig quotes

#### Scenario: Schrale bron
- **WHEN** de analyse vijf bruikbare kandidaten oplevert
- **THEN** bevat `quotes.md` vijf quotes en geen opvulling

### Requirement: Duur per quote

Het systeem SHALL per quote een instelbare onder- en bovengrens hanteren en
een quote buiten die grenzen opnemen met een zichtbare waarschuwing.

#### Scenario: Quote te lang
- **WHEN** een quote langer is dan de bovengrens
- **THEN** blijft hij in het document staan met een waarschuwing dat hij te
  lang is

#### Scenario: Eigen grenzen
- **WHEN** de gebruiker de grenzen op 5 en 20 seconden zet
- **THEN** gebruikt het systeem die grenzen bij de beoordeling en de
  waarschuwing

### Requirement: Tijdcode, duur en letterlijke tekst

Het systeem SHALL per quote de starttijd, de duur en de letterlijke tekst
tonen; het taalmodel levert uitsluitend de tijdgrenzen.

#### Scenario: Quote uit het transcript
- **WHEN** het model een fragment met grenzen `[[724320-736880]]` aanwijst
- **THEN** komt de tekst woordelijk uit de transcriptsegmenten binnen dat
  bereik en toont het document `00:12:04.320` en `12,6 s`

#### Scenario: Volgorde
- **WHEN** de quotes zijn geselecteerd
- **THEN** staan ze op sterkte en niet op chronologie

### Requirement: Quotes zijn zelfstandig leesbaar

Het systeem SHALL alleen uitspraken accepteren die zonder de rest van de
video te begrijpen zijn en die op een zinsgrens beginnen en eindigen.

#### Scenario: Halve zin
- **WHEN** een gekozen fragment op een komma begint of eindigt
- **THEN** markeert het document die quote als na te lopen

#### Scenario: Verwijzing zonder antecedent
- **WHEN** een quote opent met "Hij", "Dat" of een voegwoord
- **THEN** markeert het document die quote als na te lopen
