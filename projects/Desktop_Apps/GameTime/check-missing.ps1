function Norm([string]$s) {
    $s = $s -replace '[-_]',' '
    $s = [regex]::Replace($s, '([a-z])([A-Z])', '$1 $2')
    $s = [regex]::Replace($s, '([a-zA-Z])(\d)', '$1 $2')
    $s = [regex]::Replace($s, '(\d)([a-zA-Z])', '$1 $2')
    $s = ($s -replace '\s+',' ').Trim().ToLower()
    $s = ($s -replace '[^a-z0-9 ]',' ' -replace '\s+',' ').Trim()
    return $s
}
$dbkeys = 'bayonetta origins cereza','bayonetta 2','bayonetta2','bayonetta','witcher 3','the witcher 3','elden ring nightreign','elden ring','oblivion remastered','elder scrolls iv oblivion remastered','elder scrolls iv','oblivion','mafia definitive edition','mafia','metal gear solid 3','metal gear solid master collection','metal gear solid','metal gear rising revengeance','metal gear rising','uncharted legacy of thieves','uncharted','south of midnight','cult of the lamb','yakuza 3 remastered','yakuza 3','dragon ball sparking zero','dragon ball xenoverse','dragon quest vii','legend of zelda echoes of wisdom','zelda echoes of wisdom','rogue prince of persia','prince of persia forgotten sands','prince of persia','ninja gaiden 2 black','ninja gaiden 2','ninjagaiden','sonic unleashed','wolfenstein ii the new colossus','wolfenstein','rise of the ronin','kenshi','crosscode','helldivers','indika','south park stick of truth','south park','asterigos curse of the stars','asterigos','a space for the unbound','aspacefortheunbound','arc runner','arcrunner','aeterna noctis','60 seconds reatomized','ashen','atelier yumia','banishers ghosts of new eden','banishers','creaks','curse of the dead gods','hellpoint','highland song','blazblue entropy effect','ultros','spiritfall','tails of iron','tailsofiron','slave zero x','eternights','the invincible','harold halibut','dustborn','no more heroes 3','no more heroes','severed steel','until then','bloons td 6','mindseye','despelote','bo path of the teal lotus','bopathoftheteal','in motion','inmot'

$games = Get-ChildItem 'E:\Games' -Directory | Select-Object -ExpandProperty Name
foreach ($game in $games) {
    $n = Norm $game
    $found = $false
    foreach ($key in ($dbkeys | Sort-Object { $_.Length } -Descending)) {
        $k = Norm $key
        if ($n.Contains($k) -or $k.Contains($n)) { $found=$true; break }
    }
    if (-not $found) { Write-Host "NO MATCH: $game  [norm: $n]" }
}
Write-Host "Done."
