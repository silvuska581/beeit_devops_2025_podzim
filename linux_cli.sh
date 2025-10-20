#!/usr/bin/env bash


echo "Toto je moj domaci ukol. Budem se pridavat ukoly z kazdej lekcie"
echo "Druhy domaci ukol, zakladne prikazy"

echo
echo "Vypisanie vsetkych suborov v zlozke"
ls

echo
echo "Vylistovanie i schovanych"
ls -la

echo
echo "Vypisanie chyboveho kodu posledneho prikazu"
echo $?

echo
echo "Presmerovanie vysledku do outputu (zapíšem text do suboru output.txt)"
echo "Presmerovanie tajnych informaci" > output.txt

echo
echo "Vypisanie obsahu suboru output.txt"
cat output.txt

echo
echo "Presmerovanie erroru do errors.txt"
ls Idontexist 2> errors.txt
echo "Chybový kód posledného príkazu bol:" $?

echo "Obsah errors.txt:"
cat errors.txt

echo
echo "Vypis shellu"
echo "$SHELL"

echo
echo "Kde sa nachadzam"
pwd

exit 0

t -euo pipefail
# linux_cli.sh – domácí úkol (VIM)
	# Spusť nápovědu: ./linux_cli.greet() {
  local name="${1:-světe}"   # když nezadáš jméno, použije se "světe"
  echo "Ahoj, $name!"
}




# ------------------ LOG ------------------
LOG_MODE="stdout"    # "stdout" alebo "file"
LOG_FILE=""          # cesta k log súboru, ak LOG_MODE="file"

timestamp(){ date +"%Y-%m-%d %H:%M:%S"; }

log(){        # info správa
  local msg="[$(timestamp)] INFO: $*"
  if [ "$LOG_MODE" = "file" ] && [ -n "$LOG_FILE" ]; then
    echo "$msg" >> "$LOG_FILE"
  else
    echo "$msg"
  fi
}

logError(){   # chybová správa
  local msg="[$(timestamp)] ERROR: $*"
  if [ "$LOG_MODE" = "file" ] && [ -n "$LOG_FILE" ]; then
    echo "$msg" >> "$LOG_FILE"
  else
    echo "$msg" >&2
  fi
}

