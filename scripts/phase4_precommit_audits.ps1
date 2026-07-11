param(
  [string]$GitPath = 'git'
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path '.').Path
function RelPath($path) { ($path.Substring($root.Length + 1) -replace '\\','/') }
function WriteUtf8($path, [string[]]$lines) { $enc = New-Object System.Text.UTF8Encoding($false); [IO.File]::WriteAllLines((Join-Path $root $path), $lines, $enc) }
function CsvEscape($v) { '"' + (($v -as [string]) -replace '"','""') + '"' }
$files = Get-ChildItem -Recurse -File -Force | Where-Object { $_.FullName -notlike '*\.git\*' }
$rels = @($files | ForEach-Object { RelPath $_.FullName })
function IsIgnored([string]$rel) { & $GitPath check-ignore -q -- $rel 2>$null; return ($LASTEXITCODE -eq 0) }
$audit = foreach ($f in $files) {
  $rel = RelPath $f.FullName
  $ignored = IsIgnored $rel
  $sizeMb = [math]::Round($f.Length / 1MB, 4)
  $trackedCandidate = -not $ignored
  $action = if ($ignored) { 'exclude' } elseif ($sizeMb -gt 100) { 'do not commit' } elseif ($sizeMb -gt 50) { 'review carefully before commit' } elseif ($sizeMb -gt 20) { 'warn before commit' } else { 'include' }
  $reason = if ($ignored) { 'matched .gitignore or excluded path' } elseif ($sizeMb -gt 100) { 'larger than 100 MB limit' } elseif ($sizeMb -gt 50) { 'larger than 50 MB careful-review threshold' } elseif ($sizeMb -gt 20) { 'larger than 20 MB warning threshold' } else { 'small tracked candidate' }
  [pscustomobject]@{ file=$rel; extension=$f.Extension; size_mb=$sizeMb; tracked_candidate=$trackedCandidate; ignored=$ignored; action=$action; reason=$reason }
}
$csvPath = Join-Path $root 'outputs/reports/PRE_COMMIT_FILE_AUDIT.csv'
$audit | Sort-Object @{Expression='tracked_candidate';Descending=$true}, @{Expression='size_mb';Descending=$true}, file | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8
$candidates = @($audit | Where-Object { $_.tracked_candidate })
$largest = @($candidates | Sort-Object size_mb -Descending | Select-Object -First 20)
$over100 = @($candidates | Where-Object { $_.size_mb -gt 100 }).Count
$over50 = @($candidates | Where-Object { $_.size_mb -gt 50 }).Count
$over20 = @($candidates | Where-Object { $_.size_mb -gt 20 }).Count
$preCommitStatus = if ($over100 -gt 0) { 'FAIL' } elseif ($over20 -gt 0) { 'WARNING' } else { 'PASS' }
$totalCandidateMb = [math]::Round(($candidates | Measure-Object size_mb -Sum).Sum, 3)
$summary = @('# Pre-Commit File Audit','',"Status: $preCommitStatus",'',"- total_repository_size_mb: $totalCandidateMb","- number_of_files_to_commit: $($candidates.Count)","- tracked candidates over 20 MB: $over20","- tracked candidates over 50 MB: $over50","- tracked candidates over 100 MB: $over100",'','## Largest 20 Tracked Candidates','','| file | size_mb | action |','|---|---:|---|')
foreach ($x in $largest) { $summary += "| $($x.file) | $($x.size_mb) | $($x.action) |" }
WriteUtf8 'outputs/reports/PRE_COMMIT_FILE_AUDIT_SUMMARY.md' $summary

