#Requires -Version 5.1

# ----- Variables -----

$ESC = [char]27

$RED = "${ESC}[0;31m"
$YLW = "${ESC}[1;33m"
$GRN = "${ESC}[0;32m"
$BLU = "${ESC}[0;34m"
$CYN = "${ESC}[0;36m"
$GRY = "${ESC}[0;37m"
$DGR = "${ESC}[1;30m"
$WHT = "${ESC}[1;37m"
$RST = "${ESC}[0m"

$inst_list = @("Hermes Agent", "SearXNG", "OpenWebUI")

$install_hermes = $false
$install_searx = $false
$install_webui = $false

$HERMES_VENV = "hermes-agent"
$SEARXNG_FOLDER_NAME = "searxng"
$OPENWEBUI_VENV = "open-webui"

$WSL_DISTRO = "Ubuntu"


# ----- Functions -----

function validate_name {
    param(
        [string]$name
    )

    if ([string]::IsNullOrEmpty($name)) {
        return $true
    }

    if ($name -eq "." -or $name -eq "..") {
        return $false
    }

    if ($name -match '(^|[\\/])\.(\.?)([\\/]|$)') {
        return $false
    }

    return $name -match '^[A-Za-z0-9._-]+$'
}


function invoke_wsl {
    param(
        [string]$Command
    )

    & wsl.exe -d $WSL_DISTRO -- bash -lc $Command

    if ($LASTEXITCODE -ne 0) {
        throw "WSL command failed with exit code $LASTEXITCODE"
    }
}


function wsl_exists {
    $result = & wsl.exe -l -q 2>$null

    foreach ($line in $result) {
        $name = $line.Trim()

        if ($name -eq $WSL_DISTRO) {
            return $true
        }
    }

    return $false
}


function wsl_is_version_2 {
    $result = & wsl.exe -l -v 2>$null

    if ($LASTEXITCODE -ne 0) {
        return $false
    }

    foreach ($line in $result) {

        if ($line -match 'Ubuntu\s+.*\s+2\s*$') {
            return $true
        }
    }

    return $false
}


function clear_screen {
    [Console]::Clear()
    [Console]::SetCursorPosition(0, 0)
}


function pause_short {
    Start-Sleep -Milliseconds 500
}


function run_checkbox_menu {

    # Kept internally so the original selection UI remains available,
    # but everything is contained in this single file.

    $options = $inst_list
    $selected = @(0, 0, 0)
    $cursor = 0

    [Console]::CursorVisible = $false

    function draw_menu {

        clear_screen

        Write-Host ""

        Write-Host "${BLU}• ───────────────────────────────────────────────────── •"
        Write-Host "${CYN}• Use ↑ ↓ to move | SPACE to toggle | ENTER to confirm  •"
        Write-Host "${BLU}• ───────────────────────────────────────────────────── •"
        Write-Host "${BLU}• ───────────────────────────────────────────────────── •"

        for ($i = 0; $i -lt $options.Count; $i++) {

            if ($i -eq $cursor) {
                $prefix = "${CYN}      >"
            }
            else {
                $prefix = "${CYN}       "
            }

            if ($selected[$i] -eq 1) {
                $box = "${CYN}[x]"
            }
            else {
                $box = "${CYN}[ ]"
            }

            Write-Host "$prefix $box $($options[$i])"
        }

        Write-Host "${BLU}• ───────────────────────────────────────────────────── •"
    }

    draw_menu

    try {

        while ($true) {

            $key = [Console]::ReadKey($true)

            switch ($key.Key) {

                "UpArrow" {

                    $cursor--

                    if ($cursor -lt 0) {
                        $cursor = 0
                    }
                }

                "DownArrow" {

                    $cursor++

                    if ($cursor -ge $options.Count) {
                        $cursor = $options.Count - 1
                    }
                }

                "Spacebar" {

                    if ($selected[$cursor] -eq 1) {
                        $selected[$cursor] = 0
                    }
                    else {
                        $selected[$cursor] = 1
                    }
                }

                "Enter" {
                    break
                }
            }

            draw_menu
        }
    }
    finally {
        [Console]::CursorVisible = $true
    }

    $result = @()

    for ($i = 0; $i -lt $options.Count; $i++) {

        if ($selected[$i] -eq 1) {
            $result += $options[$i]
        }
    }

    return $result
}


