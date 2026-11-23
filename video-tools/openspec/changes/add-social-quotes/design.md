# Design

## Context

Zie `proposal.md` — Why. De bestaande pijplijn (`vid-transcribe.sh`,
`vid-inspire.sh`, `lib/common.sh`) levert al een transcript en een
inspirations-document. Dit ontwerp bouwt daarop voort en hergebruikt de
backend-abstractie (`analyseer`) en de werkmapconventie uit
`add-video-inspirations`.

Wat de vorm bepaalt:

- Een quote moet de kern raken, niet toevallig mooi klinken. Daarom is er een
  samenvatting nodig die vóór de selectie vastligt.
- Dezelfde samenvatting is bruikbaar voor andere doeleinden (samenvatting in
  een nieuwsbrief, ondertiteling, een blog). Hem weggooien na de quote-run
  zou zonde zijn.
- De renderer kan geen tekst verzinnen: het model levert grenzen, het script
  haalt de woorden uit de TSV. Dat blijft ongewijzigd.

## Goals / Non-Goals

**Goals:**

- Samenvatting en quotes als twee losse, inspecteerbare artefacten.
- De quote-selectie is aantoonbaar gegrond: elke quote verwijst naar een
  punt uit de samenvatting.
- Bestaande scripts en vlaggen blijven werken.

**Non-Goals:**

- De inspirations-pijplijn aanpassen of de rubriek daarvan hergebruiken.
- Beeld maken (quote-kaarten), publiceren, of vertalen.
- De samenvatting als vervanging van `inspirations.md` gebruiken.

## Decisions

### Samenvatting als eigen artefact en eigen script

```
vid-summarize.sh <bestand|werkmap>  ->  samenvatting.md
vid-quotes.sh    <bestand|werkmap>  ->  quotes.md   (leest samenvatting.md + transcript.tsv)
```

Twee modelcallen in plaats van één die beide doet. Redenen:

- De samenvatting is te lezen en te corrigeren voordat je quotes laat kiezen.
- Een tweede quote-run om de rubriek bij te schaven mag de samenvatting niet
  opnieuw laten maken.
- De samenvatting is zelf een bruikbaar product.

*Alternatief:* één call die eerst samenvat en dan citeert. Verworpen — dan is
de samenvatting onzichtbaar, niet te corrigeren en niet te hergebruiken.

`vid-quotes.sh` maakt de samenvatting zelf als die ontbreekt, zodat één
commando blijft werken. Bestaat hij al, dan wordt hij hergebruikt.

### De samenvatting is sturend, niet decoratief

De samenvatting heeft een vaste vorm:

```
## Kernboodschap
## Opbouw
## Punten
```

De quote-prompt krijgt die drie secties letterlijk mee, plus het transcript.
De opdracht is expliciet: elke quote hoort bij de kernboodschap of bij een
van de genoemde punten, en de `WAAROM`-regel noemt welk punt. Zo is achteraf
te controleren of de selectie op de inhoud rust en niet op losse treffers.

*Alternatief:* alleen de samenvatting als input en het transcript weglaten.
Verworpen — dan kan het model geen grenzen in milliseconden aanwijzen.

### Eigen renderer voor quotes

`lib/render-quotes.awk`, geen uitbreiding van `render-inspirations.awk`. De
uitvoer verschilt te veel: geen tabel, geen rollen, geen montagevolgorde,
maar een blokquote per quote met tijdcode en duur. De controle op halve
zinnen en verwijzingen zonder antecedent wordt overgenomen; dat is deels
duplicatie, maar awk kent geen include en één renderer met twee modi wordt
moeilijker te lezen dan twee kleine.

Uitvoer per quote:

```
## Quote 1 — <titel>
**00:12:04.320 - 00:12:16.880**  ·  12,6 s   [⚠ ...]

> <letterlijke tekst>

**Waarom:** <welk punt uit de samenvatting>
```

### Grenzen en aantal

| Variabele | Standaard | Betekenis |
|---|---|---|
| `VID_QUOTE_MAX_AANTAL` | 20 | harde bovengrens op het aantal quotes |
| `VID_QUOTE_MIN` | 5 | ondergrens in seconden |
| `VID_QUOTE_MAX` | 30 | bovengrens in seconden |

Het maximum wordt ook in de prompt genoemd én in de renderer afgedwongen. Een
model dat er 23 teruggeeft levert er dan 20, in de opgegeven volgorde (sterkte).

*Alternatief:* alleen in de prompt afdwingen. Verworpen — promptinstructies
worden niet altijd gevolgd en dit is een harde eis.

### `vid.sh` wordt vier stappen

```
1. transcriberen    transcript.*
2. samenvatten      samenvatting.md
3. inspireren       inspirations.md
4. quoten           quotes.md
```

Elke stap slaat over wat er ligt; `--force-transcribe`, `--force-samenvatting`,
`--force-analyse` en `--force-quotes` werken per stap. `--force-all` doet
alles opnieuw.

*Alternatief:* de nieuwe stappen achter een vlag zetten. Verworpen — dan
produceert hetzelfde commando op twee machines andere uitvoer, en de
samenvatting is juist de context die de quotes nodig hebben.

### Foutgedrag

Beide nieuwe scripts schrijven via een tijdelijk bestand en vervangen pas na
een controle: niet-lege uitvoer en minstens één herkenbaar blok
(`## Kernboodschap` respectievelijk `## Quote`). Mislukt de backend, dan
blijft het bestaande artefact staan.

## Risks / Trade-offs

| Risico | Mitigatie |
|---|---|
| De samenvatting bevat verzonnen feiten | prompt verbiedt aanvullen; de opbouw moet naar tijdcodegebieden verwijzen die in het transcript bestaan |
| Quotes drijven af van de samenvatting | `WAAROM` moet een genoemd punt aanwijzen; de renderer toont die regel verplicht |
| Twee modelcallen maken de run duurder | de samenvatting is herbruikbaar en wordt overgeslagen zodra hij bestaat |
| Een lange bron geeft een afgekapte samenvatting | dezelfde `--van`/`--tot`-route als bij transcriptie; de TSV blijft de magerste vorm |
| De quote-renderer dupliceert de zinscontrole | bewust geaccepteerd; twee kleine awk-bestanden zijn eenvoudiger dan één met vertakkingen |

## Migration Plan

Nieuwe scripts en artefacten; bestaande werkmappen blijven geldig. Een map
met alleen `transcript.tsv` werkt direct met `vid-quotes.sh`, dat de
samenvatting dan aanmaakt.

## Open Questions

Geen.
