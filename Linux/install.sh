#!/usr/bin/env bash

# ============================================================================
# HermSearxWebUI
# Linux AMD64 / x86_64 installer
# ============================================================================

set -e

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


checkbox_menu() {
  local -n result=$1
  shift

  local options=("$@")
  local selected=()
  local cursor=0
  local i key prefix box
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
  }

  tput civis
  stty -echo -icanon min 1 time 0

  cleanup() {
    stty sane
    tput cnorm
    tput rc
  }

  trap cleanup EXIT INT TERM

  draw

  while true; do

    IFS= read -rsn1 key

    if [[ $key == $'\e' ]]; then

      read -rsn1 key
      [[ $key == "[" ]] || continue
      read -rsn1 key

      case "$key" in
        A) ((cursor--)) ;;
        B) ((cursor++)) ;;
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

    if (( cursor >= ${#options[@]} )); then
      cursor=$((${#options[@]} - 1))
    fi

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


clear_screen() {
  clear
}


pause_short() {
  sleep 0.5
}


# ----- Linux detection -----

detect_linux() {

  if [[ "$(uname -s)" != "Linux" ]]; then
    return 1
  fi

  return 0
}


# ----- Architecture detection -----

detect_architecture() {

  local arch

  arch="$(uname -m)"

  case "$arch" in

    x86_64|amd64)
      return 0
      ;;

    *)
      return 1
      ;;

  esac
}


# ----- Distribution detection -----

detect_distribution() {

  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
  else
    ID="unknown"
    ID_LIKE=""
  fi

  case "${ID:-}" in

    ubuntu|debian)
      return 0
      ;;

  esac

  if [[ "${ID_LIKE:-}" == *debian* ]]; then
    return 0
  fi

  return 1
}


# ----- Command check -----

command_exists() {
  command -v "$1" >/dev/null 2>&1
}


# ----- Installation -----

clear_screen

echo ""

echo "║${BLU}    ██████╗  █████╗ ██╗    ██╗███╗   ██╗        ${CYN}║"
echo "║${BLU}    ██╔══██╗██╔══██╗██║    ██║████╗  ██║        ${CYN}║"
echo "║${BLU}    ██║  ██║███████║██║ █╗ ██║██╔██╗ ██║        ${CYN}║"
echo "║${BLU}    ██║  ██║██╔══██║██║███╗██║██║╚██╗██║        ${CYN}║"
echo "║${BLU}    ██████╔╝██║  ██║╚███╔███╔╝██║ ╚████║        ${CYN}║"
echo "║${BLU}    ╚═════╝ ╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═══╝        ${CYN}║"
echo "║${BLU}    ███████╗ █████╗ ██╗     ██╗     ███████╗    ${CYN}║"
echo "║${BLU}    ██╔════╝██╔══██╗██║     ██║     ╚══███╔╝    ${CYN}║"
echo "║${BLU}    █████╗  ███████║██║     ██║       ███╔╝     ${CYN}║"
echo "║${BLU}    ██╔══╝  ██╔══██║██║     ██║      ███╔╝      ${CYN}║"
echo "║${BLU}    ██║     ██║  ██║███████╗███████╗███████╗    ${CYN}║"
echo "║${BLU}    ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝    ${CYN}║"

echo "${CYN}"

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║${GRY}  🚀 Starting Installation of Hermes, SearXNG and OpenWebUI... ${CYN}║"
echo "╚═══════════════════════════════════════════════════════════════╝"

echo "${YLW}─────────────────────────────────────────────────────────────────"

echo "${YLW}• Detecting Linux environment... ${RST}"

sleep 3


# ----- Linux detection -----

if ! detect_linux; then

  echo "${RED}• ERROR: Not in a Linux environment!${RST}"
  echo "${RED}• This installer is for Linux AMD64/x86_64 computers and laptops.${RST}"
  echo "${YLW}─────────────────────────────────────────────────────────────────${RST}"

  exit 1

fi


echo "${GRN}• ✅ Linux environment detected!${RST}"

sleep 0.5


# ----- Architecture detection -----

echo "${YLW}• Detecting CPU architecture...${RST}"

sleep 1

if ! detect_architecture; then

  echo "${RED}• ERROR: Unsupported CPU architecture!${RST}"
  echo "${RED}• This version requires Linux AMD64/x86_64.${RST}"
  echo "${YLW}─────────────────────────────────────────────────────────────────${RST}"

  exit 1

fi


echo "${GRN}• ✅ Linux AMD64/x86_64 detected!${RST}"

sleep 0.5


# ----- Distribution detection -----

echo "${YLW}• Detecting Linux distribution...${RST}"

sleep 1

if ! detect_distribution; then

  echo "${RED}• ERROR: Unsupported Linux distribution!${RST}"
  echo "${RED}• This installer currently supports Debian/Ubuntu-based systems.${RST}"
  echo "${YLW}─────────────────────────────────────────────────────────────────${RST}"

  exit 1

fi


echo "${GRN}• ✅ Debian/Ubuntu-based Linux detected!${RST}"

sleep 1


# ----- sudo detection -----

if [[ $EUID -eq 0 ]]; then

  SUDO=""

else

  if ! command_exists sudo; then

    echo "${RED}• ERROR: sudo is required for package installation.${RST}"
    echo "${RED}• Please install sudo or run this installer as root.${RST}"
    exit 1
  fi

  SUDO="sudo"

fi


sleep 1


# ----- Selection -----

install_all=$(read -rp "${YLW}• Install all (Hermes Agent + SearXNG + OpenWebUI)? [y/N]: ${RST}" choice && printf '%s' "$choice")

sleep 1

echo

if [[ "$install_all" =~ ^[Yy]$ ]]; then

  install_hermes=true
  install_searx=true
  install_webui=true

else

  if [[ ! "$install_all" =~ ^[Nn]$ && -n "$install_all" ]]; then

    echo "${RED}• WARNING: Not a valid option. Defaulting to NO...${RST}"

    sleep 0.5

  fi

  echo "${YLW}• Please select which to install from the options provided:${RST}"

  sleep 2

  selected_installations_list=()

  checkbox_menu selected_installations_list "${inst_list[@]}"

  sleep 0.5

  echo "${YLW}• Selected:${RST}"

  printf "${YLW}    ✓ %s\n" "${selected_installations_list[@]}"

  sleep 2

  for item in "${selected_installations_list[@]}"; do

    case "$item" in

      "Hermes Agent")
        install_hermes=true
        ;;

      "SearXNG")
        install_searx=true
        ;;

      "OpenWebUI")
        install_webui=true
        ;;

    esac

  done

