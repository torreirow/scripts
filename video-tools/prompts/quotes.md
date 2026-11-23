# Opdracht

Je krijgt hierboven de metadata van een mediabestand, daarna de samenvatting
en daaronder het volledige transcript. Kies uit dat transcript de uitspraken
die zich lenen voor een quote-kaart of caption op social media.

Je levert alleen de grenzen van die uitspraken. De tekst hoef je niet over te
schrijven: een script haalt die letterlijk uit het transcript. Schrijf nooit
zelf quotetekst uit.

## De samenvatting is sturend

De samenvatting hierboven noemt de kernboodschap en de punten die de opname
draagt. Elke quote die je kiest, moet bij een van die punten horen. Een quote
die mooi klinkt maar nergens in de samenvatting terugkomt, is geen goede
quote: hij vertegenwoordigt de video niet.

Noem in de `WAAROM`-regel welk punt uit de samenvatting de quote draagt. Is er
geen punt dat past, kies dan een andere quote.

## Het transcript

Tabgescheiden, drie kolommen:

    start	end	text

`start` en `end` zijn milliseconden vanaf het begin van de opname. Neem die
getallen letterlijk over; reken niets om en verzin geen tussenwaarden.

## Wat een quote is

Een quote is geen tijdvak, het is een **afgeronde uitspraak** die op een
kaart kan staan.

Een bruikbare quote:

- **begint bij het begin van een zin en eindigt bij het einde van een zin.**
  Nooit midden in een zin, nooit op een komma.
- **is te begrijpen zonder de video te kennen.** Geen "hij", "het", "dat",
  "die" waarvan de verwijzing buiten het fragment ligt. Geen opening met
  "En", "Want", "Maar", "Dus", "Daarom" of "Dan".
- **beweert iets.** "X is Y", "X is niet Y maar Z", "wij doen X omdat Y". Een
  vraag, een aanloop of een aankondiging is geen quote.
- **is kort.** Tussen de 5 en 30 seconden. Een langere passage is meestal
  geen quote meer maar een alinea.
- **heeft geen uitleg van buitenaf nodig.** Geen "zoals ik net zei", geen
  verwijzing naar de dag, de dienst of het publiek.

Laat liggen: opbouwvragen, aankondigingen, commentaar op de opname,
opsommingen zonder punt, en alles wat pas betekenis krijgt met de zin
eromheen.

## Aantal en volgorde

Lever **hoogstens twintig** quotes. Minder mag en is beter dan opvullen: als
er tien sterke uitspraken in zitten, lever er dan tien.

Zet ze op sterkte, niet in de volgorde van de opname. De bovenste moet de
quote zijn die je zou plaatsen als je er maar één mocht kiezen.

Ze moeten van elkaar verschillen: geen twee varianten op dezelfde uitspraak,
en geen quotes die elkaar in tijd overlappen. Een fragment komt in hooguit
één quote voor.

## Uitvoer

Geen inleiding, geen afsluiting, geen uitleg eromheen. Begin direct met
`## Quote 1`. Voor elke quote precies dit blok:

    ## Quote 1
    TITEL: <korte titel, in de woorden van de spreker>
    WAAROM: <welk punt uit de samenvatting deze quote draagt>
    FRAGMENT: [[<start>-<eind>]]

### De titel

De kern van de quote in enkele woorden, gevolgd door de naam van de spreker
als die in de metadata staat. Verzin nooit een naam.

### De waarom-regel

Eén zin die het verband met de samenvatting legt. Niet "dit is een mooie
zin", maar "dit is het punt dat genade een geschenk is en geen beloning".
