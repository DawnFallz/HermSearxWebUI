#!/bin/bash

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

BREW_PREFIX=""
PYTHON_BIN=""


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


detect_macos() {
  [[ "$(uname -s)" == "Darwin" ]]
}


detect_brew() {
  command -v brew >/dev/null 2>&1
}


setup_homebrew() {

  if detect_brew; then
    BREW_PREFIX="$(brew --prefix)"
    return 0
  fi

  echo "${YLW}• Homebrew was not detected.${RST}"
  echo "${YLW}• Installing Homebrew...${RST}"

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if ! detect_brew; then
    echo "${RED}• ERROR: Homebrew installation failed.${RST}"
    exit 1
  fi

  BREW_PREFIX="$(brew --prefix)"

  if [[ -x "${BREW_PREFIX}/bin/brew" ]]; then
    eval "$("${BREW_PREFIX}/bin/brew" shellenv)"
  fi
}


setup_xcode_tools() {

  if xcode-select -p >/dev/null 2>&1; then
    return 0
  fi

  echo "${YLW}• Xcode Command Line Tools are not detected.${RST}"
  echo "${YLW}• Starting Apple's Command Line Tools installer...${RST}"

  xcode-select --install 2>/dev/null || true

  echo
  echo "${YLW}• Please complete the Command Line Tools installation window.${RST}"
  echo "${YLW}• Then run this installer again.${RST}"
  exit 0
}


setup_python() {

  if [[ -x "${BREW_PREFIX}/bin/python3.12" ]]; then
    PYTHON_BIN="${BREW_PREFIX}/bin/python3.12"
    return 0
  fi

  echo "${YLW}• Installing Python 3.12...${RST}"
  brew install python@3.12

  if [[ ! -x "${BREW_PREFIX}/bin/python3.12" ]]; then
    echo "${RED}• ERROR: Python 3.12 installation failed.${RST}"
    exit 1
  fi

  PYTHON_BIN="${BREW_PREFIX}/bin/python3.12"
}


install_common_packages() {

  echo "${YLW}• Installing macOS packages...${RST}"
  echo "${BLU}• ─────────────────────────────────${RST}"

  brew install \
    git \
    rust \
    cmake \
    libxml2 \
    libxslt \
    libffi \
    openssl@3 \
    zlib \
    pkgconf \
    ripgrep \
    ffmpeg \
    tmux

  echo "${BLU}• ─────────────────────────────────${RST}"
}


setup_build_environment() {

  export PATH="${BREW_PREFIX}/opt/python@3.12/libexec/bin:${BREW_PREFIX}/bin:${PATH}"

  export LDFLAGS="-L${BREW_PREFIX}/opt/libxml2/lib -L${BREW_PREFIX}/opt/libxslt/lib -L${BREW_PREFIX}/opt/libffi/lib -L${BREW_PREFIX}/opt/openssl@3/lib -L${BREW_PREFIX}/opt/zlib/lib ${LDFLAGS:-}"

  export CPPFLAGS="-I${BREW_PREFIX}/opt/libxml2/include -I${BREW_PREFIX}/opt/libxslt/include -I${BREW_PREFIX}/opt/libffi/include -I${BREW_PREFIX}/opt/openssl@3/include -I${BREW_PREFIX}/opt/zlib/include ${CPPFLAGS:-}"

  export PKG_CONFIG_PATH="${BREW_PREFIX}/opt/libxml2/lib/pkgconfig:${BREW_PREFIX}/opt/libxslt/lib/pkgconfig:${BREW_PREFIX}/opt/libffi/lib/pkgconfig:${BREW_PREFIX}/opt/openssl@3/lib/pkgconfig:${BREW_PREFIX}/opt/zlib/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
}


# ----- Installation -----

clear

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
echo "${YLW}• Detecting macOS environment... ${RST}"

sleep 3


# ----- macOS detection -----

if ! detect_macos; then
  echo "${RED}• ERROR: Not in macOS environment!${RST}"
  echo "${RED}• Please run this installer on macOS.${RST}"
  echo "${YLW}─────────────────────────────────────────────────────────────────${RST}"
  exit 1