fi


if [[ "$install_hermes" != true &&
      "$install_searx" != true &&
      "$install_webui" != true ]]; then

  echo "${RED}• ERROR: Please select at least 1 option to install.${RST}"

  exit 0

fi


echo


# ----- Hermes name -----

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


# ----- SearXNG name -----

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


# ----- OpenWebUI name -----

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


# ----- Update system -----

echo

echo "${YLW}• Updating Linux packages... "

echo "${BLU}• ─────────────────────────────────${RST}"

$SUDO apt-get update -y

echo "${BLU}• ─────────────────────────────────${RST}"

echo

echo "${YLW}• Upgrading Linux packages..."

echo "${BLU}• ─────────────────────────────────${RST}"

$SUDO apt-get upgrade -y

echo "${BLU}• ─────────────────────────────────${RST}"

echo


# ----- Base packages -----

echo "${YLW}• Installing required Linux packages..."

echo "${BLU}• ─────────────────────────────────${RST}"

$SUDO apt-get install -y \
  ca-certificates \
  curl \
  git \
  xz-utils \
  build-essential \
  pkg-config \
  python3 \
  python3-pip \
  python3-venv \
  python3-dev \
  clang \
  rustc \
  cargo \
  libffi-dev \
  libssl-dev \
  libxml2-dev \
  libxslt1-dev \
  zlib1g-dev \
  nodejs \
  npm \
  ripgrep \
  ffmpeg \
  tmux

echo "${BLU}• ─────────────────────────────────${RST}"

echo


# ----- Hermes Agent -----

