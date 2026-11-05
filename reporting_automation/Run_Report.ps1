$ErrorActionPreference = 'Stop'
try {
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$env:PYTHONUTF8 = '1'
$bundledPython = Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
if (Test-Path -LiteralPath $bundledPython) {
    $pythonPath = $bundledPython
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $pythonPath = (Get-Command python).Source
} else {
    throw 'Python was not found. Install Python 3.10+ and try again.'
}
Write-Host 'Olist report | Historical data: 2017-01 to 2018-08'
$month = Read-Host 'Month (YYYY-MM), or Enter for latest'
Write-Host '1 = Offline report (default, no API); 2 = AI draft (sends aggregate facts to OpenAI)'
$mode = Read-Host 'Choose 1 or 2'
if ($mode -notin @('', '1', '2')) { throw 'Choose 1 or 2.' }
$reportArgs = @((Join-Path $PSScriptRoot 'report.py'))
if ($month) { $reportArgs += @('--month', $month.Trim()) }
if ($mode -eq '2') {
    $model = Read-Host 'Model ID for your OpenAI API account'
    if (-not $model) { throw 'Model ID is required.' }
    if (-not $env:OPENAI_API_KEY) {
        $secret = Read-Host 'API key (hidden, used only for this session)' -AsSecureString
        $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret)
        try { $env:OPENAI_API_KEY = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer) }
        finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer) }
    }
    $reportArgs += @('--ai', '--model', $model.Trim())
}
try {
    & $pythonPath @reportArgs
    if ($LASTEXITCODE -ne 0) { throw 'Report failed. No new report was produced. See the message above.' }
    $reportPath = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'reports\latest_path.txt') -Raw
    Write-Host 'Report complete:' $reportPath
} finally {
    if ($secret) { Remove-Item Env:OPENAI_API_KEY -ErrorAction SilentlyContinue }
}
} catch {
    $message = $_.Exception.Message
    Write-Host ''
    Write-Host 'STARTUP OR REPORT ERROR:' -ForegroundColor Red
    Write-Host $message -ForegroundColor Red
    $errorPath = Join-Path $PSScriptRoot 'last_error.txt'
    try {
        Set-Content -LiteralPath $errorPath -Value $message -Encoding UTF8
        Write-Host 'Error details saved to:' $errorPath
    } catch {
        Write-Host 'Could not save an error log. Copy the message above.'
    }
    exit 1
}
