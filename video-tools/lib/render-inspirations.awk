#!/usr/bin/env awk -f
#
# Bouwt inspirations.md uit het transcript en de blokuitvoer van het model.
#
#   awk -f lib/render-inspirations.awk -v VIDEO_ID=... transcript.tsv model.txt
#
# Het model levert tijdgrenzen en een rol per fragment. De tekst komt hier uit
# het transcript, zodat hij per definitie letterlijk is. De fragmenten blijven
# in de volgorde waarin het model ze zette: dat is de montagevolgorde, niet de
# volgorde in de bron.

BEGIN {
    FS = "\t"
    if (MIN_S == "") MIN_S = 30
    if (MAX_S == "") MAX_S = 90
    nseg = 0; nshort = 0; kort = 0
}

function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }

function tc(ms,   t, h, m, s) {
    t = int(ms/1000); h = int(t/3600); m = int((t%3600)/60); s = t%60
    return sprintf("%02d:%02d:%02d.%03d", h, m, s, ms%1000)
}

function mmss(ms,   t, h, m, s) {
    t = int(ms/1000); h = int(t/3600); m = int((t%3600)/60); s = t%60
    if (h > 0) return sprintf("%d:%02d:%02d", h, m, s)
    return sprintf("%d:%02d", m, s)
}

function komma(s) { gsub(/\./, ",", s); return s }