if $install_hermes; then

  echo

  echo "${YLW}• Installing Hermes Agent..."

  echo "${BLU}• ─────────────────────────────────${RST}"

  echo "${YLW}• Installing required packages...${RST}"

  $SUDO apt-get install -y \
    ca-certificates \
    curl \
    git \
    xz-utils \
    build-essential

  echo "${YLW}• Now installing Hermes Agent...${RST}"

  echo "${YLW}• Using the official Hermes Linux installer...${RST}"

  HERMES_HOME="$HOME/$HERMES_VENV" \
  HERMES_INSTALL_DIR="$HOME/$HERMES_VENV/hermes-agent" \
  bash <(curl -fsSL https://hermes-agent.nousresearch.com/install.sh) \
    --skip-setup \
    --skip-browser

  echo "${YLW}• Creating compatibility venv path...${RST}"

  mkdir -p "$HOME/$HERMES_VENV"

  if [[ -d "$HOME/$HERMES_VENV/hermes-agent/venv" ]]; then

    ln -sfn \
      "$HOME/$HERMES_VENV/hermes-agent/venv" \
      "$HOME/$HERMES_VENV/venv"

  fi

  echo "${GRN}• ✅ Done installing Hermes Agent!${RST}"

  echo "${BLU}• ─────────────────────────────────${RST}"

  echo

fi


# ----- SearXNG -----

if $install_searx; then

  echo

  echo "${YLW}• Installing SearXNG..."

  echo "${BLU}• ─────────────────────────────────${RST}"

  echo "${YLW}• Installing required packages...${RST}"

  $SUDO apt-get install -y \
    git \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    python3-babel \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    libffi-dev \
    libssl-dev \
    clang \
    build-essential

  echo "${YLW}• Cloning GitHub Repository${RST}"

  git clone \
    https://github.com/searxng/searxng.git \
    "$HOME/$SEARXNG_FOLDER_NAME"

  cd "$HOME/$SEARXNG_FOLDER_NAME"

  cp searx/settings.yml settings.yml

  echo "${YLW}• Creating venv...${RST}"

  python3 -m venv \
    "$HOME/$SEARXNG_FOLDER_NAME/venv"

  source "$HOME/$SEARXNG_FOLDER_NAME/venv/bin/activate"

  echo "${YLW}• Installing pip packages... ${RST}"

  python -m pip install -U \
    pip \
    setuptools \
    wheel

  python -m pip install -U \
    pyyaml \
    msgspec \
    typing-extensions \
    pybind11

  python -m pip install \
    --use-pep517 \
    --no-build-isolation \
    -e .

  deactivate

  cd "$HOME"

  echo "${GRN}• ✅ Done installing SearXNG!${RST}"

  echo "${BLU}• ─────────────────────────────────${RST}"

  echo

fi


# ----- OpenWebUI -----

if $install_webui; then

  echo

  echo "${YLW}• Installing OpenWebUI..."

  echo "${BLU}• ─────────────────────────────────${RST}"

  echo "${YLW}• Installing required packages... ${RST}"

  $SUDO apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    cmake \
    git

  echo "${YLW}• Checking Python version for OpenWebUI...${RST}"

  PYTHON_BIN=""

  if command_exists python3.12; then
    PYTHON_BIN="python3.12"
  elif command_exists python3.11; then
    PYTHON_BIN="python3.11"
  elif command_exists python3; then
    PYTHON_BIN="python3"
  fi

  if [[ -z "$PYTHON_BIN" ]]; then

    echo "${RED}• ERROR: Python 3.11 or 3.12 is required for OpenWebUI.${RST}"

    exit 1

  fi

  OPENWEBUI_PYVER="$("$PYTHON_BIN" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"

  if [[ "$OPENWEBUI_PYVER" != "3.11" &&
        "$OPENWEBUI_PYVER" != "3.12" ]]; then

    echo "${RED}• ERROR: OpenWebUI requires Python 3.11 or 3.12.${RST}"
    echo "${RED}• Detected: Python $OPENWEBUI_PYVER${RST}"
    echo "${YLW}• Install Python 3.11 or 3.12 and run this installer again.${RST}"

    exit 1

  fi

  echo "${YLW}• Creating venv...${RST}"

  "$PYTHON_BIN" -m venv \
    "$HOME/$OPENWEBUI_VENV"

  source "$HOME/$OPENWEBUI_VENV/bin/activate"

  echo "${YLW}• Installing pip packages... ${RST}"

  python -m pip install -U \
    pip \
    setuptools \
    wheel

  python -m pip install \
    open-webui

  echo "${YLW}• Setting OpenWebUI data directory to ~/${OPENWEBUI_VENV}/data"

  mkdir -p \
    "$HOME/$OPENWEBUI_VENV/data"

  deactivate

  echo "${GRN}• ✅ Done installing OpenWebUI!${RST}"

  echo "${BLU}• ─────────────────────────────────${RST}"

  echo

fi


# ----- Installation finished -----

echo "${GRN}• ✅ INSTALLATION ENDED!!!"

echo "${GRN}• ──────────────────────────────────────────────${RST}"

sleep 1

echo

echo "${YLW}• Putting aliases and functions into ~/.bashrc..."


# ----- .bashrc base -----

grep -q "# • ===== HermSearxWebUI ===== •" "$HOME/.bashrc" 2>/dev/null ||
cat <<EOF >> "$HOME/.bashrc"

# • ===== HermSearxWebUI ===== •
EOF


# ----- Hermes alias -----

if $install_hermes; then

  grep -q "alias hermes-venv" "$HOME/.bashrc" 2>/dev/null ||
  cat <<EOF >> "$HOME/.bashrc"

# • === hermes-agent === •
alias hermes-venv="source ~/${HERMES_VENV}/venv/bin/activate"
EOF

fi


# ----- SearXNG alias -----

if $install_searx; then

  grep -q "alias searxng" "$HOME/.bashrc" 2>/dev/null ||
  cat <<EOF >> "$HOME/.bashrc"

# • === searxng === •
alias searxng="cd ~/${SEARXNG_FOLDER_NAME} && source venv/bin/activate && python -m searx.webapp && cd && deactivate"
EOF

fi


# ----- OpenWebUI alias -----

if $install_webui; then

  grep -q "alias open-webui-venv" "$HOME/.bashrc" 2>/dev/null ||
  cat <<EOF >> "$HOME/.bashrc"

# • === open-webui === •
alias open-webui-venv="source ~/${OPENWEBUI_VENV}/bin/activate"
alias open-webui-run="source ~/${OPENWEBUI_VENV}/bin/activate && DATA_DIR=~/${OPENWEBUI_VENV}/data open-webui serve"
EOF

fi


# ----- OpenWebUI DATA_DIR -----

if $install_webui; then

  grep -q "DATA_DIR=.*${OPENWEBUI_VENV}/data" "$HOME/.bashrc" 2>/dev/null ||
  cat <<EOF >> "$HOME/.bashrc"

export DATA_DIR="\$HOME/${OPENWEBUI_VENV}/data"
EOF

fi


# ----- Combined launcher -----

if [[ $install_hermes == true &&
      $install_searx == true &&
      $install_webui == true ]]; then

  grep -q "hermsearxwebui()" "$HOME/.bashrc" 2>/dev/null ||
  cat <<EOF >> "$HOME/.bashrc"

# • === hermsearxwebui === •
hermsearxwebui() {
    echo "
╔═══════════════════════════════════════════╗
║       🚀 Starting HermSearxWebUI...       ║
╚═══════════════════════════════════════════╝
──────────────────────────────────────────────
• Starting...
• Preparing services...";

    echo "• Prepared services! ✅";
    sleep 1;
    echo "• Preparing tmux session with windows... ";

    tmux kill-session -t hermsearxwebui 2>/dev/null || true;

    tmux new-session -d -s hermsearxwebui -n "dashboard";
    tmux send-keys -t hermsearxwebui:dashboard "source ~/${HERMES_VENV}/venv/bin/activate && hermes dashboard" C-m;

    tmux new-window -t hermsearxwebui -n "gateway";
    tmux send-keys -t hermsearxwebui:gateway "source ~/${HERMES_VENV}/venv/bin/activate && hermes gateway" C-m;

    tmux new-window -t hermsearxwebui -n "searx";
    tmux send-keys -t hermsearxwebui:searx "cd ~/${SEARXNG_FOLDER_NAME} && source venv/bin/activate && python3 -m searx.webapp > searx.log 2>&1" C-m;

    tmux new-window -t hermsearxwebui -n "webui";
    tmux send-keys -t hermsearxwebui:webui "source ~/${OPENWEBUI_VENV}/bin/activate && DATA_DIR=~/${OPENWEBUI_VENV}/data open-webui serve" C-m;

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
      printf "\r• Launching in %b%d\e[0m " "\${colors[\$((5-i))]}" "\$i";
      ((countdown_num++));
      sleep 1;
    done;

    echo;
    sleep 1;

    tmux attach-session -t hermsearxwebui;

    echo "• Exited";
    echo "──────────────────────────────────────────────";
}
EOF

fi


echo

echo "${DGR}• Run: source ~/.bashrc${RST}"

echo "${DGR}• Run combined stack: hermsearxwebui${RST}"

echo "${GRN}• ✅ Complete${RST}"

echo "${YLW}─────────────────────────────────────────────────────────────────${RST}"