fi

echo "${GRN}• ✅ macOS environment detected!${RST}"
sleep 0.5

echo "${YLW}• Detecting Homebrew...${RST}"
sleep 1

setup_homebrew

echo "${GRN}• ✅ Homebrew detected!${RST}"

sleep 1

echo "${YLW}• Detecting Xcode Command Line Tools...${RST}"
setup_xcode_tools

echo "${GRN}• ✅ Xcode Command Line Tools detected!${RST}"

sleep 2


# ----- Selection -----

read -rp "${YLW}• Install all (Hermes Agent + SearXNG + OpenWebUI)? [y/N]: ${RST}" install_all

sleep 1
echo

if [[ "$install_all" =~ ^[Yy]$ ]]; then

  install_hermes=true
  install_searx=true
  install_webui=true

else

  if [[ ! "$install_all" == [Nn] && -n "$install_all" ]]; then
    echo "${RED}• WARNING: Not a valid option. Defaulting to NO...${RST}"
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
    echo "${RED}• Hermes Agent's path already exists: $HOME/$target_name${RST}"
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


# ----- Homebrew update -----

echo
echo "${YLW}• Updating macOS package manager... "
echo "${BLU}• ─────────────────────────────────${RST}"

brew update

echo "${BLU}• ─────────────────────────────────${RST}"

echo
echo "${YLW}• Upgrading macOS packages..."
echo "${BLU}• ─────────────────────────────────${RST}"

brew upgrade

echo "${BLU}• ─────────────────────────────────${RST}"

echo


# ----- Common packages -----

install_common_packages

setup_python
setup_build_environment


# ----- Hermes Agent -----

if $install_hermes; then

  echo
  echo "${YLW}• Installing Hermes Agent..."
  echo "${BLU}• ─────────────────────────────────${RST}"

  echo "${YLW}• Installing required packages...${RST}"

  echo "${YLW}• Hermes Agent's official installer will handle its own runtime dependencies.${RST}"

  echo "${YLW}• Now installing Hermes Agent...${RST}"

  # Hermes officially supports macOS through this installer.
  # HERMES_HOME is used so the requested custom name remains meaningful.
  export HERMES_HOME="$HOME/${HERMES_VENV}"

  curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

  if ! command -v hermes >/dev/null 2>&1; then

    if [[ -x "$HOME/.local/bin/hermes" ]]; then
      export PATH="$HOME/.local/bin:$PATH"
    fi

  fi

  if ! command -v hermes >/dev/null 2>&1; then
    echo "${RED}• ERROR: Hermes Agent installation completed but 'hermes' was not found in PATH.${RST}"
    echo "${YLW}• Try opening a new Terminal window and running: hermes${RST}"
    exit 1
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

  brew install \
    python@3.12 \
    git \
    rust \
    cmake \
    libxml2 \
    libxslt \
    libffi \
    openssl@3 \
    zlib \
    pkgconf

  setup_python
  setup_build_environment

  echo "${YLW}• Cloning GitHub Repository${RST}"

  git clone https://github.com/searxng/searxng.git "$HOME/${SEARXNG_FOLDER_NAME}"

  cd "$HOME/${SEARXNG_FOLDER_NAME}" || exit 1

  cp searx/settings.yml settings.yml

  echo "${YLW}• Creating venv...${RST}"

  "$PYTHON_BIN" -m venv "$HOME/${SEARXNG_FOLDER_NAME}/venv"

  source "$HOME/${SEARXNG_FOLDER_NAME}/venv/bin/activate"

  echo "${YLW}• Installing pip packages... ${RST}"

  python -m pip install -U pip setuptools wheel

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

  cd "$HOME" || exit 1

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

  brew install python@3.12

  setup_python

  echo "${YLW}• Creating venv...${RST}"

  "$PYTHON_BIN" -m venv "$HOME/${OPENWEBUI_VENV}"

  echo "${YLW}• Installing pip packages... ${RST}"

  source "$HOME/${OPENWEBUI_VENV}/bin/activate"

  python -m pip install -U pip setuptools wheel

  python -m pip install open-webui

  deactivate

  echo "${YLW}• Setting OpenWebUI data directory to ~/${OPENWEBUI_VENV}/data"

  mkdir -p "$HOME/${OPENWEBUI_VENV}/data"

  echo "${GRN}• ✅ Done installing OpenWebUI!${RST}"
  echo "${BLU}• ─────────────────────────────────${RST}"
  echo