# Controleert of een fragment een afgeronde uitspraak is. Het model kiest
# tijdvakken; segmentgrenzen vallen lang niet altijd op zinsgrenzen, en een
# fragment dat op een komma begint of eindigt is geen citaat.
# Losse verwijzingen ("Hij", "En") tellen alleen zwaar bij het eerste
# fragment: daarna mag een fragment voortbouwen op wat ervoor kwam.
function controleer(tekst, eerste,   klachten) {
    klachten = ""
    if (tekst !~ /^[A-ZÀ-ÞĲ]/)
        klachten = klachten "begint midden in een zin; "
    if (tekst !~ /[.!?]["\x27)]?$/)
        klachten = klachten "eindigt midden in een zin; "
    if (eerste) {
        if (tekst ~ /^(En|Want|Maar|Dus|Daarom|Dan|Toen|Ook|Want) /)
            klachten = klachten "opent met een voegwoord; "
        if (tekst ~ /^(Hij|Het|Die|Dat|Deze|Dit|Ze|Zij|Hem|Hun) /)
            klachten = klachten "opent met een verwijzing zonder antecedent; "
        if (tekst ~ /\?[[:space:]]*$/ || tekst ~ /^Waarom /)
            klachten = klachten "is een opbouwvraag, geen bewering; "
    }
    sub(/; $/, "", klachten)
    return klachten
}
function dur(ms)  { return komma(sprintf("%.1f s", ms/1000)) }

function link(ms) {
    if (VIDEO_ID == "") return tc(ms)
    return sprintf("[%s](https://youtu.be/%s?t=%d)", tc(ms), VIDEO_ID, int(ms/1000))
}

# Klapt de segmenten binnen [a,b) samen en zet de grenzen op echte
# segmentgrenzen, zodat tekst en tijd altijd bij elkaar horen.
function bouw(a, b,   i, eerste, laatste, tekst) {
    eerste = 0; tekst = ""
    for (i = 1; i <= nseg; i++)
        if (seg_start[i] >= a && seg_start[i] < b) {
            if (eerste == 0) eerste = i
            laatste = i
            tekst = (tekst == "") ? seg_text[i] : tekst " " seg_text[i]
        }
    if (eerste == 0) return 0
    f_start = seg_start[eerste]; f_end = seg_end[laatste]; f_text = trim(tekst)
    return 1
}

function schrijf(   i, ok, totaal, waarschuwing, secs, chrono) {
    if (kort == 0 || nfrag == 0) return

    ok = 0; totaal = 0
    for (i = 1; i <= nfrag; i++)
        if (bouw(frag_a[i], frag_b[i])) {
            ok++
            r_start[ok] = f_start; r_end[ok] = f_end
            r_text[ok] = f_text;   r_rol[ok] = frag_rol[i]
            totaal += f_end - f_start
        }

    if (ok == 0) {
        printf("\n## Short %d — %s\n\n> Geen transcriptsegmenten gevonden bij de opgegeven tijden. Overslaan.\n", kort, titel)
        return
    }

    nshort++
    secs = totaal/1000
    waarschuwing = ""
    if (secs > MAX_S) waarschuwing = sprintf(" ⚠ te lang (grens %d s)", MAX_S)
    else if (secs < MIN_S) waarschuwing = sprintf(" ⚠ te kort (ondergrens %d s)", MIN_S)

    # Loopt de montage tegen de chronologie in? Dat is toegestaan en zelfs de
    # bedoeling, maar de editor moet het weten.
    chrono = 1
    for (i = 2; i <= ok; i++) if (r_start[i] < r_start[i-1]) chrono = 0

    printf("\n## Short %d — %s\n\n", kort, titel)
    printf("**Totaal: %s**%s  ·  %d fragmenten\n\n", dur(totaal), waarschuwing, ok)
    if (!chrono)
        printf("> **Montagevolgorde wijkt af van de bron.** De fragmenten hieronder staan in de volgorde waarin ze gemonteerd moeten worden, niet in de volgorde waarin ze zijn uitgesproken.\n\n")

    printf("| # | Start | Stop | Duur | Functie | Fragment |\n")
    printf("|---|-------|------|------|---------|----------|\n")
    nklacht = 0
    for (i = 1; i <= ok; i++) {
        klacht[i] = controleer(r_text[i], i == 1)
        if (klacht[i] != "") nklacht++
        printf("| %d%s | %s | %s | %s | %s | %s |\n",
               i, (klacht[i] != "" ? " ⚠" : ""),
               link(r_start[i]), tc(r_end[i]), dur(r_end[i]-r_start[i]),
               r_rol[i], r_text[i])
    }

    if (nklacht > 0) {
        printf("\n**Nalopen voor je knipt:**\n\n")
        for (i = 1; i <= ok; i++)
            if (klacht[i] != "")
                printf("- Fragment %d — %s\n", i, klacht[i])
    }

    printf("\n**Waarom:** %s\n", waarom)
}

FNR == NR {
    if (FNR == 1) next
    if ($1 !~ /^[0-9]+$/) next
    nseg++
    seg_start[nseg] = $1+0; seg_end[nseg] = $2+0; seg_text[nseg] = trim($3)
    next
}

/^##[[:space:]]*Short/ {
    schrijf(); kort++; titel = ""; waarom = ""; nfrag = 0; next
}
/^[[:space:]]*TITEL:/  { titel  = trim(substr($0, index($0,":")+1)); next }
/^[[:space:]]*WAAROM:/ { waarom = trim(substr($0, index($0,":")+1)); next }
/^[[:space:]]*FRAGMENT:/ {
    if (match($0, /\[\[[0-9]+[[:space:]]*-[[:space:]]*[0-9]+\]\]/)) {
        blok = substr($0, RSTART+2, RLENGTH-4)
        split(blok, dl, /[[:space:]]*-[[:space:]]*/)
        nfrag++
        frag_a[nfrag] = dl[1]+0; frag_b[nfrag] = dl[2]+0
        rest = substr($0, RSTART+RLENGTH)
        sub(/^[[:space:]]*\|[[:space:]]*/, "", rest)
        frag_rol[nfrag] = (trim(rest) == "") ? "—" : trim(rest)
    }
    next
}

END {
    schrijf()
    if (nshort == 0) { print "GEEN_SHORTS" > "/dev/stderr"; exit 3 }
    printf("\n---\n\n%d shortvoorstel(len).\n", nshort)
}