# ----- Installation -----

clear_screen

Write-Host ""

Write-Host "║${BLU}    ██████╗  █████╗ ██╗    ██╗███╗   ██╗        ${CYN}║"
Write-Host "║${BLU}    ██╔══██╗██╔══██╗██║    ██║████╗  ██║        ${CYN}║"
Write-Host "║${BLU}    ██║  ██║███████║██║ █╗ ██║██╔██╗ ██║        ${CYN}║"
Write-Host "║${BLU}    ██║  ██║██╔══██║██║███╗██║██║╚██╗██║        ${CYN}║"
Write-Host "║${BLU}    ██████╔╝██║  ██║╚███╔███╔╝██║ ╚████║        ${CYN}║"
Write-Host "║${BLU}    ╚═════╝ ╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═══╝        ${CYN}║"
Write-Host "║${BLU}    ███████╗ █████╗ ██╗     ██╗     ███████╗    ${CYN}║"
Write-Host "║${BLU}    ██╔════╝██╔══██╗██║     ██║     ╚══███╔╝    ${CYN}║"
Write-Host "║${BLU}    █████╗  ███████║██║     ██║       ███╔╝     ${CYN}║"
Write-Host "║${BLU}    ██╔══╝  ██╔══██║██║     ██║      ███╔╝      ${CYN}║"
Write-Host "║${BLU}    ██║     ██║  ██║███████╗███████╗███████╗    ${CYN}║"
Write-Host "║${BLU}    ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝    ${CYN}║"

Write-Host "${CYN}"

Write-Host "╔═══════════════════════════════════════════════════════════════╗"
Write-Host "║${GRY}  🚀 Starting Installation of Hermes, SearXNG and OpenWebUI... ${CYN}║"
Write-Host "╚═══════════════════════════════════════════════════════════════╝"

Write-Host "${YLW}─────────────────────────────────────────────────────────────────"
Write-Host "${YLW}• Detecting Windows environment... ${RST}"

Start-Sleep -Seconds 3


# ----- Windows / WSL2 detection -----

if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {

    Write-Host "${RED}• ERROR: WSL is not installed!${RST}"
    Write-Host "${RED}• Please install WSL2 first: wsl --install${RST}"
    Write-Host "${YLW}─────────────────────────────────────────────────────────────────${RST}"

    exit 1
}

Write-Host "${GRN}• ✅ Windows environment detected!${RST}"

Start-Sleep -Milliseconds 500

Write-Host "${YLW}• Detecting WSL2 environment...${RST}"

Start-Sleep -Seconds 1


# ----- WSL installation -----

if (-not (wsl_exists)) {

    Write-Host "${YLW}• Installing Ubuntu from WSL...${RST}"

    & wsl.exe --install -d Ubuntu

    if ($LASTEXITCODE -ne 0) {

        Write-Host "${RED}• ERROR: Failed to install Ubuntu through WSL.${RST}"
        exit 1
    }

    Write-Host "${YLW}• Ubuntu installation may require a Windows restart.${RST}"
    Write-Host "${YLW}• After restarting Windows, run this installer again.${RST}"

    exit 0
}


# ----- WSL2 verification -----

if (-not (wsl_is_version_2)) {

    Write-Host "${RED}• ERROR: Ubuntu is not running under WSL2!${RST}"
    Write-Host "${YLW}• Converting Ubuntu to WSL2...${RST}"

    & wsl.exe --set-version $WSL_DISTRO 2

    if ($LASTEXITCODE -ne 0) {

        Write-Host "${RED}• ERROR: Failed to convert Ubuntu to WSL2.${RST}"
        Write-Host "${YLW}• Run manually: wsl --set-version Ubuntu 2${RST}"

        exit 1
    }
}

Write-Host "${GRN}• ✅ WSL2 environment detected!${RST}"

Start-Sleep -Milliseconds 500

Write-Host "${YLW}• Detecting Ubuntu environment...${RST}"

Start-Sleep -Seconds 1

Write-Host "${GRN}• ✅ Ubuntu environment detected!${RST}"

Start-Sleep -Seconds 2


# ----- Selection -----

