# Scheme2ICS

**Scheme2ICS** is een Python-script voor de **Dindoa korfbal vereniging** dat het wedstrijdschema omzet naar een **calendar/ICS-formaat**. Het script verwerkt automatisch de HTML, zet tabellen om naar CSV en genereert een ICS-bestand met alle wedstrijden van het opgegeven team.

---

## Bestandsoverzicht

- `scheme2ics.py` — Hoofdscript dat de workflow uitvoert:
  1. Parseert `index.html` en splitst het schema per `<h3>` + tabel.
  2. Zet de tabellen om naar CSV-bestanden.
  3. Genereert een ICS-bestand voor een opgegeven team.
- Tijdelijke HTML- en CSV-bestanden worden opgeslagen in een **tijdelijke directory** en na afloop verwijderd.
- De ICS wordt altijd in de huidige directory weggeschreven.

---

## Vereisten / Prerequisites

- Python 3.8 of hoger
- Python-pakketten:
  ```bash
  pip install beautifulsoup4 ics
  ```
- Download het competitieschema van Dindoa:
  ```bash
  wget https://dindoa.nl/ws/competitie-programma/ -O index.html
  ```
  Het bestand moet als `index.html` in dezelfde map als het script staan.

---

## Gebruik

1. Zorg dat het competitieschema beschikbaar is als `index.html` in dezelfde map als het script.
2. Run het script met de teamnaam als argument:

```bash
python scheme2ics.py "Dindoa J3"
```

3. Het script genereert:
   - Tijdelijke HTML- en CSV-bestanden in een tijdelijke directory.
   - Een ICS-bestand in de huidige directory, bijvoorbeeld: `Dindoa_J3.ics`.

---

## Werking

1. **HTML-parsing:**  
   Het script zoekt de `<div class="page-content table-responsive">` in `index.html` en splitst deze in blokken per `<h3>` + tabel.

2. **CSV-generatie:**  
   Elk blok wordt omgezet naar CSV met de bestandsnaam `blok-YYYY-MM-DD.csv` (datum uit `<h3>`).

3. **ICS-generatie:**  
   Voor het opgegeven team worden alle wedstrijden gevonden in de CSV’s en toegevoegd aan een ICS-agenda:
   - **Titel:** `Team,Tegenstander`
   - **Datum & tijd:** uit CSV
   - **Locatie:** uit CSV
   - **Duur:** standaard 1 uur

---

## Opmerkingen

- De teamnaam wordt case-insensitive gezocht in **zowel Team als Tegenstander**.
- De tijdelijke bestanden worden automatisch verwijderd na afloop van het script.
- Het huidige jaar wordt automatisch toegevoegd aan de datum uit de HTML.
- Dit script is specifiek ontwikkeld voor het Dindoa korfbal vereniging wedstrijdschema.

---

## License

MIT License