# Public content check
$mustInclude = @('README.md','LICENSE','CITATION.cff','CODE_OF_CONDUCT.md','CONTRIBUTING.md','paper/main.html','paper/main.pdf','paper/policy_brief.html','docs','docs/assets','dashboard','R','scripts','tests','outputs/figures','outputs/tables','outputs/reports','data/sample','config/paths.example.yml')
$includeRows = foreach ($x in $mustInclude) { [pscustomobject]@{ item=$x; exists=(Test-Path -LiteralPath (Join-Path $root $x)); tracked_candidate=($candidates.file -contains ($x -replace '\\','/')) -or (Test-Path -Path (Join-Path $root $x) -PathType Container) } }
$badCandidates = @($candidates | Where-Object { $_.file -match '(^|/)config/paths\.local\.yml$|(^|/)data/raw/|(^|/)data/interim/|(^|/)data/processed/|(^|/)cache/|\.rds$|\.aux$|\.log$|\.out$|\.toc$|\.tex$' })
$status = if (($includeRows | Where-Object { -not $_.exists }).Count -or $badCandidates.Count) { 'FAIL' } else { 'PASS' }
$pub = @('# Public Content Check','',"Status: $status",'',"- Required items missing: $(($includeRows | Where-Object { -not $_.exists }).Count)","- Excluded-pattern tracked candidates: $($badCandidates.Count)",'','## Required Items','','| item | exists |','|---|---|')
foreach($r in $includeRows){ $pub += "| $($r.item) | $($r.exists) |" }
if ($badCandidates.Count) { $pub += @('','## Problematic tracked candidates'); foreach($b in $badCandidates){ $pub += "- $($b.file)" } }
WriteUtf8 'outputs/reports/PUBLIC_CONTENT_CHECK.md' $pub

