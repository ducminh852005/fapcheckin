<#
.SYNOPSIS
  Deploy FAP Check-in lên Firebase: Hosting (trang SV), Firestore rules/indexes, Storage rules,
  Remote Config và Cloud Functions (OCR).

.DESCRIPTION
  Không còn backend Apps Script: toàn bộ backend là dịch vụ Firebase. Script chạy test Security Rules
  trên Emulator trước, rồi `firebase deploy`. App Flutter (mobile/) KHÔNG deploy bằng script này.
  Hướng dẫn: docs/deploy-firebase.md

.PARAMETER ProjectId
  Firebase project id. Mặc định lấy từ .firebaserc ("default").

.PARAMETER Only
  all (mặc định) | hosting | firestore | storage | remoteconfig | functions
  Lưu ý: functions cần gói Blaze và bật Cloud Vision API.

.PARAMETER Channel
  Deploy Hosting lên preview channel thay vì live. Chỉ dùng với -Only hosting.

.PARAMETER SkipTests
  Bỏ qua `npm test` (rules + Emulator) trước khi deploy.

.PARAMETER DryRun
  In các bước và lệnh, không thay đổi gì.

.EXAMPLE
  ./scripts/deploy.ps1
.EXAMPLE
  ./scripts/deploy.ps1 -Only firestore
.EXAMPLE
  ./scripts/deploy.ps1 -Only hosting -Channel preview
#>
[CmdletBinding()]
param(
  [string]$ProjectId,
  [ValidateSet('all', 'hosting', 'firestore', 'storage', 'remoteconfig', 'functions')]
  [string]$Only = 'all',
  [string]$Channel,
  [switch]$SkipTests,
  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot

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

if ($Channel -and $Only -ne 'hosting') {
  throw '-Channel chỉ dùng cho Hosting: thêm -Only hosting.'
}

if (-not $ProjectId) {
  $rc = Join-Path $RepoRoot '.firebaserc'
  if (Test-Path $rc) {
    $rcJson = Get-Content -Raw -Path $rc | ConvertFrom-Json
    if ($rcJson.PSObject.Properties.Name -contains 'projects' -and
        $rcJson.projects.PSObject.Properties.Name -contains 'default') {
      $ProjectId = $rcJson.projects.default
    }
  }
  if (-not $ProjectId) {
    throw 'Thiếu Firebase project. Truyền -ProjectId <id> hoặc chạy "firebase use --add".'
  }
}

foreach ($file in @('firebase.json', 'firebase/firestore.rules', 'firebase/firestore.indexes.json',
                    'firebase/storage.rules', 'firebase/remoteconfig.template.json', 'web/checkin/index.html')) {
  if (-not (Test-Path (Join-Path $RepoRoot $file))) { throw "Thiếu $file." }
}
foreach ($file in @('firebase.json', 'firebase/firestore.indexes.json', 'firebase/remoteconfig.template.json')) {
  try { Get-Content -Raw -Path (Join-Path $RepoRoot $file) | ConvertFrom-Json | Out-Null }
  catch { throw "$file không phải JSON hợp lệ: $($_.Exception.Message)" }
}

$channelNote = ''
if ($Channel) { $channelNote = " (preview channel '$Channel')" }
Write-Step 'Cấu hình'
Write-Host "    Project : $ProjectId"
Write-Host "    Targets : $Only$channelNote"
if ($DryRun) { Write-Host '    DRY RUN: không thay đổi gì.' -ForegroundColor Yellow }

Write-Step 'Kiểm tra công cụ'
if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw 'Cần Node.js 22+.' }
$fbExe = $null; $fbPre = @()
if (Get-Command firebase -ErrorAction SilentlyContinue) {
  $fbExe = 'firebase'
} elseif (Get-Command npx -ErrorAction SilentlyContinue) {
  $fbExe = 'npx'; $fbPre = @('--yes', 'firebase-tools')
  Write-Host '    Chưa cài firebase CLI toàn cục; dùng "npx firebase-tools".'
} else {
  throw 'Không thấy firebase CLI. Chạy: npm install -g firebase-tools'
}

if (-not $SkipTests) {
  Write-Step 'Chạy test Security Rules trên Firebase Emulator'
  Push-Location (Join-Path $RepoRoot 'firebase')
  try {
    if (-not (Test-Path 'node_modules')) { Invoke-Native 'npm' @('ci') }
    Invoke-Native 'npm' @('test')
  } finally {
    Pop-Location
  }
} else {
  Write-Host '    (bỏ qua test: -SkipTests)' -ForegroundColor Yellow
}

Push-Location $RepoRoot
try {
  if ($Channel) {
    Write-Step "Deploy Hosting lên preview channel '$Channel'"
    Invoke-Native $fbExe ($fbPre + @('hosting:channel:deploy', $Channel, '--project', $ProjectId))
  } else {
    $targets = $Only
    if ($Only -eq 'all') { $targets = 'hosting,firestore,storage,remoteconfig,functions' }
    Write-Step "Deploy lên Firebase: $targets"
    Invoke-Native $fbExe ($fbPre + @('deploy', '--only', $targets, '--project', $ProjectId))
  }
} finally {
  Pop-Location
}

Write-Step 'Xong'
if ($Only -in @('all', 'hosting') -and -not $Channel) {
  Write-Host "    Trang SV: https://$ProjectId.web.app/?s=<sessionId>&t=<qrSecret>"
}
if ($Channel) { Write-Host '    URL preview do firebase CLI in ở trên.' }
