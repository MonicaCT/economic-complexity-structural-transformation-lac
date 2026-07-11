param(
  [string[]]$SourceRoots = @(
    '${DATA_PART_I}',
    '${DATA_PART_II}'
  ),
  [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
  [int]$SampleBytes = 32768
)

$ErrorActionPreference = 'Stop'

function Ensure-Dir([string]$Path) {
  if (-not (Test-Path -Path $Path)) { New-Item -ItemType Directory -Force -Path $Path | Out-Null }
}

function Relative-Path([string]$Path, [string]$Root) {
  $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd('\')
  $pathFull = [System.IO.Path]::GetFullPath($Path)
  if ($pathFull.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $pathFull.Substring($rootFull.Length).TrimStart('\')
  }
  return $pathFull
}

function Read-SampleText([string]$Path, [int]$Bytes) {
  try {
    $fs = [System.IO.File]::OpenRead($Path)
    try {
      $n = [Math]::Min([Math]::Max($Bytes, 4096), [int]([Math]::Min($fs.Length, [int64][int]::MaxValue)))
      if ($n -le 0) { return '' }
      $buffer = New-Object byte[] $n
      $read = $fs.Read($buffer, 0, $n)
      return [System.Text.Encoding]::UTF8.GetString($buffer, 0, $read)
    } finally { $fs.Dispose() }
  } catch { return '' }
}

function Detect-Encoding([string]$Path) {
  try {
    $fs = [System.IO.File]::OpenRead($Path)
    try {
      $bytes = New-Object byte[] 4
      $read = $fs.Read($bytes, 0, 4)
      if ($read -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { return 'UTF-8 BOM' }
      if ($read -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) { return 'UTF-16 LE BOM' }
      if ($read -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) { return 'UTF-16 BE BOM' }
    } finally { $fs.Dispose() }
  } catch { return 'unknown' }
  return 'unknown or UTF-8 without BOM'
}

function Get-DelimitedMeta([System.IO.FileInfo]$File, [int]$Bytes) {
  $sample = Read-SampleText -Path $File.FullName -Bytes $Bytes
  $out = @{ header=''; rows=$null; cols=$null; delimiter=''; obs='' }
  if (-not $sample) { $out.obs = 'Could not read bounded text sample.'; return $out }
  $lines = @($sample -split "`r?`n" | Where-Object { $_.Trim().Length -gt 0 } | Select-Object -First 20)
  if ($lines.Count -eq 0) { $out.obs = 'No non-empty lines in bounded sample.'; return $out }
  $header = [string]$lines[0]
  if ($header.Length -gt 20000) { $header = $header.Substring(0, 20000) }
  $delims = @(',', ';', "`t", '|')
  $scores = @{}
  foreach ($d in $delims) { $scores[$d] = $header.Length - $header.Replace($d, '').Length }
  $delim = ($scores.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1).Key
  if ($scores[$delim] -eq 0) { $delim = ',' }
  $nl = ([regex]::Matches($sample, "`n")).Count
  if ($nl -gt 1) {
    $avg = [Math]::Max(1.0, $sample.Length / [double]$nl)
    $out.rows = [Math]::Max(0, [int64]([Math]::Round($File.Length / $avg)) - 1)
    $out.obs = 'Rows estimated from bounded byte sample; file not fully scanned.'
  } else { $out.obs = 'Header sampled; row count unavailable because sample has too few line breaks.' }
  $out.header = $header
  $out.delimiter = $delim.Replace("`t", '\t')
  $out.cols = ([regex]::Split($header, [regex]::Escape($delim))).Count
  return $out
}

function Get-XlsxMeta([System.IO.FileInfo]$File) {
  $out = @{ sheets=$null; rows=$null; cols=$null; obs='' }
  try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
    $zip = [System.IO.Compression.ZipFile]::OpenRead($File.FullName)
    try {
      $sheets = @($zip.Entries | Where-Object { $_.FullName -match '^xl/worksheets/sheet[0-9]+\.xml$' })
      $out.sheets = $sheets.Count
      $first = $sheets | Select-Object -First 1
      if ($null -ne $first) {
        $stream = $first.Open()
        try {
          $reader = New-Object System.IO.StreamReader($stream)
          $chars = New-Object char[] 65536
          $read = $reader.ReadBlock($chars, 0, $chars.Length)
          $sample = if ($read -gt 0) { -join $chars[0..($read - 1)] } else { '' }
          $m = [regex]::Match($sample, '<dimension ref="([^"]+)"')
          if ($m.Success) {
            $last = $m.Groups[1].Value.Split(':')[-1]
            $letters = ([regex]::Match($last, '^[A-Z]+')).Value
            $digits = ([regex]::Match($last, '[0-9]+$')).Value
            if ($digits) { $out.rows = [int64]$digits }
            if ($letters) {
              $c = 0
              foreach ($ch in $letters.ToCharArray()) { $c = $c * 26 + ([int][char]$ch - [int][char]'A' + 1) }
              $out.cols = $c
            }
          }
        } finally { $stream.Dispose() }
      }
      $out.obs = 'Workbook metadata read from XLSX zip structure; cell values not loaded.'
    } finally { $zip.Dispose() }
  } catch { $out.obs = 'Could not inspect XLSX structure: ' + $_.Exception.Message }
  return $out
}

function Get-ZipMeta([System.IO.FileInfo]$File) {
  $out = @{ entries=$null; exts=''; obs='' }
  try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
    $zip = [System.IO.Compression.ZipFile]::OpenRead($File.FullName)
    try {
      $entries = @($zip.Entries)
      $out.entries = $entries.Count
      $out.exts = (($entries | ForEach-Object { [System.IO.Path]::GetExtension($_.FullName).ToLowerInvariant() } | Where-Object { $_ } | Group-Object | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object { "$($_.Name):$($_.Count)" }) -join '; ')
      $out.obs = 'ZIP contents listed without extraction.'
    } finally { $zip.Dispose() }
  } catch { $out.obs = 'Could not list ZIP contents: ' + $_.Exception.Message }
  return $out
}

function Key-Vars([string]$Text) {
  if (-not $Text) { return '' }
  $patterns = @('country','iso','reporter','partner','exporter','importer','year','time','product','hs','sitc','isic','cpc','commodity','export','import','trade','value','usd','gdp','population','productivity','employment','manufacturing','rents','eci','pci','rca','indicator','series','description')
  $tokens = [regex]::Split($Text.ToLowerInvariant(), '[^a-z0-9_]+') | Where-Object { $_.Length -gt 1 } | Select-Object -Unique
  $hits = New-Object System.Collections.Generic.List[string]
  foreach ($tok in $tokens) { foreach ($p in $patterns) { if ($tok -like "*$p*") { [void]$hits.Add($tok); break } } }
  return (($hits | Select-Object -Unique -First 40) -join '; ')
}

function Source-Signal([string]$Text) {
  $t = $Text.ToLowerInvariant()
  if ($t -match 'baci|cepii') { return 'BACI/CEPII candidate' }
  if ($t -match 'comtrade|uncomtrade') { return 'UN Comtrade candidate' }
  if ($t -match 'atlas|economic.complexity|complexity') { return 'Atlas/economic complexity candidate' }
  if ($t -match 'world.bank|wdi|world.development') { return 'World Bank/WDI candidate' }
  if ($t -match 'pwt|penn.world') { return 'Penn World Table candidate' }
  if ($t -match 'ilo|ilostat') { return 'ILO/ILOSTAT candidate' }
  if ($t -match 'unctad') { return 'UNCTAD candidate' }
  if ($t -match 'oecd') { return 'OECD candidate' }
  return 'local file; source not explicit from name'
}

function Theme([string]$Text, [string]$Keys) {
  $t = ($Text + ' ' + $Keys).ToLowerInvariant()
  if ($t -match 'dictionary|metadata|classification|concordance|codebook|country_code|product_description|hs|sitc|isic|cpc') { return 'dictionaries and metadata' }
  if ($t -match 'export|exports|trade_value|baci|comtrade') { if ($t -match 'importer|partner|bilateral') { return 'bilateral trade' } else { return 'exports by product' } }
  if ($t -match 'import|imports') { return 'imports by product' }
  if ($t -match 'gdp.per.capita|ny.gdp.pcap|gdppc') { return 'GDP per capita' }
  if ($t -match 'gdp|ny.gdp|rgdp') { return 'GDP' }
  if ($t -match 'population|sp.pop') { return 'population' }
  if ($t -match 'productivity') { return 'productivity' }
  if ($t -match 'employment|labor|labour') { return 'sectoral employment' }
  if ($t -match 'value.added|manufacturing') { return 'manufacturing' }
  if ($t -match 'technology|patent|innovation|ict') { return 'technology' }
  if ($t -match 'education|school|human.capital') { return 'education or human capital' }
  if ($t -match 'natural.resource|rents|minerals|oil|gas|hydrocarbon') { return 'natural resources' }
  if ($t -match 'geo|shape|shp|boundary') { return 'geography' }
  if ($t -match 'macro|indicator|wdi|world.bank|pwt') { return 'macroeconomic indicators' }
  return 'other'
}

function Utility-Status([string]$Category, [string]$Keys, [string]$Ext, [string]$Name) {
  $k = $Keys.ToLowerInvariant(); $n = $Name.ToLowerInvariant()
  $utility = 'unclear until manual review'; $status = 'pending'
  if ($Category -in @('bilateral trade','exports by product','imports by product')) {
    $utility = 'high: candidate for trade-country-product-year construction'; $status = 'possibly useful'
    if ($k -match 'year|time' -and $k -match 'product|hs|sitc|commodity' -and $k -match 'value|trade|export|import' -and $k -match 'country|reporter|exporter|iso') { $status = 'useful' }
  } elseif ($Category -in @('macroeconomic indicators','GDP','GDP per capita','population','productivity','manufacturing','natural resources','education or human capital')) {
    $utility = 'medium to high: candidate for country-year panel'; $status = 'possibly useful'
    if ($k -match 'country|iso|code' -and $k -match 'year|time' -and $k -match 'value|indicator|gdp|population') { $status = 'useful' }
  } elseif ($Category -eq 'dictionaries and metadata') { $utility = 'medium: candidate for harmonization and labels'; $status = 'possibly useful' }
  elseif ($Ext -in @('.png','.pdf','.doc','.html','.do','.R','.py','.md')) { $utility = 'documentation, code, or existing output; not primary analytical data'; $status = 'possibly useful'; if ($Ext -eq '.png') { $status = 'irrelevant' } }
  if ($n -match 'duplicate|copy|backup') { $status = 'duplicated candidate' }
  return @($utility, $status)
}

$docs = Join-Path $ProjectRoot 'docs'; $metaDir = Join-Path $ProjectRoot 'data\metadata'; $logs = Join-Path $ProjectRoot 'logs'
Ensure-Dir $docs; Ensure-Dir $metaDir; Ensure-Dir $logs
$started = Get-Date
$rows = New-Object System.Collections.Generic.List[object]

foreach ($root in $SourceRoots) {
  if (-not (Test-Path -Path $root)) { Write-Warning "Source root not found: $root"; continue }
  $files = @(Get-ChildItem -Path $root -Recurse -File -ErrorAction SilentlyContinue)
  $i = 0
  foreach ($file in $files) {
    $i++
    Set-Content -Path (Join-Path $logs 'inventory_progress.txt') -Value ("{0}/{1}`t{2}" -f $i, $files.Count, $file.FullName) -Encoding UTF8
    if (($i % 250) -eq 0) { Write-Host ("Inventorying {0}/{1} in {2}" -f $i, $files.Count, $root) }
    $ext = $file.Extension.ToLowerInvariant(); $sheet=$null; $rowsApprox=$null; $cols=$null; $enc=''; $obs=''; $header=''; $zipEntries=''; $zipExts=''
    if ($ext -in @('.csv','.txt','.tsv')) { $enc = Detect-Encoding $file.FullName; $m = Get-DelimitedMeta $file $SampleBytes; $header=$m.header; $rowsApprox=$m.rows; $cols=$m.cols; $obs=$m.obs + ' Delimiter: ' + $m.delimiter }
    elseif ($ext -eq '.xlsx') { $m = Get-XlsxMeta $file; $sheet=$m.sheets; $rowsApprox=$m.rows; $cols=$m.cols; $obs=$m.obs }
    elseif ($ext -eq '.zip') { $m = Get-ZipMeta $file; $zipEntries=$m.entries; $zipExts=$m.exts; $obs=$m.obs; $header=$zipExts }
    elseif ($ext -in @('.dta','.sav','.rds','.rdata','.parquet','.xls','.xlsb')) { $header = Read-SampleText $file.FullName ([Math]::Min($SampleBytes, 65536)); $obs='Binary/statistical format inventoried from bounded printable sample only.' }
    elseif ($ext -in @('.gz','.rar','.7z')) { $obs='Compressed file inventoried without extraction.' }
    elseif ($file.Length -lt 10485760) { $header = Read-SampleText $file.FullName ([Math]::Min($SampleBytes, 16384)) }
    $infer = "$($file.FullName) $header $zipExts"
    $keys = Key-Vars $infer
    $source = Source-Signal $infer
    $cat = Theme $infer $keys
    $content = if ($cat -eq 'bilateral trade') { 'Likely exporter-importer-product-year trade records.' } elseif ($cat -eq 'exports by product') { 'Likely country-product-year export or trade records.' } elseif ($cat -eq 'dictionaries and metadata') { 'Likely code dictionary, classifier, metadata, or concordance.' } elseif ($cat -match 'GDP|population|macro|productivity') { 'Likely country-year macroeconomic indicators.' } else { 'Content inferred from file name and bounded sample only.' }
    $us = Utility-Status $cat $keys $ext $file.Name
    $rows.Add([pscustomobject]@{
      full_path=$file.FullName; source_root=$root; relative_path=(Relative-Path $file.FullName $root); name=$file.Name; extension=$ext; size_bytes=$file.Length; size_mb=[Math]::Round($file.Length / 1MB, 3); modified_time=$file.LastWriteTime.ToString('s'); sheet_count=$sheet; approx_rows=$rowsApprox; approx_columns=$cols; encoding=$enc; possible_source=$source; probable_content=$content; key_variables_identified=$keys; thematic_category=$cat; potential_utility=$us[0]; status=$us[1]; compressed_entry_count=$zipEntries; compressed_entry_extensions=$zipExts; observations=$obs
    }) | Out-Null
  }
}

$csv = Join-Path $docs 'DATA_INVENTORY.csv'; $md = Join-Path $docs 'DATA_INVENTORY.md'; $fr = Join-Path $docs 'DATA_FEASIBILITY_REPORT.md'
$rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
$sourceGroups = $rows | Group-Object source_root | Sort-Object Count -Descending
$catGroups = $rows | Group-Object thematic_category | Sort-Object Count -Descending
$statusGroups = $rows | Group-Object status | Sort-Object Count -Descending
$useful = @($rows | Where-Object { $_.status -in @('useful','possibly useful') } | Sort-Object @{Expression='size_bytes';Descending=$true} | Select-Object -First 40)
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('# Data Inventory') | Out-Null; $lines.Add('') | Out-Null; $lines.Add('Generated by `scripts/build_inventory.ps1` using local metadata and bounded file samples only. Original data files were not modified.') | Out-Null; $lines.Add('') | Out-Null; $lines.Add("Total files inventoried: **$($rows.Count)**") | Out-Null; $lines.Add('') | Out-Null
$lines.Add('## By Source Root') | Out-Null; $lines.Add('| Source root | Files | Size GB |') | Out-Null; $lines.Add('|---|---:|---:|') | Out-Null
foreach ($g in $sourceGroups) { $bytes=($g.Group | Measure-Object size_bytes -Sum).Sum; $lines.Add("| $($g.Name) | $($g.Count) | $([Math]::Round($bytes / 1GB, 2)) |") | Out-Null }
$lines.Add('') | Out-Null; $lines.Add('## By Thematic Category') | Out-Null; $lines.Add('| Category | Files |') | Out-Null; $lines.Add('|---|---:|') | Out-Null
foreach ($g in $catGroups) { $lines.Add("| $($g.Name) | $($g.Count) |") | Out-Null }
$lines.Add('') | Out-Null; $lines.Add('## By Status') | Out-Null; $lines.Add('| Status | Files |') | Out-Null; $lines.Add('|---|---:|') | Out-Null
foreach ($g in $statusGroups) { $lines.Add("| $($g.Name) | $($g.Count) |") | Out-Null }
$lines.Add('') | Out-Null; $lines.Add('## Largest Useful or Possibly Useful Candidates') | Out-Null; $lines.Add('| File | Category | Size MB | Key variables | Utility |') | Out-Null; $lines.Add('|---|---|---:|---|---|') | Out-Null
foreach ($r in $useful) { $lines.Add("| $($r.relative_path.Replace('|','/')) | $($r.thematic_category) | $($r.size_mb) | $(($r.key_variables_identified -replace '\|','/')) | $(($r.potential_utility -replace '\|','/')) |") | Out-Null }
Set-Content -Path $md -Value $lines -Encoding UTF8

$trade = @($rows | Where-Object { $_.thematic_category -in @('bilateral trade','exports by product','imports by product') -and $_.status -in @('useful','possibly useful') })
$exports = @($rows | Where-Object { $_.thematic_category -eq 'exports by product' -and $_.status -in @('useful','possibly useful') })
$bilat = @($rows | Where-Object { $_.thematic_category -eq 'bilateral trade' -and $_.status -in @('useful','possibly useful') })
$macro = @($rows | Where-Object { $_.thematic_category -in @('macroeconomic indicators','GDP','GDP per capita','population','productivity','manufacturing','natural resources','education or human capital') -and $_.status -in @('useful','possibly useful') })
$dicts = @($rows | Where-Object { $_.thematic_category -eq 'dictionaries and metadata' -and $_.status -in @('useful','possibly useful') })
$tf = if ($trade.Count -gt 0) { 'partially feasible pending source-level validation' } else { 'not feasible from current audit evidence' }
$mf = if ($macro.Count -gt 0) { 'partially feasible pending source-level validation' } else { 'not feasible from current audit evidence' }
$cand = @($trade + $macro + $dicts | Sort-Object @{Expression='size_bytes';Descending=$true} | Select-Object -First 60)
$f = New-Object System.Collections.Generic.List[string]
$f.Add('# Data Feasibility Report') | Out-Null; $f.Add('') | Out-Null; $f.Add('This Phase 1 gate uses the complete local file inventory plus bounded metadata/header samples. It does not run empirical models or claim findings.') | Out-Null; $f.Add('') | Out-Null
$f.Add('## Summary') | Out-Null; $f.Add('| Component | Feasibility | Evidence |') | Out-Null; $f.Add('|---|---|---|') | Out-Null
$f.Add("| Exports by country-product-year | $tf | $($exports.Count) export-product candidates and $($bilat.Count) bilateral-trade candidates. |") | Out-Null
$f.Add("| Imports and bilateral trade | $tf | Product-level trade candidates must validate importer/exporter/product/year/value fields. |") | Out-Null
$f.Add("| RCA, diversity, ubiquity, ECI, PCI, Product Space, density | $tf | Requires a validated export-value table with consistent product codes. |") | Out-Null
$f.Add("| Bolivia-Latin America comparison | $tf | Requires Bolivia to appear in the selected trade source. |") | Out-Null
$f.Add("| Country-year macro panel | $mf | $($macro.Count) macro candidates identified. |") | Out-Null
$f.Add('| Econometric panel models | conditional | Only after trade indicators and macro panel pass validation. |') | Out-Null
$f.Add('') | Out-Null; $f.Add('## Candidate Files for Use') | Out-Null; $f.Add('| File | Category | Status | Size MB | Key variables | Source signal |') | Out-Null; $f.Add('|---|---|---|---:|---|---|') | Out-Null
foreach ($r in $cand) { $f.Add("| $($r.full_path.Replace('|','/')) | $($r.thematic_category) | $($r.status) | $($r.size_mb) | $(($r.key_variables_identified -replace '\|','/')) | $($r.possible_source) |") | Out-Null }
$f.Add('') | Out-Null; $f.Add('## Analyses Not Yet Possible') | Out-Null; $f.Add('- No empirical model, Bolivia ranking, Product Space graph, or conclusion should be produced until candidate source files are imported and tested.') | Out-Null; $f.Add('- No external references or missing data can be added because the project forbids web access, APIs, and synthetic replacement data.') | Out-Null
$f.Add('') | Out-Null; $f.Add('## Central Limitations') | Out-Null; $f.Add('- The current environment has no Rscript, Python, or Quarto on PATH; Phase 1 was generated with PowerShell/.NET only.') | Out-Null; $f.Add('- XLS, DTA, SAV, RDS, RData, Parquet, RAR, 7Z, and GZ files are inventoried but require specialized readers for full validation.') | Out-Null; $f.Add('- ZIP files were listed but not extracted.') | Out-Null
$f.Add('') | Out-Null; $f.Add('## Next Gate') | Out-Null; $f.Add('Proceed to Phase 2 only after selecting one principal trade source and one macro source from the candidate files, then validating actual columns, units, countries, years, and product classification.') | Out-Null
Set-Content -Path $fr -Value $f -Encoding UTF8

$finished = Get-Date
$summary = [pscustomobject]@{ generated_at=$finished.ToString('s'); elapsed_seconds=[Math]::Round(($finished-$started).TotalSeconds,2); source_roots=$SourceRoots; total_files=$rows.Count; total_size_gb=[Math]::Round((($rows | Measure-Object size_bytes -Sum).Sum)/1GB,3); status_counts=@($statusGroups | ForEach-Object { [pscustomobject]@{status=$_.Name; count=$_.Count} }); category_counts=@($catGroups | ForEach-Object { [pscustomobject]@{category=$_.Name; count=$_.Count} }) }
$summary | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $metaDir 'inventory_summary.json') -Encoding UTF8
"Inventory complete: $($rows.Count) files, $($summary.total_size_gb) GB, elapsed $($summary.elapsed_seconds) seconds." | Tee-Object -FilePath (Join-Path $logs 'inventory.log')