$install_all = Read-Host "${YLW}• Install all (Hermes Agent + SearXNG + OpenWebUI)? [y/N]: ${RST}"

Start-Sleep -Seconds 1

Write-Host ""

if ($install_all -match '^[Yy]$') {

    $install_hermes = $true
    $install_searx = $true
    $install_webui = $true
}
else {

    if (
        $install_all -notmatch '^[Nn]$' -and
        -not [string]::IsNullOrEmpty($install_all)
    ) {

        Write-Host "${RED}• WARNING: Not a valid option. Defaulting to NO...${RST}"

        Start-Sleep -Milliseconds 500
    }

    Write-Host "${YLW}• Please select which to install from the options provided:${RST}"

    Start-Sleep -Seconds 2

    $selected_installations_list = run_checkbox_menu

    Write-Host "${YLW}• Selected:${RST}"

    foreach ($item in $selected_installations_list) {
        Write-Host "${YLW}    ✓ $item${RST}"
    }

    Start-Sleep -Seconds 2

    foreach ($item in $selected_installations_list) {

        switch ($item) {

            "Hermes Agent" {
                $install_hermes = $true
            }

            "SearXNG" {
                $install_searx = $true
            }

            "OpenWebUI" {
                $install_webui = $true
            }
        }
    }
}


if (
    -not $install_hermes -and
    -not $install_searx -and
    -not $install_webui
) {

    Write-Host "${RED}• ERROR: Please select at least 1 option to install.${RST}"

    exit 0
}


Write-Host ""


# ----- Hermes name -----

