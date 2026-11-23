#!/usr/bin/env awk -f
#
# Bouwt quotes.md uit het transcript en de blokuitvoer van het model.
#
#   awk -f lib/render-quotes.awk -v MIN_S=5 -v MAX_S=30 transcript.tsv model.txt
#
# Het model levert tijdgrenzen. De tekst komt hier uit het transcript, zodat
# hij per definitie letterlijk is. De volgorde is die van het model: sterkte,
# niet chronologie.

BEGIN {
    FS = "\t"
    if (MIN_S == "") MIN_S = 5
    if (MAX_S == "") MAX_S = 30
    if (MAX_AANTAL == "") MAX_AANTAL = 20
    nseg = 0; nquote = 0; kort = 0; overgeslagen = 0
}

function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }

function tc(ms,   t, h, m, s) {
    t = int(ms/1000); h = int(t/3600); m = int((t%3600)/60); s = t%60
    return sprintf("%02d:%02d:%02d.%03d", h, m, s, ms%1000)
}

function komma(s) { gsub(/\./, ",", s); return s }
function dur(ms)  { return komma(sprintf("%.1f s", ms/1000)) }

# Controleert of een fragment een afgeronde uitspraak is.
function controleer(tekst,   klachten) {
    klachten = ""
    if (tekst !~ /^[A-ZÀ-ÞĲ]/)
        klachten = klachten "begint midden in een zin; "
    if (tekst !~ /[.!?]["\x27)]?$/)
        klachten = klachten "eindigt midden in een zin; "
    if (tekst ~ /^(En|Want|Maar|Dus|Daarom|Dan|Toen|Ook) /)
        klachten = klachten "opent met een voegwoord; "
    if (tekst ~ /^(Hij|Het|Die|Dat|Deze|Dit|Ze|Zij|Hem|Hun) /)
        klachten = klachten "opent met een verwijzing zonder antecedent; "
    sub(/; $/, "", klachten)
    return klachten
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

function schrijf(   waarschuwing, secs) {
    if (kort == 0 || nfrag == 0) return
    if (nquote >= MAX_AANTAL) { overgeslagen++; return }

    if (!bouw(frag_a, frag_b)) {
        printf("\n## Quote %d — %s\n\n> Geen transcriptsegmenten gevonden bij de opgegeven tijden. Overslaan.\n", nquote + 1, titel)
        nquote++
        return
    }

    secs = (f_end - f_start) / 1000
    waarschuwing = ""
    if (secs > MAX_S)      waarschuwing = sprintf("  ·  ⚠ te lang (grens %d s)", MAX_S)
    else if (secs < MIN_S) waarschuwing = sprintf("  ·  ⚠ te kort (ondergrens %d s)", MIN_S)

    nquote++
    printf("\n## Quote %d — %s\n\n", nquote, titel)
    printf("**%s - %s**  ·  %s%s\n\n", tc(f_start), tc(f_end), dur(f_end - f_start), waarschuwing)

    printf("> %s\n\n", f_text)

    klacht = controleer(f_text)
    if (klacht != "")
        printf("**Nalopen:** %s\n\n", klacht)

    printf("**Waarom:** %s\n", waarom)
}

FNR == NR {
    if (FNR == 1) next
    if ($1 !~ /^[0-9]+$/) next
    nseg++
    seg_start[nseg] = $1+0; seg_end[nseg] = $2+0; seg_text[nseg] = trim($3)
    next
}

/^##[[:space:]]*Quote/ {
    schrijf(); kort++; titel = ""; waarom = ""; nfrag = 0; next
}
/^[[:space:]]*TITEL:/  { titel  = trim(substr($0, index($0,":")+1)); next }
/^[[:space:]]*WAAROM:/ { waarom = trim(substr($0, index($0,":")+1)); next }
/^[[:space:]]*FRAGMENT:/ {
    if (match($0, /\[\[[0-9]+[[:space:]]*-[[:space:]]*[0-9]+\]\]/)) {
        blok = substr($0, RSTART+2, RLENGTH-4)
        split(blok, dl, /[[:space:]]*-[[:space:]]*/)
        nfrag++
        frag_a = dl[1]+0; frag_b = dl[2]+0
    }
    next
}

END {
    schrijf()
    if (nquote == 0) { print "GEEN_QUOTES" > "/dev/stderr"; exit 3 }
    if (overgeslagen > 0)
        printf("\n> %d kandidaten vielen af boven het maximum van %d quotes.\n", overgeslagen, MAX_AANTAL)
    printf("\n---\n\n%d quote(s).\n", nquote)
}
