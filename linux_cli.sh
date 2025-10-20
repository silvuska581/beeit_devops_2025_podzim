#!/usr/bin/env bash
#!/usr/bin/env bash
set -euo pipefail
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


