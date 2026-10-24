function hllog($box, $task, $notes) {
    $date = Get-Date -Format "yyyy-MM-dd"
    Add-Content "$HOME\Documents\GitHub\homelab\docs\maintenance.md" "| $date | $box | $task | $notes |"
}
function hl { Set-Location "$HOME\Documents\GitHub\homelab" }
function hldoc($name) { notepad "$HOME\Documents\GitHub\homelab\docs\$name.md" }
