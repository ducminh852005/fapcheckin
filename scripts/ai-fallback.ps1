# Điều khiển AI dự phòng (Ollama local) cho buổi demo.
#
#   ./scripts/ai-fallback.ps1 up                 # bật Ollama + tunnel, tự ghi URL vào Firestore, chế độ auto
#   ./scripts/ai-fallback.ps1 switch ollama      # ép dùng Ollama NGAY (khi Gemini quá tải)
#   ./scripts/ai-fallback.ps1 switch auto        # Gemini trước, lỗi thì sang Ollama
#   ./scripts/ai-fallback.ps1 switch gemini      # chỉ Gemini
#   ./scripts/ai-fallback.ps1 status             # xem cấu hình + container
#   ./scripts/ai-fallback.ps1 down               # tắt container, trả về chế độ gemini
#
# Tham số tuỳ chọn: -Project <id> (mặc định lấy từ .firebaserc), -Model <tên> (mặc định qwen2.5:7b), -Emulator
# Cần: Docker, Node 22+, và đăng nhập Google cho Admin SDK: `gcloud auth application-default login`
param(
  [Parameter(Mandatory = $true, Position = 0)][ValidateSet('up', 'switch', 'status', 'down')][string]$Action,
  [Parameter(Position = 1)][ValidateSet('auto', 'gemini', 'ollama')][string]$Mode,
  [string]$Project,
  [string]$Model = 'qwen2.5:7b',
  [switch]$Emulator
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$compose = Join-Path $root 'ops/ollama/docker-compose.yml'
$setter = Join-Path $root 'firebase/scripts/set-ai-provider.mjs'
$env:OLLAMA_MODEL = $Model

function Set-Provider([string[]]$extra) {
  $a = @($setter) + $extra
  if ($Project) { $a += @('--project', $Project) }
  if ($Emulator) { $a += '--emulator' }
  Push-Location (Join-Path $root 'firebase')
  try { & node @a } finally { Pop-Location }
  if ($LASTEXITCODE -ne 0) { throw "set-ai-provider thất bại (mã $LASTEXITCODE)" }
}

function Get-TunnelUrl {
  for ($i = 0; $i -lt 40; $i++) {
    $logs = docker logs fap-ollama-tunnel 2>&1 | Out-String
    $m = [regex]::Matches($logs, 'https://[a-z0-9-]+\.trycloudflare\.com')
    if ($m.Count -gt 0) { return $m[$m.Count - 1].Value }
    Start-Sleep -Seconds 2
  }
  throw 'Không đọc được URL tunnel sau 80 giây. Xem: docker logs fap-ollama-tunnel'
}

switch ($Action) {
  'up' {
    Write-Host '1/4 Khởi động Ollama + tunnel...'
    docker compose -f $compose up -d ollama tunnel
    Write-Host "2/4 Tải model $Model (lần đầu vài phút)..."
    docker compose -f $compose run --rm pull
    Write-Host '3/4 Đọc URL tunnel...'
    $url = Get-TunnelUrl
    Write-Host "    $url"
    Write-Host '4/4 Kiểm tra Ollama qua tunnel...'
    $tags = Invoke-RestMethod -Uri "$url/api/tags" -TimeoutSec 30
    if (-not ($tags.models | Where-Object { $_.name -like "$Model*" })) { throw "Model $Model chưa có trên Ollama." }
    Set-Provider @('--provider', 'auto', '--url', $url, '--model', $Model)
    Write-Host "`nXong. Chế độ auto: Gemini trước, quá tải thì tự sang Ollama. Ép dùng Ollama ngay: ./scripts/ai-fallback.ps1 switch ollama"
  }
  'switch' {
    if (-not $Mode) { throw 'Thiếu chế độ: auto | gemini | ollama' }
    Set-Provider @('--provider', $Mode)
  }
  'status' {
    Set-Provider @('--show')
    docker ps --filter 'name=fap-ollama' --format 'table {{.Names}}\t{{.Status}}'
  }
  'down' {
    Set-Provider @('--provider', 'gemini')
    docker compose -f $compose down
  }
}