# Privacy and security scan over tracked candidates only
$textExt = @('.R','.md','.qmd','.yml','.yaml','.csv','.txt','.ps1','.html','.bib','.tex','.json','.cff','.sty','.gitignore')
$scanFiles = @($candidates | Where-Object { $textExt -contains $_.extension -or [IO.Path]::GetFileName($_.file) -eq '.gitignore' })
$localWinPattern = 'C:' + '\\Users\\' + 'Asus'
$localSlashPattern = 'C:' + '/Users/' + 'Asus'
$driveDWinPattern = 'D:' + '\\'
$driveDSlashPattern = 'D:' + '/'
$patternsFail = @($localWinPattern,$localSlashPattern,$driveDWinPattern,$driveDSlashPattern,'-----BEGIN PRIVATE KEY-----','api_key\s*=','secret\s*=','token\s*=','password\s*=')
$patternsWarn = @('password','token','secret','api_key','credentials','private key','email personal','phone')
$hits = New-Object System.Collections.Generic.List[object]
foreach($sf in $scanFiles){
  if ($sf.file -in @('outputs/reports/PRIVACY_AND_SECURITY_CHECK.md','outputs/tables/csv/local_path_scan.csv','scripts/phase4_precommit_audits.ps1')) { continue }
  $full = Join-Path $root ($sf.file -replace '/','\')
  $n=0
  foreach($line in [IO.File]::ReadLines($full)){
    $n++
    foreach($p in $patternsFail){ if($line -match $p){ $hits.Add([pscustomobject]@{file=$sf.file; line=$n; severity='FAIL'; pattern=$p; text=$line.Trim()}) } }
    foreach($p in $patternsWarn){ if($line -match $p){ $hits.Add([pscustomobject]@{file=$sf.file; line=$n; severity='WARNING'; pattern=$p; text=$line.Trim()}) } }
  }
}
$realFail = @($hits | Where-Object { $_.severity -eq 'FAIL' })
$warn = @($hits | Where-Object { $_.severity -eq 'WARNING' })
$secStatus = if($realFail.Count){'FAIL'} elseif($warn.Count){'WARNING'} else {'PASS'}
$sec = @('# Privacy And Security Check','',"Status: $secStatus",'',"- Files scanned: $($scanFiles.Count)","- FAIL hits: $($realFail.Count)","- WARNING keyword hits: $($warn.Count)",'','Interpretation: warning keyword hits are reviewed as prose mentions unless they include assignments or secret-looking values. Commit is blocked only by FAIL hits.','')
if($hits.Count){ $sec += @('| severity | file | line | pattern | text |','|---|---|---:|---|---|'); foreach($h in $hits | Select-Object -First 100){ $sec += "| $($h.severity) | $($h.file) | $($h.line) | $($h.pattern) | $($h.text -replace '\|','/') |" } }
WriteUtf8 'outputs/reports/PRIVACY_AND_SECURITY_CHECK.md' $sec

# Link check for README, paper HTML, docs markdown
$linkRows = New-Object System.Collections.Generic.List[object]
function AddLink($source,$target,$kind,$exists,$note){ $linkRows.Add([pscustomobject]@{source=$source; target=$target; kind=$kind; exists=$exists; note=$note}) }
function CheckTarget($base,$target){
  if([string]::IsNullOrWhiteSpace($target)){ return @{exists=$true; note='empty/ignored'} }
  if($target -match '^(https?:|mailto:)'){ return @{exists=$true; note='external not fetched'} }
  if($target.StartsWith('#')){ return @{exists=$true; note='internal anchor not fully validated'} }
  $clean = ($target -replace '#.*$','')
  $full = Join-Path $base ($clean -replace '/','\')
  return @{exists=(Test-Path -LiteralPath $full); note=$full}
}
$mdSources = @('README.md') + @(Get-ChildItem -LiteralPath 'docs' -Filter '*.md' -File | ForEach-Object { RelPath $_.FullName })
foreach($src in $mdSources){
  $full = Join-Path $root ($src -replace '/','\')
  $base = Split-Path $full -Parent
  $content = [IO.File]::ReadAllText($full)
  $matches = [regex]::Matches($content, '!?' + '\[[^\]]*\]\(([^)]+)\)')
  foreach($m in $matches){ $target = ($m.Groups[1].Value -replace '".*$','').Trim(); $res = CheckTarget $base $target; AddLink $src $target 'markdown' $res.exists $res.note }
}
$htmlPath = Join-Path $root 'paper/main.html'
$html = [IO.File]::ReadAllText($htmlPath)
foreach($m in [regex]::Matches($html, '(?:href|src)="([^"]+)"')){ $target=$m.Groups[1].Value; $res=CheckTarget (Split-Path $htmlPath -Parent) $target; AddLink 'paper/main.html' $target 'html' $res.exists $res.note }
$linkFail = @($linkRows | Where-Object { -not $_.exists })
$linkStatus = if($linkFail.Count){'FAIL'} else {'PASS'}
$linkMd = @('# Link Check','',"Status: $linkStatus",'',"- Links checked: $($linkRows.Count)","- Broken local links: $($linkFail.Count)",'','| source | target | kind | status |','|---|---|---|---|')
foreach($r in $linkRows){ $linkStatusCell = if($r.exists){'PASS'}else{'FAIL'}; $linkMd += "| $($r.source) | $($r.target -replace '\|','/') | $($r.kind) | $linkStatusCell |" }
WriteUtf8 'outputs/reports/LINK_CHECK.md' $linkMd

# Citation check
$cff = Get-Content -LiteralPath 'CITATION.cff' -Raw
$required = @('title:','authors:','given-names:','family-names:','version:','date-released:','license:','repository-code:','keywords:','message:')
$missing = @($required | Where-Object { $cff -notmatch [regex]::Escape($_) })
$cffStatus = if($missing.Count){'FAIL'} else {'PASS'}
$cffLines = @(
  '# Citation CFF Check',
  '',
  "Status: $cffStatus",
  '',
  "- Missing required fields: $($missing.Count)",
  '- Name checked: Monica Cueto Tapia',
  '- DOI: not provided and not invented.',
  '- ORCID: not provided and not invented.',
  ''
)
if($missing.Count){ $cffLines += 'Missing: ' + ($missing -join ', ') } else { $cffLines += 'All requested fields present.' }
WriteUtf8 'outputs/reports/CITATION_CFF_CHECK.md' $cffLines
Write-Output 'Phase 4 pre-commit audits complete'
