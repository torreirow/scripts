# Opdracht

Je krijgt hierboven de metadata van een mediabestand en hieronder het
volledige transcript. Stel daaruit korte video's samen: geen uitsnede van één
passage, maar een **opgebouwd geheel** uit fragmenten die verspreid door de
bron liggen.

Je levert alleen de grenzen van die fragmenten en hun rol. De tekst hoef je
niet over te schrijven: een script haalt die letterlijk uit het transcript.
Schrijf nooit zelf quotetekst uit.

## Het transcript

Tabgescheiden, drie kolommen:

    start	end	text

`start` en `end` zijn milliseconden vanaf het begin van de opname. Neem die
getallen letterlijk over; reken niets om en verzin geen tussenwaarden.

Het transcript komt uit automatische spraakherkenning en kan verhaspelde
woorden bevatten. Kies geen fragment waarvan de tekst zo rommelig is dat een
kijker hem niet zou volgen.

## Wat een fragment is

Dit is de belangrijkste regel van deze opdracht. Een fragment is geen
tijdvak, het is een **afgeronde uitspraak**.

Een bruikbaar fragment:

- **begint bij het begin van een zin en eindigt bij het einde van een zin.**
  Nooit midden in een zin, nooit op een komma.
- **is te begrijpen zonder de rest te kennen.** Geen "hij", "het", "dat",
  "die" waarvan de verwijzing buiten het fragment ligt. Geen opening met
  "En", "Want", "Maar", "Dus", "Daarom" of "Dan".
- **beweert iets.** De vorm die je zoekt is "X is Y", "X is niet Y maar Z",
  "wij doen X omdat Y". Een vraag, een aanloop of een aankondiging is geen
  bewering.
- **zou als los citaat op een kaart kunnen staan** en dan nog steeds kloppen.

Laat daarom liggen:

| Soort | Voorbeeld |
|---------------------|----------------------------------------------------|
| Opbouwvragen | "Waarom gebeurde dat? Waarom moest dat zo?" |
| Aankondiging | "Ik wil het aan het begin eigenlijk zo zeggen." |
| Commentaar op de opname | "Daar ligt de bodem van alles wat ik zo wil zeggen." |
| Verwijzing naar het moment | "zoals ik net al zei", "straks", "vandaag" |
| Halve zinnen | alles wat op een komma begint of eindigt |

Vulwoorden als "eigenlijk", "een soort van", "min of meer" en "gewoon" zijn
een teken dat de spreker nog aan het zoeken is. Een passage die daarvan aan
elkaar hangt is zelden een goed fragment; kies dan de zin verderop waarin hij
het wél scherp zegt.

Er zijn genoeg scherp geformuleerde zinnen. Neem er geen met een rafelrand
omdat hij toevallig in het goede tijdvak valt.

## Waar je op let

Je zoekt uitspraken die ook buiten hun oorspronkelijke context overeind
blijven. Wat daarbij gewicht heeft:

- **Een concrete bewering** — niet een gevoel of een algemeenheid, maar iets
  wat je kunt bevestigen of betwisten
- **Contrast of omkering** — "niet X maar Y" is bijna altijd sterker dan een
  opsomming
- **Een beeld dat blijft hangen** — een vergelijking, een scène, een getal
- **Iets op het spel** — waarom dit ertoe doet, voor de kijker
- **Toepassing** — wat dit betekent voor wie luistert, in het gewone leven

Wat je laat liggen: reclame voor de zender, mededelingen, aankondigingen van
wat komen gaat, en uitweidingen die alleen op die dag betekenis hadden.

Je legt de bron uit, je beoordeelt hem niet. Geen kritiek op de spreker, geen
correcties, geen "hij had beter kunnen zeggen".

## De opbouw van een short

Elk fragment krijgt een rol. Gebruik uitsluitend deze vier:

| Rol | Wat het doet |
|---------------|---------------------------------------------------------|
| Hook | opent met een bewering die de kijker vasthoudt |
| Kernboodschap | de stelling die de spreker **bevestigt**, kort en kaal |
| Verdieping | geeft de grond onder die stelling |
| Punchline | sluit af met de zin die blijft hangen |

**Let op bij Kernboodschap.** Een spreker zet vaak eerst neer wat iets
*niet* is voordat hij zegt wat het wel is. Neem als kernboodschap altijd de
kant die hij **bevestigt**, nooit de kant die hij weerlegt. Een fragment dat
losgeknipt de verkeerde helft van zo'n tegenstelling bevat, keert de
boodschap om.

Een short heeft minstens een **Hook** en een **Kernboodschap**. Verdieping en
Punchline zijn sterk aanbevolen maar niet verplicht.

Hook, Kernboodschap en Punchline komen **hooguit één keer** voor: één opening,
één stelling, één slot. **Verdieping mag je zo vaak gebruiken als de opbouw
vraagt.** Een short met vier verdiepingsfragmenten is prima zolang elk
fragment de redenering een stap verder brengt en er geen herhaling in zit.

**De montagevolgorde is niet de volgorde van de bron.** Een kernboodschap die
pas op 1:22 valt mag als tweede fragment komen, na een hook van 1:02. Dat is
juist de bedoeling: je bouwt een betoog uit onderdelen die in de bron ver uit
elkaar liggen.

Zet de `FRAGMENT`-regels in de volgorde waarin ze gemonteerd moeten worden.

## Lengte

Een short duurt **maximaal ongeveer 90 seconden**. Daaronder bepaalt de
opbouw de lengte, niet een quotum: stopt het betoog na veertig seconden,
dan is het klaar.

Het aantal fragmenten is vrij. Twee kan, acht kan ook, zolang de volgorde
een logische opbouw vormt en geen opsomming wordt.

Richtlengtes per rol — dit is waar de ritmiek in zit:

| Rol | Richtlengte | Waarom |
|---------------|-------------|-------------------------------------------|
| Hook | 15 – 35 s | mag ademen, moet de situatie neerzetten |
| Kernboodschap | 5 – 15 s | kort en kaal, dat is de kracht ervan |
| Verdieping | 15 – 40 s | heeft ruimte nodig om te onderbouwen |
| Punchline | 5 – 20 s | landt het, meer niet |

Een hook van tien seconden is meestal te haastig; een kernboodschap van
dertig seconden is meestal geen kernboodschap meer.

## De shorts onderling

Lever er zoveel als de bron er draagt, van sterkste naar zwakste. Meestal
zijn dat er vier tot acht; lever er minder als de bron niet meer hergeeft en
meer als er meer in zit.

Ze moeten wel van elkaar verschillen: niet twee varianten op dezelfde
stelling. Een fragment mag in hooguit één short voorkomen.

## Uitvoer

Geen inleiding, geen afsluiting, geen uitleg eromheen. Begin direct met
`## Short 1`. Voor elke short precies dit blok:

    ## Short 1
    TITEL: <titelsuggestie>
    WAAROM: <één zin: wat deze short doet>
    FRAGMENT: [[<start>-<eind>]] | Hook
    FRAGMENT: [[<start>-<eind>]] | Kernboodschap
    FRAGMENT: [[<start>-<eind>]] | Verdieping
    FRAGMENT: [[<start>-<eind>]] | Punchline

### De titel

De kern van de short, kort en in de woorden van de spreker, gevolgd door de
naam van de spreker als die in de metadata staat. Verzin nooit een naam.

### De waarom-regel

Eén zin voor iemand die de bron niet kent en moet kiezen welke short hij
gaat monteren. Zeg wat de short doet, niet dat hij mooi is.
