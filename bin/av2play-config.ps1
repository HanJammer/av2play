# av2play-config.ps1 - configure av2play boot defaults (run via av2play-config.bat)
#
# No arguments: finds AVFPLAY and AV2PLAY.XEX next to this script and offers
# an interactive menu for each (current values shown).
#
# Arguments:  av2play-config.ps1 <file> [UI] [SOUND] [PLAYBACK] [STORAGE]
#   UI:       auto | ui40 | ui80m3 | ui80m4
#   SOUND:    pokey | d280 | d300 | d500 | d580 | d600 | d700
#   PLAYBACK: playapac | play80m3 | play80m4
#   STORAGE:  auto | off
#   '.' leaves a slot unchanged ('-' does not survive PowerShell parameter
#   binding, so the dot is the official skip marker). Old value names
#   (ui80, std, m3, m4) are still accepted.
param(
    [string]$File = "",
    [string]$Ui = "",
    [string]$Sound = "",
    [string]$Playback = "",
    [string]$Storage = ""
)

$uiNames  = @("ui40", "ui80m3", "ui80m4")
$sndNames = @("pokey", "d280", "d300", "d500", "d580", "d600", "d700")
$pbNames  = @("playapac", "play80m3", "play80m4")
$stNames  = @("auto", "off")

function Find-Block([byte[]]$bytes) {
    $magic = [byte[]](0x41, 0x32, 0x43, 0x46)   # "A2CF"
    for ($i = 0; $i -le $bytes.Length - 4; $i++) {
        if ($bytes[$i] -eq $magic[0] -and $bytes[$i+1] -eq $magic[1] -and
            $bytes[$i+2] -eq $magic[2] -and $bytes[$i+3] -eq $magic[3]) { return $i }
    }
    return -1
}

function Show-Config([string]$path, [byte[]]$bytes, [int]$off) {
    $ui = if ($bytes[$off+5] -eq 255) { "auto" }
          elseif ($bytes[$off+5] -lt 3) { $uiNames[$bytes[$off+5]] }
          else { "invalid" }
    $snd = if ($bytes[$off+6] -lt 7) { $sndNames[$bytes[$off+6]] } else { "invalid" }
    $pb  = if ($bytes[$off+7] -lt 3) { $pbNames[$bytes[$off+7]] } else { "invalid" }
    $st  = if ($bytes[$off+8] -lt 2) { $stNames[$bytes[$off+8]] } else { "invalid" }
    Write-Host ""
    Write-Host "$(Split-Path $path -Leaf):"
    Write-Host "  1) UI mode      : $ui"
    Write-Host "  2) Sound device : $snd"
    Write-Host "  3) Playback     : $pb"
    Write-Host "  4) Storage      : $st"
}

function Pick-Value([string]$label, [string[]]$names, [bool]$withAuto) {
    Write-Host ""
    $idx = 1
    if ($withAuto) { Write-Host "  $idx) auto"; $idx++ }
    foreach ($n in $names) { Write-Host "  $idx) $n"; $idx++ }
    $c = Read-Host "$label - pick a number (ENTER = keep)"
    if ($c -eq "") { return -1 }
    $n = 0
    if (-not [int]::TryParse($c, [ref]$n)) { return -1 }
    if ($withAuto) {
        if ($n -eq 1) { return 255 }
        $n -= 1
    }
    if ($n -ge 1 -and $n -le $names.Length) { return $n - 1 }
    return -1
}

