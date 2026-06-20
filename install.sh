#!/data/data/com.termux/files/usr/bin/bash


# ----- Variables -----

RED=$'\e[0;31m'
YLW=$'\e[1;33m'
GRN=$'\e[0;32m'
BLU=$'\e[0;34m'
CYN=$'\e[0;36m'
GRY=$'\e[0;37m'
DGR=$'\e[1;30m'
WHT=$'\e[1;37m'
RST=$'\e[0m'

inst_list=("Hermes Agent" "SearXNG" "OpenWebUI")

install_hermes=false
install_searx=false
install_webui=false

HERMES_VENV='hermes-agent'
SEARXNG_FOLDER_NAME='searxng'
OPENWEBUI_VENV='open-webui'


# ----- Functions -----

checkbox_menu() {
  local -n result=$1
  shift

  local options=("$@")
  local selected=()
  local cursor=0
  local i key prefix box
  local start_row redraw_count=0
  local menu_height=$(( ${#options[@]} + 7 ))

  for _ in "${options[@]}"; do
    selected+=(0)
  done

  tput sc

  draw() {
    tput rc

    echo
    echo "${BLU}• ───────────────────────────────────────────────────── •"
    echo "${CYN}• Use ↑ ↓ to move | SPACE to toggle | ENTER to confirm  •"
    echo "${BLU}• ───────────────────────────────────────────────────── •"
    echo "${BLU}• ───────────────────────────────────────────────────── •"

    for i in "${!options[@]}"; do
      if [ "$i" -eq "$cursor" ]; then
        prefix="${CYN}      >"
      else
        prefix="${CYN}       "
      fi

      if [ "${selected[$i]}" -eq 1 ]; then
        box="${CYN}[x]"
      else
        box="${CYN}[ ]"
      fi

      printf "%s %s %s\n" "$prefix" "$box" "${options[$i]}"
    done

    echo "${BLU}• ───────────────────────────────────────────────────── •"
    redraw_count=$((redraw_count + 1))
  }

  tput civis
  stty -echo -icanon time 0 min 0

  cleanup() {
    stty sane
    tput cnorm
    tput rc
  }

  trap cleanup EXIT INT TERM

  draw

  while true; do
    IFS= read -rsn1 key

    if [[ $key == $'\x1b' ]]; then
      read -rsn2 key
      case "$key" in
        "[A") ((cursor--)) ;; # up
        "[B") ((cursor++)) ;; # down
      esac
    else
      case "$key" in
        " ")
          selected[$cursor]=$((1 - selected[$cursor]))
          ;;
        "")
          break
          ;;
      esac
    fi

    ((cursor < 0)) && cursor=0
    ((cursor >= ${#options[@]})) && cursor=$((${#options[@]} - 1))

    draw
  done

  stty sane
  tput cnorm
  tput rc

  for ((i=0; i<menu_height; i++)); do
    tput el
    printf '\n'
  done

  printf '\033[%dA' "$menu_height"

  result=()
  for i in "${!options[@]}"; do
    [[ ${selected[$i]} -eq 1 ]] && result+=("${options[$i]}")
  done
}

validate_name() {
  local name="$1"

  [[ -z "$name" ]] && return 0

  case "$name" in
    "."|".."|*/.|*/..|./*|../*)
      return 1
      ;;
  esac

  [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]]
}

detect_termux_api() {
  if command -v termux-battery-status >/dev/null 2>&1 && cmd package list packages | grep -q '^package:com.termux.api$'; then
    echo true
  else
    echo false
  fi
}


# ----- Installation -----

set -euo pipefail
pkg install -y ncurses-utils
clear
termux-wake-lock
echo "${CYN}
║${BLU}    ██████╗  █████╗ ██╗    ██╗███╗   ██╗        ${CYN}║
║${BLU}    ██╔══██╗██╔══██╗██║    ██║████╗  ██║        ${CYN}║
║${BLU}    ██║  ██║███████║██║ █╗ ██║██╔██╗ ██║        ${CYN}║
║${BLU}    ██║  ██║██╔══██║██║███╗██║██║╚██╗██║        ${CYN}║
║${GRY}    ██████╔╝██║  ██║╚███╔███╔╝██║ ╚████║        ${CYN}║
║${GRY}    ╚═════╝ ╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═══╝        ${CYN}║
║${BLU}    ███████╗ █████╗ ██╗     ██╗     ███████╗    ${CYN}║
║${BLU}    ██╔════╝██╔══██╗██║     ██║     ╚══███╔╝    ${CYN}║
║${BLU}    █████╗  ███████║██║     ██║       ███╔╝     ${CYN}║
║${BLU}    ██╔══╝  ██╔══██║██║     ██║      ███╔╝      ${CYN}║
║${GRY}    ██║     ██║  ██║███████╗███████╗███████╗    ${CYN}║
║${GRY}    ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝    ${CYN}║

${CYN}
╔═══════════════════════════════════════════════════════════════╗
║${GRY}  🚀 Starting Installation of Hermes, SearXNG and OpenWebUI... ${CYN}║
╚═══════════════════════════════════════════════════════════════╝
${YLW}─────────────────────────────────────────────────────────────────
${YLW}• Detecting Termux environment... ${RST}"
sleep 3

if [[ -z "${TERMUX_VERSION:-}" || ! -d "/data/data/com.termux" ]] && ! command -v pkg >/dev/null 2>&1; then
  echo "${RED}• ERROR: Not in termux environment!${RST}"
  if [[ "$(detect_termux_api)" == true ]]; then
    echo "${RED}• [RECOMMENDED] Install Termux:API from F-droid for extra features before running this again: ${BLU}https://f-droid.org/en/packages/com.termux.api/${RST}"
  fi
  echo "${RED}• Please install Termux from F-Droid: https://f-droid.org/en/packages/com.termux/${RST}"
  echo "${YLW}─────────────────────────────────────────────────────────────────${RST}"
  exit 1
fi

echo "${GRN}• ✅ Termux environment detected!${RST}"
sleep 0.5
echo "${YLW}• Detecting presence of Termux:API...${RST}"
sleep 1
if [[ "$(detect_termux_api)" == "true" ]]; then
  echo "${GRN}• ✅ Termux:API detected!${RST}"
else
  echo "${RED}• [RECOMMENDED] Install Termux:API from F-Droid for extra features before running this again: ${BLU}https://f-droid.org/en/packages/com.termux.api/${RST}"
  read -rp "${YLW}• Exit now? [Y/n]: " choice
  choice=${choice,,}

  if [[ -z "$choice" || "$choice" == "y" ]]; then
    echo "${YLW}• Exited.${RST}"
    echo "${YLW}─────────────────────────────────────────────────────────────────${RST}"
    exit 0
  elif [[ "$choice" == "n" ]]; then
    echo "${YLW}• Continuing...${RST}"
  else
    echo "${RED}• Invalid option. Defaulting to YES...${RST}"
    exit 0
  fi
fi

sleep 2

read -rp "${YLW}• Install all (Hermes Agent + SearXNG + OpenWebUI)? [y/N]: ${RST}" install_all
sleep 1
echo

if [[ "$install_all" =~ ^[Yy]$ ]]; then
  install_hermes=true
  install_searx=true
  install_webui=true
else
  if [[ ! "$install_all" == [Nn] ]]; then
    echo "${RED}• WARNING: Not a valid option. Defaulting to NO..."
    sleep 0.5
  fi
  echo "${YLW}• Please select which to install from the options provided:${RST}"
  sleep 2

  selected_installations_list=()
  checkbox_menu selected_installations_list "${inst_list[@]}"
  sleep 0.5

  echo "${YLW}• Selected:${RST}"
  printf "${YLW}    ✓ %s\n" "${selected_installations_list[@]}${RST}"
  sleep 2

  for item in "${selected_installations_list[@]}"; do
    case "$item" in
      "Hermes Agent")
        install_hermes=true;;
      "SearXNG")
        install_searx=true;;
      "OpenWebUI")
        install_webui=true;;
    esac
  done
fi

if [[ "$install_hermes" != true && "$install_searx" != true && "$install_webui" != true ]]; then
  echo "${RED}• ERROR: Please select at least 1 option to install.${RST}"
  exit 0
fi

echo
if $install_hermes; then
  read -rp "${YLW}• What name would you give for Hermes Agent's venv? It will be created in your home directory (~). Leave blank for default. [Default: ${HERMES_VENV}]: ${RST}" input

  if [[ -n "$input" ]]; then
    input="${input#\~/}"
    input="${input%/}"
  fi
  if ! validate_name "$input"; then
    echo "${RED}• Invalid name. Use only letters, numbers, dots (.), underscores (_), and hyphens (-).${RST}"
    exit 1
  fi
  target_name="${input:-$HERMES_VENV}"
  if [[ -e "$HOME/$target_name" ]]; then
    echo "${RED}• Hermes Agent's venv path already exists: $HOME/$target_name${RST}"
    exit 1
  fi

  HERMES_VENV="$target_name"
fi

if $install_searx; then
  read -rp "${YLW}• What name would you give for SearXNG's folder name? It will be created in your home directory (~). Leave blank for default. [Default: ${SEARXNG_FOLDER_NAME}]: ${RST}" input

  if [[ -n "$input" ]]; then
    input="${input#\~/}"
    input="${input%/}"
  fi
  if ! validate_name "$input"; then
    echo "${RED}• Invalid name. Use only letters, numbers, dots (.), underscores (_), and hyphens (-).${RST}"
    exit 1
  fi
  target_name="${input:-$SEARXNG_FOLDER_NAME}"
  if [[ -e "$HOME/$target_name" ]]; then
    echo "${RED}• SearXNG folder already exists: $HOME/$target_name${RST}"
    exit 1
  fi

  SEARXNG_FOLDER_NAME="$target_name"
fi

if $install_webui; then
  read -rp "${YLW}• What name would you give for OpenWebUI's venv? It will be created in your home directory (~). Leave blank for default. [Default: ${OPENWEBUI_VENV}]: ${RST}" input

  if [[ -n "$input" ]]; then
    input="${input#\~/}"
    input="${input%/}"
  fi
  if ! validate_name "$input"; then
    echo "${RED}• Invalid name. Use only letters, numbers, dots (.), underscores (_), and hyphens (-).${RST}"
    exit 1
  fi
  target_name="${input:-$OPENWEBUI_VENV}"
  if [[ -e "$HOME/$target_name" ]]; then
    echo "${RED}• OpenWebUI venv path already exists: $HOME/$target_name${RST}"
    exit 1
  fi

  OPENWEBUI_VENV="$target_name"
fi

echo
echo "${GRN}• ✅ Done. You can safely leave this running in the background. Installation may take some time.${RST}"
echo

sleep 3
echo "${YLW}• Starting installation process..."
echo "${GRN}• ──────────────────────────────────────────────${RST}"
sleep 1

echo
echo "${YLW}• Updating termux window... "
echo "${BLU}• ─────────────────────────────────${RST}"
pkg update -y
echo "${BLU}• ─────────────────────────────────"
echo
echo "${YLW}• Upgrading termux packages..."
echo "${BLU}• ─────────────────────────────────${RST}"
pkg upgrade -y
echo "${BLU}• ─────────────────────────────────${RST}"
echo
if [[ "$(detect_termux_api)" == true ]] || [[ $install_hermes && $install_searx && $install_webui ]]; then
  echo "${YLW}• Installing termux packages..."
  echo "${BLU}• ─────────────────────────────────${RST}"
  if [[ "$(detect_termux_api)" != true ]]; then
    pkg install -y termux-api
  fi
  if [[ $install_hermes && $install_searx && $install_webui ]]; then
    pkg install -y tmux
  fi
  echo "${BLU}• ─────────────────────────────────${RST}"
  echo
fi

if $install_hermes; then
  echo
  echo "${YLW}• Installing Hermes Agent..."
  echo "${BLU}• ─────────────────────────────────${RST}"
  echo "${YLW}• Installing required packages...${RST}"
  pkg install -y python python-pip python-psutil git clang rust make pkg-config libffi openssl nodejs npm ripgrep ffmpeg
  echo "${YLW}• Now installing Hermes Agent...${RST}"
  echo "${YLW}• Creating venv..."
  python3 -m venv ~/${HERMES_VENV}/venv
  source ~/${HERMES_VENV}/venv/bin/activate
  echo "${YLW}• Installing pip packages...${RST}"
  PYVER=$(python -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
  PSUTIL_INFO_PATH=$(find "$PREFIX/lib/python${PYVER}/site-packages" -name "psutil*.dist-info" | head -n 1)
  ln -s "$PREFIX/lib/python${PYVER}/site-packages/psutil" "$HOME/${HERMES_VENV}/venv/lib/python${PYVER}/site-packages/"
  ln -s "$PSUTIL_INFO_PATH" "$HOME/${HERMES_VENV}/venv/lib/python${PYVER}/site-packages/"
  pip install -U pip setuptools wheel hermes-agent
  deactivate
  echo "${GRN}• ✅ Done installing Hermes Agent!"
  echo "${BLU}• ─────────────────────────────────${RST}"
  echo
fi

if $install_searx; then
  echo
  echo "${YLW}• Installing SearXNG..."
  echo "${BLU}• ─────────────────────────────────${RST}"
  echo "${YLW}• Installing required packages...${RST}"
  pkg install -y git python python-pip libxml2 libxslt clang binutils uv
  echo "${YLW}• Cloning GitHub Repository${RST}"
  git clone https://github.com/searxng/searxng.git ~/${SEARXNG_FOLDER_NAME}
  cd ~/${SEARXNG_FOLDER_NAME}
  cp searx/settings.yml settings.yml
  echo "${YLW}• Creating venv...${RST}"
  python3 -m venv ~/${SEARXNG_FOLDER_NAME}/venv
  source ~/${SEARXNG_FOLDER_NAME}/venv/bin/activate
  echo "${YLW}• Installing pip packages... ${RST}"
  uv pip install -U pip setuptools wheel
  uv pip install --use-pep517 --no-build-isolation -e .
  cd
  deactivate
  echo "${GRN}• ✅ Done installing SearXNG!"
  echo "${BLU}• ─────────────────────────────────${RST}"
  echo
fi

if $install_webui; then
  echo
  echo "${YLW}• Installing OpenWebUI..."
  echo "${BLU}• ─────────────────────────────────${RST}"
  echo "${YLW}• Installing required packages... ${RST}"
  pkg install -y proot-distro
  echo "${YLW}• Installing Ubuntu from Proot-Distro...${RST}"
  proot-distro install ubuntu
  sleep 5
  echo "${YLW}• Installing required packages for Ubuntu...${RST}"
  proot-distro login ubuntu -- bash -lc "apt update && apt install -y python3 python3-pip python3-venv build-essential cmake git"
  proot-distro login ubuntu -- bash -lc "python3 -m pip install -U pip setuptools wheel uv"
  echo "${YLW}• Creating venv...${RST}"
  proot-distro login ubuntu -- bash -lc "python3 -m venv ~/${OPENWEBUI_VENV}"
  echo "${YLW}• Installing pip packages... ${RST}"
  proot-distro login ubuntu -- bash -lc "source ~/${OPENWEBUI_VENV}/bin/activate && uv pip install -U pip setuptools wheel open-webui"
  echo "${YLW}• Setting OpenWebUI data directory to ~/${OPENWEBUI_VENV}/data"
  proot-distro login ubuntu -- bash -lc "mkdir -p ~/${OPENWEBUI_VENV}/data"

  proot-distro login ubuntu -- bash -lc "cat <<EOF >> ~/.bashrc
# • ===== HermSearxWebUI ===== •
# • === open-webui === •
export DATA_DIR="/root/${OPENWEBUI_VENV}/data"
EOF
"
  echo "${GRN}• ✅ Done installing OpenWebUI!"
  echo "${BLU}• ─────────────────────────────────${RST}"
  echo
fi

echo "${GRN}• ✅ INSTALLATION ENDED!!!"
echo "${GRN}• ──────────────────────────────────────────────${RST}"
sleep 1

echo
echo "${YLW}• Putting aliases and functions into ~/.bashrc..."

grep -q "# • ===== HermSearxWebUI ===== •" ~/.bashrc || cat <<EOF >> ~/.bashrc
# • ===== HermSearxWebUI ===== •
EOF

if $install_hermesv; then
  grep -q "alias hermes-venv" ~/.bashrc || cat <<EOF >> ~/.bashrc
# • === hermes-agent === •
alias hermes-venv="source ~/${HERMES_VENV}/venv/bin/activate"
EOF
fi

if $install_searx; then
  grep -q "alias searxng" ~/.bashrc || cat <<EOF >> ~/.bashrc
# • === searxng === •
alias searxng="cd ~/${SEARXNG_FOLDER_NAME} && source venv/bin/activate && python -m searx.webapp && cd && deactivate"
EOF
fi

if $install_webui; then
  grep -q "alias open-webui-venv" ~/.bashrc && grep -q "alias open-webui-run" ~/.bashrc || cat <<EOF >> ~/.bashrc
# • === open-webui === •
alias open-webui-venv="proot-distro login ubuntu -- bash -lc 'source ~/${OPENWEBUI_VENV}/bin/activate'"
alias open-webui-run="proot-distro login ubuntu -- bash -lc 'source ~/${OPENWEBUI_VENV}/bin/activate && open-webui serve'"
EOF
fi

if [[ $install_hermes && $install_searx && $install_webui && "$(detect_termux_api)" == true ]]; then
  grep -q "hermsearxwebui()" ~/.bashrc || cat <<EOF >> ~/.bashrc
# • === hermsearxwebui === •
hermsearxwebui() {
    echo "
╔═══════════════════════════════════════════╗
║       🚀 Starting HermSearxWebUI...       ║
╚═══════════════════════════════════════════╝
──────────────────────────────────────────────
• Starting...
• Preparing services...";
    termux-wake-lock;
    termux-notification --id "termux_hermsearxwebui" -t "🚀 Hermes + SearXNG + OpenWebUI" -c "Running in Termux... (HermesSearXWebUI)" --button1 "Show logs" --button1-action "am start -W -n com.termux/.app.TermuxActivity" --button2 "Kill session" --button2-action "tmux kill-session -t hermsearxwebui" --sound --ongoing;
    termux-toast -g "top" -c "white" -b "black" "hermsearxwebui is running...";
    echo "• Prepared services! ✅";
    sleep 1;
    echo "• Preparing tmux session with windows... ";
    tmux new-session -d -s hermsearxwebui -n "dashboard";
    tmux send-keys -t hermsearxwebui:dashboard "source ~/${HERMES_VENV}/venv/bin/activate && hermes dashboard" C-m;
    tmux new-window -t hermsearxwebui -n "gateway";
    tmux send-keys -t hermsearxwebui:gateway "source ~/${HERMES_VENV}/venv/bin/activate && hermes gateway" C-m;
    tmux new-window -t hermsearxwebui -n "searx";
    tmux send-keys -t hermsearxwebui:searx "cd ~/${SEARXNG_FOLDER_NAME} && source venv/bin/activate && python3 -m searx.webapp > searx.log 2>&1" C-m;
    tmux new-window -t hermsearxwebui -n "webui";
    tmux send-keys -t hermsearxwebui:webui "proot-distro login ubuntu -- bash -lc 'source ~/${OPENWEBUI_VENV}/bin/activate && open-webui serve'" C-m;
    tmux new-window -t hermsearxwebui -n "default";
    tmux send-keys -t hermsearxwebui:default "clear; echo '
╔════════════════════════════════════════════╗
║ 🚀 Welcome to Hermes + SearXNG + OpenWebUI ║
╚════════════════════════════════════════════╝
──────────────────────────────────────────────
| • Hermes Dashboard                         |
| • Hermes Gateway                           |
| • SearXNG Search Engine                    |
| • OpenWebUI Interface                      |
| • Default (Current)                        |
|                                            |
──────────────────────────────────────────────
──────────────────────────────────────────────
| Press Ctrl+C to continue                   |
──────────────────────────────────────────────
'; sleep infinity" C-m;
    tmux select-window -t hermsearxwebui:default;
    echo "• Prepared tmux session! ✅";
    sleep 1;
    colors=("\e[31m" "\e[91m" "\e[33m" "\e[93m" "\e[92m" "\e[92m");
    countdown_num=0;
    for i in {5..0};
    do
      printf "\r• Launching in %b%d\e[0m " "${colors[$((5-i))]}" "$i";
      ((countdown_num++));
      sleep 1;
    done;
    echo;
    sleep 1;
    tmux attach-session -t hermsearxwebui;
    echo "• Exited"
    echo "──────────────────────────────────────────────";
    termux-notification-remove "termux_hermsearxwebui";
    termux-wake-unlock
}
EOF

elif [[ $install_hermes && $install_searx && $install_webui ]]; then
  grep -q "hermsearxwebui()" ~/.bashrc || cat <<EOF >> ~/.bashrc
# • === hermsearxwebui === •
hermsearxwebui ()
{
  echo "
╔════════════════════════════════════════════╗
║      🚀 Starting HermsSearXWebUI...        ║
╚════════════════════════════════════════════╝
──────────────────────────────────────────────
• Starting...
• Preparing services...";

  termux-wake-lock 2>/dev/null || true;

  echo "• Prepared services! ✅";
  sleep 1;

  echo "• Preparing tmux session with windows... ";

  tmux new-session -d -s hermsearxwebui -n "dashboard";
  tmux send-keys -t hermsearxwebui:dashboard "source ~/${HERMES_VENV}/venv/bin/activate && hermes dashboard" C-m;

  tmux new-window -t hermsearxwebui -n "gateway";
  tmux send-keys -t hermsearxwebui:gateway "source ~/${HERMES_VENV}/venv/bin/activate && hermes gateway" C-m;

  tmux new-window -t hermsearxwebui -n "searx";
  tmux send-keys -t hermsearxwebui:searx "cd ~/${SEARXNG_FOLDER_NAME} && source venv/bin/activate && python3 -m searx.webapp > searx.log 2>&1" C-m;

  tmux new-window -t hermsearxwebui -n "webui";
  tmux send-keys -t hermsearxwebui:webui "proot-distro login ubuntu -- bash -lc 'source ~/${OPENWEBUI_VENV}/bin/activate && open-webui serve'" C-m;

  tmux new-window -t hermsearxwebui -n "default";
  tmux send-keys -t hermsearxwebui:default "clear; echo '
╔════════════════════════════════════════════╗
║ 🚀 Welcome to Hermes + SearXNG + OpenWebUI ║
╚════════════════════════════════════════════╝
──────────────────────────────────────────────
| • Hermes Dashboard                         |
| • Hermes Gateway                           |
| • SearXNG Search Engine                    |
| • OpenWebUI Interface                      |
| • Default (Current)                        |
|                                            |
──────────────────────────────────────────────
──────────────────────────────────────────────
| Press Ctrl+C to continue                   |
──────────────────────────────────────────────
'; sleep infinity" C-m;

  tmux select-window -t hermsearxwebui:default;

  echo "• Prepared tmux session! ✅";
  sleep 1;
  colors=("\e[31m" "\e[91m" "\e[33m" "\e[93m" "\e[92m" "\e[92m");
  countdown_num=0;
  for i in {5..0};
  do
    printf "\r• Launching in %b%d\e[0m " "${colors[$((5-i))]}" "$i";
    ((countdown_num++));
    sleep 1;
  done;
  echo;
  sleep 1;
  tmux attach-session -t hermsearxwebui;
  echo "• Exited"
  echo "──────────────────────────────────────────────";
  termux-wake-unlock 2>/dev/null || true;
}
EOF
fi

termux-wake-unlock

echo "${DGR}• Run: source ~/.bashrc${RST}"
echo "${GRN}• ✅ Complete${RST}"

echo "${YLW}─────────────────────────────────────────────────────────────────${RST}"