fi


echo "${GRN}• ✅ INSTALLATION ENDED!!!"
echo "${GRN}• ──────────────────────────────────────────────${RST}"

sleep 1

echo
echo "${YLW}• Putting aliases and functions into shell configuration..."


# ----- Shell configuration -----

SHELL_CONFIG="$HOME/.zshrc"

if [[ ! -f "$SHELL_CONFIG" ]]; then
  touch "$SHELL_CONFIG"
fi


grep -q "# • ===== HermSearxWebUI ===== •" "$SHELL_CONFIG" || cat <<EOF >> "$SHELL_CONFIG"

# • ===== HermSearxWebUI ===== •
EOF


# ----- Hermes alias -----

if $install_hermes; then

  grep -q "alias hermes-venv" "$SHELL_CONFIG" || cat <<EOF >> "$SHELL_CONFIG"

# • === hermes-agent === •
alias hermes-venv='export HERMES_HOME="\$HOME/${HERMES_VENV}"'
EOF

fi


# ----- SearXNG alias -----

if $install_searx; then

  grep -q "alias searxng" "$SHELL_CONFIG" || cat <<EOF >> "$SHELL_CONFIG"

# • === searxng === •
alias searxng='cd "\$HOME/${SEARXNG_FOLDER_NAME}" && source venv/bin/activate && python -m searx.webapp && cd "\$HOME" && deactivate'
EOF

fi


# ----- OpenWebUI alias -----

if $install_webui; then

  grep -q "alias open-webui-venv" "$SHELL_CONFIG" || cat <<EOF >> "$SHELL_CONFIG"

# • === open-webui === •
alias open-webui-venv='source "\$HOME/${OPENWEBUI_VENV}/bin/activate"'
alias open-webui-run='cd "\$HOME/${OPENWEBUI_VENV}" && DATA_DIR="\$HOME/${OPENWEBUI_VENV}/data" source bin/activate && DATA_DIR="\$HOME/${OPENWEBUI_VENV}/data" open-webui serve'
EOF

fi


# ----- Combined launcher -----

if [[ $install_hermes == true &&
      $install_searx == true &&
      $install_webui == true ]]; then

  grep -q "hermsearxwebui()" "$SHELL_CONFIG" || cat <<EOF >> "$SHELL_CONFIG"

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
    tmux send-keys -t hermsearxwebui:dashboard "hermes dashboard" C-m;

    tmux new-window -t hermsearxwebui -n "gateway";
    tmux send-keys -t hermsearxwebui:gateway "hermes gateway" C-m;

    tmux new-window -t hermsearxwebui -n "searx";
    tmux send-keys -t hermsearxwebui:searx "cd ~/${SEARXNG_FOLDER_NAME} && source venv/bin/activate && python3 -m searx.webapp > searx.log 2>&1" C-m;

    tmux new-window -t hermsearxwebui -n "webui";
    tmux send-keys -t hermsearxwebui:webui "cd ~/${OPENWEBUI_VENV} && source bin/activate && DATA_DIR=~/\${OPENWEBUI_VENV}/data open-webui serve" C-m;

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


# ----- Make Hermes available to future shells -----

if $install_hermes; then

  grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$SHELL_CONFIG" || cat <<'EOF' >> "$SHELL_CONFIG"

# • === Hermes PATH === •
export PATH="$HOME/.local/bin:$PATH"
EOF

fi


echo ""

echo "${DGR}• Run: source ~/.zshrc${RST}"

if [[ $install_hermes == true &&
      $install_searx == true &&
      $install_webui == true ]]; then

  echo "${DGR}• Run combined stack: hermsearxwebui${RST}"

fi

echo "${GRN}• ✅ Complete${RST}"

echo "${YLW}─────────────────────────────────────────────────────────────────${RST}"

