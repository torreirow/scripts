# Tasks

## 1. Samenvatting

- [ ] 1.1 Schrijf `prompts/samenvatting.md` met een vaste uitvoervorm (`## Kernboodschap`, `## Opbouw`, `## Punten`), de eis dat niets verzonnen wordt en dat de opbouw naar tijdcodegebieden uit het transcript verwijst; verifieer met een handmatige run op een bestaand transcript dat de drie koppen aanwezig zijn.
- [ ] 1.2 Implementeer `vid-summarize.sh` met `--uit`, `--titel`, `--auteur`, `--backend`, `--model`, `--rubriek` en `--force`, inclusief werkmapbepaling en metadata; verifieer dat een run `samenvatting.md` schrijft en de kopregel de titel en auteur bevat.
- [ ] 1.3 Implementeer het overslaan van een bestaande samenvatting en het atomair schrijven met controle op niet-lege uitvoer en de kop `## Kernboodschap`; verifieer met een stub-backend die rommel teruggeeft dat een bestaand bestand ongewijzigd blijft.
- [ ] 1.4 Documenteer `vid-summarize.sh` in `USAGE.md` en verifieer dat het gedocumenteerde commando bestaat en `--help` geeft.

## 2. Quotes

- [ ] 2.1 Schrijf `prompts/quotes.md` met de samenvatting als sturende context, de eis dat elke quote bij een genoemd punt hoort, maximaal twintig quotes en de uitvoervorm (`## Quote N`, `TITEL:`, `WAAROM:`, `FRAGMENT: [[start-eind]]`); verifieer dat een run op een transcript plus samenvatting blokken oplevert die de renderer herkent.
- [ ] 2.2 Schrijf `lib/render-quotes.awk` die per quote de tijdcode, duur en letterlijke tekst uit de TSV toont, de zinnencontrole toepast, het maximum aan quotes afdwingt en een waarschuwing zet bij een quote buiten de duurgrenzen; verifieer met een klein transcript en een handgemaakte analyse dat tijdcode, duur en tekst kloppen.
- [ ] 2.3 Implementeer `vid-quotes.sh` met `--uit`, `--titel`, `--auteur`, `--rubriek`, `--backend`, `--model`, `--force` en de grenzen `VID_QUOTE_MIN`, `VID_QUOTE_MAX`, `VID_QUOTE_MAX_AANTAL`; verifieer dat een run `quotes.md` schrijft met niet meer dan twintig quotes en de gekozen grenzen toepast.
- [ ] 2.4 Laat `vid-quotes.sh` de samenvatting aanmaken wanneer die ontbreekt, en verifieer dat een werkmap met alleen `transcript.tsv` in één run zowel `samenvatting.md` als `quotes.md` oplevert.
- [ ] 2.5 Implementeer de controle vóór het schrijven en het atomair vervangen van `quotes.md`; verifieer met een stub-backend die rommel teruggeeft dat een bestaand document ongewijzigd blijft.
- [ ] 2.6 Documenteer `vid-quotes.sh`, de quote-grenzen en de samenhang met de samenvatting in `USAGE.md`; verifieer dat het gedocumenteerde commando bestaat en `--help` geeft.

## 3. Orchestrator

- [ ] 3.1 Breid `vid.sh` uit naar vier stappen (transcriberen, samenvatten, inspireren, quoten) met dezelfde werkmap; verifieer dat één run vanaf een mediabestand alle vier artefacten oplevert.
- [ ] 3.2 Voeg `--force-samenvatting` en `--force-quotes` toe naast de bestaande force-vlaggen en verifieer dat een tweede run alles overslaat en dat elke force-vlag alleen de eigen stap opnieuw draait.
- [ ] 3.3 Werk de `--help` van `vid.sh` bij en verifieer dat de genoemde stappen en vlaggen overeenkomen met het script.

## 4. Integratie en documentatie

- [ ] 4.1 Verifieer de volledige keten op een echt mediabestand met beide analyse-backends en vergelijk de structuur van `quotes.md`; leg vast dat alleen de gekozen quotes verschillen en niet het formaat.
- [ ] 4.2 Verifieer dat elke quote in `quotes.md` een `Waarom`-regel heeft die een punt uit `samenvatting.md` noemt; tel de quotes en controleer het maximum.
- [ ] 4.3 Verifieer de foutpaden: ontbrekend transcript, ontbrekende rubriek, geen backend en een backend die rommel teruggeeft; elk moet een begrijpelijke melding geven en geen half document achterlaten.
- [ ] 4.4 Werk `USAGE.md` bij met de vierstaps-pijplijn en de nieuwe omgevingsvariabelen, en verifieer dat elk gedocumenteerd commando `--help` geeft.

## Workflow follow-up

- Archiveer de change nadat de review en de integratiecheck zijn afgerond.
