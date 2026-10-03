<#
.SYNOPSIS
  Deploy FAP Check-in: backend (Apps Script) + student check-in page (Firebase Hosting) + Firestore rules/indexes.

.DESCRIPTION
  The teacher app is a Flutter mobile/desktop app and is NOT deployed by this script.
  Only the student web page (checkin-web/) is hosted, because students open it
  by scanning the attendance QR code.

  Targets (see -Only), executed in this order:
    backend   : run apps-script tests, clasp push, clasp deploy to the EXISTING
                Web App deployment (URL does not change), verify live revision
    hosting   : stage checkin-web/* -> build/firebase-hosting (BACKEND_URL injected
                into the STAGED index.html only), firebase deploy --only hosting
    firestore : firebase deploy --only firestore (rules + indexes)

  Guide: docs/deploy-firebase.md

.PARAMETER ProjectId
  Firebase project id. Optional when .firebaserc has a "default" project, or when
  -Only backend.

.PARAMETER Only
  all (default: backend + hosting + firestore) | backend | hosting | firestore

.PARAMETER Channel
  Deploy Hosting to a preview channel instead of live. Requires -Only hosting.

.PARAMETER BackendUrl
  Apps Script Web App URL (.../macros/s/<DEPLOYMENT_ID>/exec). Injected into the
  student page BACKEND_URL and used to derive -DeploymentId.
  Default: the defaultValue found in lib/core/network/api_service.dart.

.PARAMETER DeploymentId
  Apps Script deployment id to update. Default: parsed from -BackendUrl.

.PARAMETER SkipTests
  Skip "node --test apps-script/tests" before pushing the backend.

.PARAMETER StageOnly
  Stage build/firebase-hosting, then stop before any deploy (backend included).

.PARAMETER DryRun
  Print every step and command; change nothing.

.EXAMPLE
  ./scripts/deploy.ps1 -ProjectId my-fap-checkin
.EXAMPLE
  ./scripts/deploy.ps1 -Only backend
.EXAMPLE
  ./scripts/deploy.ps1 -ProjectId my-fap-checkin -Only hosting -Channel preview
.EXAMPLE
  ./scripts/deploy.ps1 -ProjectId my-fap-checkin -DryRun
#>
[CmdletBinding()]
param(
  [string]$ProjectId,
  [ValidateSet('all', 'backend', 'hosting', 'firestore')]
  [string]$Only = 'all',
  [string]$Channel,
  [string]$BackendUrl,
  [string]$DeploymentId,
  [switch]$SkipTests,
  [switch]$StageOnly,
  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot   = Split-Path -Parent $PSScriptRoot
$StageDir   = Join-Path $RepoRoot 'build\firebase-hosting'
$CheckinDir = Join-Path $RepoRoot 'checkin-web'
$ScriptDir  = Join-Path $RepoRoot 'apps-script'
$ApiService = Join-Path $RepoRoot 'lib\core\network\api_service.dart'

$doBackend   = $Only -in @('all', 'backend')
$doHosting   = $Only -in @('all', 'hosting')
$doFirestore = $Only -in @('all', 'firestore')
$doFirebase  = $doHosting -or $doFirestore

function Write-Step([string]$Message) {
  Write-Host ''
  Write-Host "==> $Message" -ForegroundColor Cyan
}

function Invoke-Native([string]$Exe, [string[]]$Arguments) {
  Write-Host ("    > {0} {1}" -f $Exe, ($Arguments -join ' ')) -ForegroundColor DarkGray
  if ($DryRun) { return }
  & $Exe @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed (exit code $LASTEXITCODE): $Exe $($Arguments -join ' ')"
  }
}

# ---------------------------------------------------------------- validation
if ($Channel -and $Only -ne 'hosting') {
  throw '-Channel deploys Hosting only; use it together with -Only hosting.'
}

if ($doFirebase -and -not $ProjectId) {
  $rc = Join-Path $RepoRoot '.firebaserc'
  if (Test-Path $rc) {
    $rcJson = Get-Content -Raw -Path $rc | ConvertFrom-Json
    if ($rcJson.PSObject.Properties.Name -contains 'projects' -and
        $rcJson.projects.PSObject.Properties.Name -contains 'default') {
      $ProjectId = $rcJson.projects.default
    }
  }
  if (-not $ProjectId) {
    throw 'Missing Firebase project. Pass -ProjectId <id> or run "firebase use --add" to create .firebaserc.'
  }
}

if (($doHosting -or $doBackend) -and -not $BackendUrl) {
  $match = Select-String -Path $ApiService -Pattern "defaultValue:\s*'([^']+)'" | Select-Object -First 1
  if (-not $match) { throw "Cannot read the default backend URL from $ApiService. Pass -BackendUrl." }
  $BackendUrl = $match.Matches[0].Groups[1].Value
}

if ($doBackend -and -not $DeploymentId) {
  if ($BackendUrl -match '/macros/s/([^/]+)/exec') { $DeploymentId = $Matches[1] }
  else { throw "Cannot derive the Apps Script deployment id from '$BackendUrl'. Pass -DeploymentId." }
}

if ($doFirebase) {
  foreach ($file in @('firebase.json', 'firestore.rules', 'firestore.indexes.json')) {
    if (-not (Test-Path (Join-Path $RepoRoot $file))) { throw "Missing $file in repo root." }
  }
  foreach ($file in @('firebase.json', 'firestore.indexes.json')) {
    try { Get-Content -Raw -Path (Join-Path $RepoRoot $file) | ConvertFrom-Json | Out-Null }
    catch { throw "$file is not valid JSON: $($_.Exception.Message)" }
  }
}
if ($doHosting -and -not (Test-Path (Join-Path $CheckinDir 'index.html'))) {
  throw 'checkin-web/index.html not found.'
}
if ($doBackend -and -not (Test-Path (Join-Path $ScriptDir 'Router.gs'))) {
  throw 'apps-script/Router.gs not found.'
}

Write-Step 'Configuration'
Write-Host "    Targets      : $Only$(if ($Channel) { " (preview channel '$Channel')" })"
if ($doFirebase) { Write-Host "    Firebase     : $ProjectId" }
if ($doBackend)  { Write-Host "    Deployment id: $DeploymentId" }
if ($doHosting)  { Write-Host "    BACKEND_URL  : $BackendUrl" }
if ($DryRun) { Write-Host '    DRY RUN: nothing will be written or deployed.' -ForegroundColor Yellow }

# ------------------------------------------------------------------- tooling
Write-Step 'Checking tools'
if ($doBackend -and -not (Get-Command node -ErrorAction SilentlyContinue)) {
  throw 'node not found. Install Node.js 18+.'
}

$fbExe = $null; $fbPre = @()
if ($doFirebase) {
  if (Get-Command firebase -ErrorAction SilentlyContinue) {
    $fbExe = 'firebase'
  } elseif (Get-Command npx -ErrorAction SilentlyContinue) {
    $fbExe = 'npx'; $fbPre = @('--yes', 'firebase-tools')
    Write-Host '    firebase CLI not installed globally; using "npx firebase-tools".'
  } else {
    throw 'firebase CLI not found. Install Node.js, then run: npm install -g firebase-tools'
  }
}

$claspExe = $null; $claspPre = @()
if ($doBackend) {
  if (Get-Command clasp -ErrorAction SilentlyContinue) {
    $claspExe = 'clasp'
  } elseif (Get-Command npx -ErrorAction SilentlyContinue) {
    $claspExe = 'npx'; $claspPre = @('--yes', '@google/clasp@2')
    Write-Host '    clasp not installed globally; using "npx @google/clasp@2".'
  } else {
    throw 'clasp not found. Run: npm install -g @google/clasp@2 && clasp login'
  }
  $clasprc = Join-Path $env:USERPROFILE '.clasprc.json'
  if (-not $DryRun -and -not (Test-Path $clasprc) -and -not $env:CLASP_TOKEN) {
    throw 'clasp is not logged in (no ~/.clasprc.json). Run: clasp login'
  }
}

# -------------------------------------------------------------------- stage
if ($doHosting) {
  Write-Step "Staging student page -> $StageDir"
  if ($DryRun) {
    Write-Host '    (dry run) would copy checkin-web/* and inject BACKEND_URL into index.html'
  } else {
    if (Test-Path $StageDir) { Remove-Item -Recurse -Force -Path $StageDir }
    New-Item -ItemType Directory -Force -Path $StageDir | Out-Null
    Copy-Item -Recurse -Force -Path (Join-Path $CheckinDir '*') -Destination $StageDir

    $needle = "var BACKEND_URL = '';"
    $html = [System.IO.File]::ReadAllText((Join-Path $CheckinDir 'index.html'), [System.Text.Encoding]::UTF8)
    if (-not $html.Contains($needle)) {
      throw "checkin-web/index.html no longer contains `"$needle`"; update scripts/deploy.ps1."
    }
    $safeUrl = $BackendUrl.Replace('\', '\\').Replace("'", "\'")
    $html = $html.Replace($needle, "var BACKEND_URL = '$safeUrl';")
    [System.IO.File]::WriteAllText(
      (Join-Path $StageDir 'index.html'), $html, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host '    BACKEND_URL injected into staged index.html'
  }
}

if ($StageOnly) {
  Write-Step 'Stopped after staging (-StageOnly).'
  return
}

# ------------------------------------------------------------ deploy backend
if ($doBackend) {
  Push-Location $RepoRoot
  try {
    if (-not $SkipTests) {
      Write-Step 'Running apps-script tests'
      $tests = @(Get-ChildItem -Path (Join-Path $ScriptDir 'tests') -Filter '*.test.cjs' | ForEach-Object { $_.FullName })
      if ($tests.Count -eq 0) { throw 'No apps-script/tests/*.test.cjs found.' }
      Invoke-Native 'node' (@('--test') + $tests)
    } else {
      Write-Host '    (skipping tests: -SkipTests)' -ForegroundColor Yellow
    }

    # Same guard as .github/workflows/apps-script-deploy.yml
    $router = Get-Content -Raw -Path (Join-Path $ScriptDir 'Router.gs')
    if (-not (Test-Path (Join-Path $ScriptDir 'ReportService.gs')) -or -not $router.Contains("'getReport'")) {
      throw 'Router.gs / ReportService.gs is missing the getReport action; refusing to deploy.'
    }
    $expectedRevision = $null
    if ($router -match "revision:\s*'([^']+)'") { $expectedRevision = $Matches[1] }
  } finally {
    Pop-Location
  }

  Push-Location $ScriptDir
  try {
    Write-Step 'Pushing Apps Script code'
    $claspJson = Join-Path $ScriptDir '.clasp.json'
    if (-not (Test-Path $claspJson)) {
      Write-Host '    .clasp.json missing; creating it from clasp.json'
      if (-not $DryRun) { Copy-Item -Force -Path (Join-Path $ScriptDir 'clasp.json') -Destination $claspJson }
    }
    Invoke-Native $claspExe ($claspPre + @('push', '-f'))

    Write-Step "Updating Web App deployment $DeploymentId (URL stays the same)"
    $desc = "Deployed via scripts/deploy.ps1 $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    Invoke-Native $claspExe ($claspPre + @('deploy', '-i', $DeploymentId, '-d', $desc))
  } finally {
    Pop-Location
  }

  Write-Step 'Verifying live backend revision'
  if ($DryRun) {
    Write-Host "    (dry run) would poll $BackendUrl`?action=getBackendInfo for revision '$expectedRevision'"
  } elseif (-not $expectedRevision) {
    Write-Host '    No revision string found in Router.gs; skipping verification.' -ForegroundColor Yellow
  } else {
    $verified = $false
    for ($attempt = 1; $attempt -le 6 -and -not $verified; $attempt++) {
      try {
        $resp = Invoke-RestMethod -Uri "$BackendUrl`?action=getBackendInfo" -Method Get -TimeoutSec 30
        if ($resp.success -and $resp.data.revision -eq $expectedRevision) { $verified = $true }
      } catch {
        Write-Host "    request failed: $($_.Exception.Message)" -ForegroundColor DarkGray
      }
      if (-not $verified) {
        Write-Host "    Live deployment not updated yet (attempt $attempt/6)."
        if ($attempt -lt 6) { Start-Sleep -Seconds 10 }
      }
    }
    if (-not $verified) {
      throw "The Web App URL is still not serving revision '$expectedRevision'. Check Apps Script > Deploy > Manage deployments."
    }
    Write-Host "    Verified live Apps Script revision: $expectedRevision" -ForegroundColor Green
  }
}

# ------------------------------------------------------------ deploy firebase
if ($doFirebase) {
  Push-Location $RepoRoot
  try {
    $extra = @()
    if ($env:FIREBASE_TOKEN) { $extra += '--non-interactive' }

    if ($Channel) {
      Write-Step "Deploying Hosting to preview channel '$Channel'"
      Invoke-Native $fbExe ($fbPre + @('hosting:channel:deploy', $Channel, '--project', $ProjectId) + $extra)
    } else {
      $targets = @()
      if ($doHosting)   { $targets += 'hosting' }
      if ($doFirestore) { $targets += 'firestore' }
      Write-Step ("Deploying to Firebase: {0}" -f ($targets -join ', '))
      Invoke-Native $fbExe ($fbPre + @('deploy', '--only', ($targets -join ','), '--project', $ProjectId) + $extra)
    }
  } finally {
    Pop-Location
  }
}

Write-Step 'Done'
if ($doBackend)  { Write-Host "    Backend     : $BackendUrl" }
if ($doHosting -and -not $Channel) {
  Write-Host "    Student page: https://$ProjectId.web.app/?token=<qrToken>"
}
if ($Channel) { Write-Host '    Preview URL is printed by the firebase CLI above.' }