if ($install_hermes) {

    $input = Read-Host "${YLW}• What name would you give for Hermes Agent's venv? It will be created in your home directory (~). Leave blank for default. [Default: ${HERMES_VENV}]: ${RST}"

    if (-not [string]::IsNullOrEmpty($input)) {

        $input = $input -replace '^~[/\\]', ''
        $input = $input.TrimEnd('/', '\')
    }

    if (-not (validate_name $input)) {

        Write-Host "${RED}• Invalid name. Use only letters, numbers, dots (.), underscores (_), and hyphens (-).${RST}"

        exit 1
    }

    $target_name = if ([string]::IsNullOrEmpty($input)) {
        $HERMES_VENV
    }
    else {
        $input
    }

    $check = & wsl.exe -d $WSL_DISTRO -- bash -lc "test ! -e ~/$target_name"

    if ($LASTEXITCODE -ne 0) {

        Write-Host "${RED}• Hermes Agent's venv path already exists: ~/$target_name${RST}"

        exit 1
    }

    $HERMES_VENV = $target_name
}


# ----- SearXNG name -----

if ($install_searx) {

    $input = Read-Host "${YLW}• What name would you give for SearXNG's folder name? It will be created in your home directory (~). Leave blank for default. [Default: ${SEARXNG_FOLDER_NAME}]: ${RST}"

    if (-not [string]::IsNullOrEmpty($input)) {

        $input = $input -replace '^~[/\\]', ''
        $input = $input.TrimEnd('/', '\')
    }

    if (-not (validate_name $input)) {

        Write-Host "${RED}• Invalid name. Use only letters, numbers, dots (.), underscores (_), and hyphens (-).${RST}"

        exit 1
    }

    $target_name = if ([string]::IsNullOrEmpty($input)) {
        $SEARXNG_FOLDER_NAME
    }
    else {
        $input
    }

    $check = & wsl.exe -d $WSL_DISTRO -- bash -lc "test ! -e ~/$target_name"

    if ($LASTEXITCODE -ne 0) {

        Write-Host "${RED}• SearXNG folder already exists: ~/$target_name${RST}"

        exit 1
    }

    $SEARXNG_FOLDER_NAME = $target_name
}


# ----- OpenWebUI name -----

if ($install_webui) {

    $input = Read-Host "${YLW}• What name would you give for OpenWebUI's venv? It will be created in your home directory (~). Leave blank for default. [Default: ${OPENWEBUI_VENV}]: ${RST}"

    if (-not [string]::IsNullOrEmpty($input)) {

        $input = $input -replace '^~[/\\]', ''
        $input = $input.TrimEnd('/', '\')
    }

    if (-not (validate_name $input)) {

        Write-Host "${RED}• Invalid name. Use only letters, numbers, dots (.), underscores (_), and hyphens (-).${RST}"

        exit 1
    }

    $target_name = if ([string]::IsNullOrEmpty($input)) {
        $OPENWEBUI_VENV
    }
    else {
        $input
    }

    $check = & wsl.exe -d $WSL_DISTRO -- bash -lc "test ! -e ~/$target_name"

    if ($LASTEXITCODE -ne 0) {

        Write-Host "${RED}• OpenWebUI venv path already exists: ~/$target_name${RST}"

        exit 1
    }

    $OPENWEBUI_VENV = $target_name
}


Write-Host ""

Write-Host "${GRN}• ✅ Done. You can safely leave this running in the background. Installation may take some time.${RST}"

Write-Host ""

Start-Sleep -Seconds 3

Write-Host "${YLW}• Starting installation process..."
Write-Host "${GRN}• ──────────────────────────────────────────────${RST}"

Start-Sleep -Seconds 1


# ----- Updating Ubuntu -----

Write-Host ""
Write-Host "${YLW}• Updating Ubuntu..."
Write-Host "${BLU}• ─────────────────────────────────${RST}"

invoke_wsl "sudo apt update -y"

Write-Host "${BLU}• ─────────────────────────────────${RST}"

Write-Host ""

Write-Host "${YLW}• Upgrading Ubuntu packages..."
Write-Host "${BLU}• ─────────────────────────────────${RST}"

invoke_wsl "sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y"

Write-Host "${BLU}• ─────────────────────────────────${RST}"

Write-Host ""


# ----- Common Ubuntu packages -----

Write-Host "${YLW}• Installing Ubuntu packages..."
Write-Host "${BLU}• ─────────────────────────────────${RST}"

invoke_wsl @"
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    ca-certificates \
    curl \
    git \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    clang \
    rustc \
    cargo \
    libffi-dev \
    libssl-dev \
    libxml2-dev \
    libxslt1-dev \
    nodejs \
    npm \
    ripgrep \
    ffmpeg \
    tmux
"@

Write-Host "${BLU}• ─────────────────────────────────${RST}"

Write-Host ""


# ----- Hermes Agent -----

if ($install_hermes) {

    Write-Host ""
    Write-Host "${YLW}• Installing Hermes Agent..."
    Write-Host "${BLU}• ─────────────────────────────────${RST}"

    Write-Host "${YLW}• Installing required packages...${RST}"

    invoke_wsl @"
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    ca-certificates \
    curl \
    git \
    python3 \
    python3-venv \
    python3-dev \
    build-essential \
    libffi-dev \
    libssl-dev \
    nodejs \
    npm \
    ripgrep \
    ffmpeg
"@

    Write-Host "${YLW}• Now installing Hermes Agent...${RST}"

    Write-Host "${YLW}• Running official Hermes installer...${RST}"

    invoke_wsl @"
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
"@

    Write-Host "${YLW}• Hermes installer completed.${RST}"

    Write-Host "${GRN}• ✅ Done installing Hermes Agent!${RST}"
    Write-Host "${BLU}• ─────────────────────────────────${RST}"
    Write-Host ""
}


# ----- SearXNG -----

if ($install_searx) {

    Write-Host ""
    Write-Host "${YLW}• Installing SearXNG..."
    Write-Host "${BLU}• ─────────────────────────────────${RST}"

    Write-Host "${YLW}• Installing required packages...${RST}"

    invoke_wsl @"
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    git \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    python-is-python3 \
    libxml2-dev \
    libxslt1-dev \
    libffi-dev \
    libssl-dev \
    zlib1g-dev \
    build-essential
"@

    Write-Host "${YLW}• Cloning GitHub Repository${RST}"

    invoke_wsl "git clone https://github.com/searxng/searxng.git ~/$SEARXNG_FOLDER_NAME"

    invoke_wsl "cd ~/$SEARXNG_FOLDER_NAME && cp searx/settings.yml settings.yml"

    Write-Host "${YLW}• Creating venv...${RST}"

    invoke_wsl "python3 -m venv ~/$SEARXNG_FOLDER_NAME/venv"

    Write-Host "${YLW}• Installing pip packages... ${RST}"

    invoke_wsl "source ~/$SEARXNG_FOLDER_NAME/venv/bin/activate && python -m pip install -U pip setuptools wheel && pip install --use-pep517 --no-build-isolation -e . && deactivate"

    Write-Host "${GRN}• ✅ Done installing SearXNG!${RST}"
    Write-Host "${BLU}• ─────────────────────────────────${RST}"
    Write-Host ""
}


# ----- OpenWebUI -----

if ($install_webui) {

    Write-Host ""
    Write-Host "${YLW}• Installing OpenWebUI..."
    Write-Host "${BLU}• ─────────────────────────────────${RST}"

    Write-Host "${YLW}• Installing required packages... ${RST}"

    invoke_wsl @"
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    cmake \
    git
"@

    Write-Host "${YLW}• Creating venv...${RST}"

    invoke_wsl "python3 -m venv ~/$OPENWEBUI_VENV"

    Write-Host "${YLW}• Installing pip packages... ${RST}"

    invoke_wsl "source ~/$OPENWEBUI_VENV/bin/activate && python -m pip install -U pip setuptools wheel && pip install open-webui && deactivate"

    Write-Host "${YLW}• Setting OpenWebUI data directory to ~/$OPENWEBUI_VENV/data"

    invoke_wsl "mkdir -p ~/$OPENWEBUI_VENV/data"

    invoke_wsl @"
grep -q 'HermSearxWebUI' ~/.bashrc || cat >> ~/.bashrc <<'EOF'

# • ===== HermSearxWebUI ===== •
# • === open-webui === •
export DATA_DIR="\$HOME/$OPENWEBUI_VENV/data"
EOF
"@

    Write-Host "${GRN}• ✅ Done installing OpenWebUI!"
    Write-Host "${BLU}• ─────────────────────────────────${RST}"
    Write-Host ""
}


Write-Host "${GRN}• ✅ INSTALLATION ENDED!!!"
Write-Host "${GRN}• ──────────────────────────────────────────────${RST}"

Start-Sleep -Seconds 1

Write-Host ""
Write-Host "${YLW}• Putting aliases and functions into ~/.bashrc..."


# ----- .bashrc base -----

invoke_wsl @"
grep -q '# • ===== HermSearxWebUI ===== •' ~/.bashrc || cat >> ~/.bashrc <<'EOF'
# • ===== HermSearxWebUI ===== •
EOF
"@


# ----- Hermes alias -----

if ($install_hermes) {

    invoke_wsl @"
grep -q 'alias hermes-venv' ~/.bashrc || cat >> ~/.bashrc <<'EOF'
# • === hermes-agent === •
alias hermes-venv="source ~/$HERMES_VENV/venv/bin/activate"
EOF
"@
}


# ----- SearXNG alias -----

if ($install_searx) {

    invoke_wsl @"
grep -q 'alias searxng' ~/.bashrc || cat >> ~/.bashrc <<'EOF'
# • === searxng === •
alias searxng="cd ~/$SEARXNG_FOLDER_NAME && source venv/bin/activate && python -m searx.webapp && cd && deactivate"
EOF
"@
}


# ----- OpenWebUI alias -----

if ($install_webui) {

    invoke_wsl @"
grep -q 'alias open-webui-venv' ~/.bashrc || cat >> ~/.bashrc <<'EOF'
# • === open-webui === •
alias open-webui-venv="source ~/$OPENWEBUI_VENV/bin/activate"
alias open-webui-run="source ~/$OPENWEBUI_VENV/bin/activate && open-webui serve"
EOF
"@
}


# ----- Combined launcher -----

if (
    $install_hermes -and
    $install_searx -and
    $install_webui
) {

    invoke_wsl @"
grep -q 'hermsearxwebui()' ~/.bashrc || cat >> ~/.bashrc <<'EOF'
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
    tmux send-keys -t hermsearxwebui:searx "cd ~/$SEARXNG_FOLDER_NAME && source venv/bin/activate && python3 -m searx.webapp > searx.log 2>&1" C-m;

    tmux new-window -t hermsearxwebui -n "webui";
    tmux send-keys -t hermsearxwebui:webui "source ~/$OPENWEBUI_VENV/bin/activate && open-webui serve" C-m;

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

    