function Interactive([string]$path) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $off = Find-Block $bytes
    if ($off -lt 0) { Write-Host "$path : no A2CF config block - skipping"; return }
    while ($true) {
        Show-Config $path $bytes $off
        $c = Read-Host "Change which setting? (1-4, ENTER = done)"
        if ($c -eq "") { break }
        $v = -1
        switch ($c) {
            "1" { $v = Pick-Value "UI mode" $uiNames $true;  if ($v -ge 0) { $bytes[$off+5] = $v } }
            "2" { $v = Pick-Value "Sound device" $sndNames $false; if ($v -ge 0) { $bytes[$off+6] = $v } }
            "3" { $v = Pick-Value "Playback" $pbNames $false; if ($v -ge 0) { $bytes[$off+7] = $v } }
            "4" { $v = Pick-Value "Storage" $stNames $false; if ($v -ge 0) { $bytes[$off+8] = $v } }
        }
        if ($v -ge 0) { [System.IO.File]::WriteAllBytes($path, $bytes) ; Write-Host "  saved." }
    }
}

if ($File -eq "") {
    $dir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $found = 0
    foreach ($name in @("AVFPLAY", "AV2PLAY.XEX", "bin\AVFPLAY", "bin\av2play.xex")) {
        $p = Join-Path $dir $name
        if (Test-Path $p) { Interactive $p; $found++ }
    }
    if ($found -eq 0) {
        Write-Host "No AVFPLAY or AV2PLAY.XEX found next to this script."
        Write-Host "Usage: av2play-config <file> [UI] [SOUND] [PLAYBACK] [STORAGE]"
    }
    exit 0
}

# --- explicit file mode ---
if (-not (Test-Path $File)) { Write-Host "ERROR: file not found: $File"; exit 1 }
Write-Host "WARNING: patching bytes inside '$File'. Only use this on av2play"
Write-Host "         binaries (AVFPLAY / AV2PLAY.XEX); anything else will be damaged."
$bytes = [System.IO.File]::ReadAllBytes($File)
$off = Find-Block $bytes
if ($off -lt 0) { Write-Host "ERROR: no A2CF config block found - not an av2play binary?"; exit 1 }

if ($Ui -eq "" -and $Sound -eq "" -and $Playback -eq "" -and $Storage -eq "") {
    Interactive $File
    exit 0
}

$dirty = $false
switch ($Ui.ToLower()) {
    ""       { }
    "."      { }
    "-"      { }
    "auto"   { $bytes[$off+5] = 255; $dirty = $true }
    "ui40"   { $bytes[$off+5] = 0;   $dirty = $true }
    "ui80"   { $bytes[$off+5] = 1;   $dirty = $true }
    "ui80m3" { $bytes[$off+5] = 1;   $dirty = $true }
    "ui80m4" { $bytes[$off+5] = 2;   $dirty = $true }
    default  { Write-Host "ERROR: UI must be auto, ui40, ui80m3 or ui80m4"; exit 1 }
}
if ($Sound -ne "" -and $Sound -ne "-" -and $Sound -ne ".") {
    $i = [array]::IndexOf($sndNames, $Sound.ToLower())
    if ($i -lt 0) { Write-Host "ERROR: SOUND must be pokey or d280/d300/d500/d580/d600/d700"; exit 1 }
    $bytes[$off+6] = $i; $dirty = $true
}
switch ($Playback.ToLower()) {
    ""         { }
    "."        { }
    "-"        { }
    "playapac" { $bytes[$off+7] = 0; $dirty = $true }
    "std"      { $bytes[$off+7] = 0; $dirty = $true }
    "play80m3" { $bytes[$off+7] = 1; $dirty = $true }
    "m3"       { $bytes[$off+7] = 1; $dirty = $true }
    "play80m4" { $bytes[$off+7] = 2; $dirty = $true }
    "m4"       { $bytes[$off+7] = 2; $dirty = $true }
    default    { Write-Host "ERROR: PLAYBACK must be playapac, play80m3 or play80m4"; exit 1 }
}
switch ($Storage.ToLower()) {
    ""     { }
    "."    { }
    "-"    { }
    "auto" { $bytes[$off+8] = 0; $dirty = $true }
    "off"  { $bytes[$off+8] = 1; $dirty = $true }
    default { Write-Host "ERROR: STORAGE must be auto or off"; exit 1 }
}
if ($dirty) { [System.IO.File]::WriteAllBytes($File, $bytes) }
Show-Config $File $bytes $off
