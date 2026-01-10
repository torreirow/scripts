# AI Prompts
## Hugo recepten
```
Zet het volgende recept om naar Hugo Markdown met YAML frontmatter.

Houd exact dit formaat aan:
- YAML frontmatter tussen --- en ---
- Velden: title, servings, ingredients, instructions
- ingredients en instructions zijn YAML-lijsten
- Gebruik metrische eenheden (g, ml), maar behoud el / tl / tbsp / tsp waar logisch
- Gebruik Unicode breuktekens (½, ¼, ¾) in plaats van 1/2, 1/4, 3/4
- Gebruik Nederlands
- Geen extra tekst buiten het YAML-blok

Voorbeeld van het gewenste formaat:

---
title: "Receptnaam"
servings: 4
ingredients:
  - 1 el olijfolie
  - 500 g kipfilet
instructions:
  - Verhit de olie in een pan.
  - Bak de kip goudbruin.
---

Hier is het recept dat je moet omzetten:
<PLAK HIER HET RECEPT>
```

## Hugo recepten #2

```
Zet het onderstaande recept om naar Hugo Markdown met YAML frontmatter.

Houd EXACT dit formaat en deze regels aan:

FRONTMATTER
- Begin en eindig met ---
- Gebruik deze velden (in deze volgorde):
  title
  ref (snake_case, gebaseerd op title)
  image (true)
  category (bijv. Dinner, Lunch, Dessert)
  tags (YAML-lijst, logisch afgeleid)
  time (bijv. "15m prep, 5h30 cooking")
  quantity (bijv. "6 people")
  ingredients (gestructureerd, zie hieronder)
  side_image (./images/<ref>.png)

INGREDIENTS STRUCTUUR
- ingredients is een YAML-lijst van objecten
- Elk object heeft EXACT deze keys:
  - name
  - unit
  - amount
- amount is altijd een string (tussen quotes)
- Gebruik metrische eenheden (g, ml)
- Sta el / tl / tbsp / tsp toe
- Gebruik Unicode breuktekens (½, ¼, ¾)
- Gebruik enkelvoudige productnamen

INSTRUCTIONS
- Instructies komen NA de frontmatter
- Gebruik een YAML-lijst met streepjes
- Korte, duidelijke zinnen
- Gebruik ⚠️ of ❗ bij hitte / oven / slowcooker / magnetron
- Gebruik Nederlands

OVERIG
- Geen uitleg, geen commentaar
- Geen Markdown headers buiten YAML
- Alleen geldige Hugo Markdown output

VOORBEELD (structuur, niet inhoud):

---
title: Voorbeeld Recept
ref: voorbeeld_recept
image: true
category: Dinner
tags:
  - Example
time: 30m prep, 45m cooking
quantity: 4 people
ingredients:
  - name: Ui
    unit: piece
    amount: "1"
side_image: ./images/voorbeeld_recept.png
---
  - Stap één.
  - Stap twee.

HIER IS HET RECEPT DAT JE MOET OMZETTEN:
<PLAK HIER DE RUWE RECEPTTEKST>
```