# ------------------ HELP -----------------
print_help(){
  cat <<EOF
Použitie: $0 [VOĽBY] AKCIA [ARGUMENTY]

VOĽBY (dobrovoľné):
  --log-file CESTA      log do súboru (inak ide na obrazovku)
  --stdout              log na obrazovku (predvolené)

AKCIE:
  -h, --help            nápoveda
  link soft|hard SRC TGT
                        vytvorí link (soft=symlink, hard=len na súbor)
  list                  vypíše balíčky s dostupným updatom (APT)
  upgrade               urobí update/upgrade (APT, potrebuje sudo)
  install-bin-link      vytvorí symlink /bin/linux_cli -> tento skript (sudo)

Príklady:
  $0 --stdout list
  $0 --log-file ~/linux_cli.log upgrade
  $0 link soft /etc/hosts /tmp/hosts_soft
  $0 link hard ~/subor.txt /tmp/subor_hard
  sudo $0 install-bin-link   # potom spúšťaj príkazom: linux_cli -h
EOF

echo "DU z 16.10.2025"

LINK_PATH="/usr/local/bin/linux_cli"   # kam vytvoriť symlink
SCRIPT_PATH="$(readlink -f "$0")"

DO_LIST_UPGRADABLE=false
DO_LIST_INSTALLED=false
DO_UPGRADE=false
DO_SYMLINK=false
LOG_FILE=""
EC=0

usage() {
  cat <<'EOF'
Použitie: linux_cli.sh [voľby]
  -a           vypísať balíčky, ktoré majú upgrade
  -i           vypísať všetky nainštalované balíčky
  -u           urobiť update + upgrade (APT)
  -s           vytvoriť symlink /usr/local/bin/linux_cli -> tento skript
  -f <súbor>   logovať výstup do súboru (append)
  -h           nápoveda

Viac volieb sa dá kombinovať (napr. -a -s -u).
Exit kódy: 0 OK; 1 zlé argumenty/PM; 2 log; 3 symlink; 4 list; 5 upgrade.
EOF
}

have_apt() { command -v apt-get >/dev/null 2>&1; }

setup_logging() {
  [ -z "$LOG_FILE" ] && return 0
  if [ -e "$LOG_FILE" ]; then
    echo "Log: '$LOG_FILE' existuje – budem PRIPÁJAŤ (append)."
  else
    if ! touch "$LOG_FILE" 2>/dev/null; then
      echo "ERROR: Nedá sa vytvoriť log súbor: $LOG_FILE" >&2
      EC=2
      return 1
    fi
    echo "Log: vytvorený '$LOG_FILE'."
  fi
  # všetok výstup aj chyby pôjdu do logu (append) aj na obrazovku
  exec > >(tee -a "$LOG_FILE") 2>&1
}

list_upgradable() {
  echo "== Upgradovateľné balíčky =="
  # ticho obnov indexy (ak je sudo k dispozícii)
  apt-get update -qq >/dev/null 2>&1 || true
  # zoznam upgradovateľných (ignorujeme prvý riadok hlavičky)
  if ! apt list --upgradeable 2>/dev/null | tail -n +2; then
    echo "ERROR: Výpis upgradovateľných balíčkov zlyhal." >&2
    [ $EC -eq 0 ] && EC=4
  fi
}

list_installed() {
  echo "== Všetky nainštalované balíčky =="
  if ! apt list --installed 2>/dev/null; then
    echo "ERROR: Výpis nainštalovaných balíčkov zlyhal." >&2
    [ $EC -eq 0 ] && EC=4
  fi
}

do_upgrade() {
  echo "== Update + Upgrade (APT) =="
  if ! (sudo apt-get update && sudo apt-get upgrade -y); then
    echo "ERROR: Upgrade zlyhal. Skús spustiť so sudo." >&2
    [ $EC -eq 0 ] && EC=5
  fi
}

create_symlink() {
  local target="$LINK_PATH"
  local dir; dir="$(dirname "$target")"

  if [ -L "$target" ]; then
    local points_to; points_to="$(readlink -f "$target")"
    if [ "$points_to" = "$SCRIPT_PATH" ]; then
      echo "Symlink už existuje a ukazuje sem: $target -> $points_to"
      return 0
    else
      echo "ERROR: Symlink už existuje, ale ukazuje inde: $target -> $points_to" >&2
      [ $EC -eq 0 ] && EC=3
      return 1
    fi
  elif [ -e "$target" ]; then
    echo "ERROR: '$target' už existuje (nie je symlink)." >&2
    [ $EC -eq 0 ] && EC=3
    return 1
  fi

  if [ ! -w "$dir" ]; then
    echo "ERROR: Nemám právo zapisovať do '$dir'." >&2
    echo "Spusti: sudo ln -s \"$SCRIPT_PATH\" \"$target\"" >&2
    [ $EC -eq 0 ] && EC=3
    return 1
  fi

  if ln -s "$SCRIPT_PATH" "$target"; then
    echo "Vytvorený symlink: $target -> $SCRIPT_PATH"
  else
    echo "ERROR: Symlink sa nepodarilo vytvoriť." >&2
    [ $EC -eq 0 ] && EC=3
  fi
}

# --- Parsovanie volieb ---
if [ $# -eq 0 ]; then
  usage; exit 1
fi

while getopts ":aiusf:h" opt; do
  case "$opt" in
    a) DO_LIST_UPGRADABLE=true ;;
    i) DO_LIST_INSTALLED=true  ;;
    u) DO_UPGRADE=true         ;;
    s) DO_SYMLINK=true         ;;
    f) LOG_FILE="$OPTARG"      ;;
    h) usage; exit 0           ;;
    :) echo "ERROR: Voľba -$OPTARG vyžaduje argument." >&2; usage; exit 1 ;;
    \?) echo "ERROR: Neznáma voľba -$OPTARG" >&2; usage; exit 1 ;;
  esac
done

# Log (ak -f)
setup_logging || true

# Kontrola správcu balíčkov
if ! have_apt; then
  echo "ERROR: Tento jednoduchý skript podporuje len APT (Ubuntu/Debian/WSL)." >&2
  [ $EC -eq 0 ] && EC=1
fi

# --- Spustenie akcií (poradie je len príklad) ---
$DO_LIST_UPGRADABLE && have_apt && list_upgradable
$DO_LIST_INSTALLED  && have_apt && list_installed
$DO_SYMLINK && create_symlink
$DO_UPGRADE && have_apt && do_upgrade

# Ak nebola zadaná žiadna akcia:
if ! $DO_LIST_UPGRADABLE && ! $DO_LIST_INSTALLED && ! $DO_UPGRADE && ! $DO_SYMLINK; then
  usage
  [ $EC -eq 0 ] && EC=1
fi

exit $EC
