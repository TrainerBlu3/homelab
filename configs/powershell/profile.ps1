# ===== Homelab shortcuts =====
$HL = "$HOME\Documents\GitHub\homelab"

function hl { Set-Location $HL }
function hldoc($name) { notepad "$HL\docs\$name.md" }

function hllog($box, $task, $notes) {
    $date = Get-Date -Format "yyyy-MM-dd"
    [IO.File]::AppendAllText("$HL\docs\maintenance.md", "| $date | $box | $task | $notes |`n")
}
function hllast($n = 10) { Get-Content "$HL\docs\maintenance.md" -Tail $n }

function hlstatus { hl; git status; git log --oneline -5 }
function hlpull   { hl; git pull }
function hlcheck { hl; $p = ((Get-Content .git\info\secret-patterns) -ne '') -join '|'; git grep -l -i --untracked -E "BEGIN .*PRIVATE KEY|WIREGUARD_PRIVATE_KEY=[^<]|$p" -- . ':!docs/lessons-learned.md' ':!.githooks/pre-commit' ':!configs/powershell/profile.ps1' }

function hlpush($msg) {
    if (-not $msg) { Write-Host "Usage: hlpush 'message'"; return }
    hl; git add docs/ configs/ .gitignore; git commit -m $msg; git push
}

function hlstacks {
    hl
    $stacks = ssh chadlab "ls /opt/stacks"
    foreach ($s in $stacks) {
        New-Item -ItemType Directory -Force "configs\$s" | Out-Null
        scp -q "chadlab:/opt/stacks/$s/compose.yaml" "configs\$s\compose.yml"
        $keys = ssh chadlab "test -f /opt/stacks/$s/.env && sed -E 's/=.*/=<secret>/' /opt/stacks/$s/.env"
        if ($keys) { Set-Content "configs\$s\.env.example" $keys }
    }
    git status --short configs/
}

function hldone {
    hlstacks
    Write-Host "`n--- Log entry ---"
    $box   = Read-Host "Box (e.g. chadlab, npclab, all)"
    $task  = Read-Host "Task (short)"
    $notes = Read-Host "What changed + WHY"
    $rb    = Read-Host "Rollback (how to undo, or 'n/a')"
    hllog $box $task "$notes. Rollback: $rb"
    $msg = Read-Host "Commit message (e.g. chadlab: pin nebula-sync)"
    hlpush $msg
}
