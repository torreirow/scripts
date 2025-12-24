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

