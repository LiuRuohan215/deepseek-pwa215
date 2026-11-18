<#
  sync.ps1
  一键把 DeepSeek 官方 chat-demo 的全部静态文件（主文件 + 懒加载 chunk）
  同步到本 PWA 项目，并重新生成 index.html 与 sw.js。
  图标、manifest 不受影响。
  用法：在本文件夹中打开 PowerShell，执行  pwsh .\sync.ps1
#>
$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
$base = 'https://cdn.deepseek.com'

# 模拟真实浏览器：CDN 对非浏览器请求不返回静态资源
$headers = @{
  'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36'
  'Accept' = '*/*'
  'Referer' = 'https://cdn.deepseek.com/chat-demo'
}

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }

# 下载文件：超时自动重试；返回 404 输出 missing；内容是 HTML 拦截页则重试。
# 已存在的同名文件直接跳过（文件名带 hash，同名即内容相同）。
function Fetch-File($url, $out) {
  if (Test-Path $out) { return 'skip' }
  for ($attempt = 1; $attempt -le 4; $attempt++) {
    try {
      Invoke-WebRequest $url -Headers $headers -OutFile $out -UseBasicParsing -TimeoutSec 25
      if ([IO.File]::ReadAllText($out).TrimStart().StartsWith('<')) { throw 'block page' }
      return 'ok'
    } catch {
      $code = $null
      if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }
      if (Test-Path $out) { Remove-Item $out -Force }
      if ($code -eq 404) { return 'missing' }
      if ($attempt -eq 4) { throw "下载失败：$url" }
      Start-Sleep ($attempt * 3)
    }
  }
}

Write-Step '拉取官方入口页面'
$entry = (Invoke-WebRequest "$base/chat-demo" -Headers $headers -UseBasicParsing).Content

# 主文件路径（官方为 /chat-demo/static/... 绝对路径）
$mainJsRemote = @([regex]::Matches($entry, 'src="(/chat-demo/static/js/[^"]+)"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
$mainCssRemote = @([regex]::Matches($entry, 'href="(/chat-demo/static/css/[^"]+)"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
if (-not $mainJsRemote -or -not $mainCssRemote) { throw '官方页面结构解析失败，停止同步，现有文件未改动。' }

# 官方应用版本号
$appVer = 'unknown'
$metaMatch = [regex]::Match($entry, '<meta[^>]*name="application-version"[^>]*>')
if ($metaMatch.Success) {
  $contentMatch = [regex]::Match($metaMatch.Value, 'content="([^"]+)"')
  if ($contentMatch.Success) { $appVer = $contentMatch.Groups[1].Value }
}

# 项目内相对路径（去掉 /chat-demo 前缀）
$mainJsRel = @($mainJsRemote | ForEach-Object { $_ -replace '^/chat-demo/', '' })
$mainCssRel = @($mainCssRemote | ForEach-Object { $_ -replace '^/chat-demo/', '' })

Write-Step '下载主文件'
for ($i = 0; $i -lt $mainJsRemote.Count; $i++) {
  $local = Join-Path $root ($mainJsRel[$i] -replace '/', '\')
  New-Item -ItemType Directory -Force -Path (Split-Path $local) | Out-Null
  Fetch-File "$base$($mainJsRemote[$i])" $local | Out-Null
  Write-Host "  $($mainJsRel[$i])"
}
for ($i = 0; $i -lt $mainCssRemote.Count; $i++) {
  $local = Join-Path $root ($mainCssRel[$i] -replace '/', '\')
  New-Item -ItemType Directory -Force -Path (Split-Path $local) | Out-Null
  Fetch-File "$base$($mainCssRemote[$i])" $local | Out-Null
  Write-Host "  $($mainCssRel[$i])"
}

Write-Step '解析懒加载 chunk 映射'
$mainJsLocal = Join-Path $root ($mainJsRel[0] -replace '/', '\')
$bundle = Get-Content $mainJsLocal -Raw

$uIdx = $bundle.IndexOf('o.u=e=>"static/js/async/"')
$braceStart = $bundle.IndexOf('({', $uIdx) + 1
$braceEnd = $bundle.IndexOf('})[e]', $braceStart) + 1
$chunkPairs = [regex]::Matches($bundle.Substring($braceStart, $braceEnd - $braceStart), '(\d+):"([0-9a-f]+)"')
$chunkCssHash = [regex]::Match($bundle, 'static/css/async/"\+e\+"\.([0-9a-f]+)\.css"').Groups[1].Value
Write-Host "  JS chunk 数量：$($chunkPairs.Count)，CSS 统一 hash：$chunkCssHash"

# 变更签名：主文件名 + 全部 chunk 映射，写入 .sync-state 对比
$sigParts = @($mainJsRel + $mainCssRel) + ($chunkPairs | ForEach-Object { "$($_.Groups[1].Value):$($_.Groups[2].Value)" }) + "csshash:$chunkCssHash"
$sigBytes = [Text.Encoding]::UTF8.GetBytes(($sigParts -join ','))
$signature = [BitConverter]::ToString([Security.Cryptography.SHA1]::Create().ComputeHash($sigBytes)).Replace('-', '').Substring(0, 12)
$stateFile = Join-Path $root '.sync-state'
if ((Test-Path $stateFile) -and (Get-Content $stateFile -Raw).Trim() -eq $signature) {
  Write-Host "官方版本（$appVer）与当前一致，已是最新，无需更新。" -ForegroundColor Green
  return
}

Write-Step '下载全部 chunk'
New-Item -ItemType Directory -Force "$root\static\js\async", "$root\static\css\async" | Out-Null
$chunkJsRel = @()
$chunkCssRel = @()
foreach ($p in $chunkPairs) {
  $id = $p.Groups[1].Value
  $hash = $p.Groups[2].Value

  $jsRelPath = "static/js/async/$id.$hash.js"
  $jsLocal = Join-Path $root ($jsRelPath -replace '/', '\')
  Fetch-File "$base/chat-demo/$jsRelPath" $jsLocal | Out-Null
  $chunkJsRel += $jsRelPath

  # 只有含样式的 chunk 才存在 CSS，404 属正常
  $cssRelPath = "static/css/async/$id.$chunkCssHash.css"
  $cssLocal = Join-Path $root ($cssRelPath -replace '/', '\')
  if ((Fetch-File "$base/chat-demo/$cssRelPath" $cssLocal) -ne 'missing') {
    $chunkCssRel += $cssRelPath
  }
}
Write-Host "  JS chunk：$($chunkJsRel.Count) 个，CSS chunk：$($chunkCssRel.Count) 个"

Write-Step '清理旧版本文件'
foreach ($sub in @('js', 'css')) {
  $mainKeep = if ($sub -eq 'js') { $mainJsRel } else { $mainCssRel }
  # 主目录
  Get-ChildItem (Join-Path $root "static\$sub") -File |
    Where-Object { $mainKeep -notcontains "static/$sub/$($_.Name)" } |
    ForEach-Object { Remove-Item $_.FullName -Force; Write-Host "  已删除 $($_.Name)" }
  # async 目录
  $asyncKeep = if ($sub -eq 'js') { $chunkJsRel } else { $chunkCssRel }
  Get-ChildItem (Join-Path $root "static\$sub\async") -File |
    Where-Object { $asyncKeep -notcontains "static/$sub/async/$($_.Name)" } |
    ForEach-Object { Remove-Item $_.FullName -Force; Write-Host "  已删除 async/$($_.Name)" }
}

Write-Step '重新生成 index.html'
$jsTags = ($mainJsRel | ForEach-Object { "  <script defer src=`"$_`"></script>" }) -join "`n"
$cssTags = ($mainCssRel | ForEach-Object { "  <link href=`"$_`" rel=`"stylesheet`">" }) -join "`n"
$indexTpl = @'
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
  <meta name="theme-color" content="#ffffff">
  <title>DeepSeek</title>
  <meta content="__APPVER__" name="application-version">
  <!-- iOS PWA: 添加到主屏幕后以独立全屏窗口运行 -->
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="default">
  <meta name="apple-mobile-web-app-title" content="DeepSeek">
  <link rel="manifest" href="manifest.webmanifest">
  <link rel="apple-touch-icon" href="icons/apple-touch-icon.png">
  <link rel="icon" type="image/png" sizes="192x192" href="icons/icon-192.png">
__CSSTAGS__
</head>
<body>
  <div id="root"></div>
__JSTAGS__
  <script>
    if ('serviceWorker' in navigator) {
      window.addEventListener('load', function () {
        navigator.serviceWorker.register('sw.js').catch(function () {});
      });
    }
  </script>
</body>
</html>
'@
($indexTpl -replace '__APPVER__', $appVer -replace '__CSSTAGS__', $cssTags -replace '__JSTAGS__', $jsTags) |
  Set-Content -Path (Join-Path $root 'index.html') -Encoding UTF8

Write-Step '重新生成 sw.js'
$stamp = Get-Date -Format 'yyyyMMddHHmm'
$assetLines = @(
  "  './'",
  "  './index.html'",
  "  './manifest.webmanifest'",
  "  './icons/icon-192.png'",
  "  './icons/icon-512.png'",
  "  './icons/apple-touch-icon.png'"
) + ($mainCssRel + $chunkCssRel | ForEach-Object { "  './$_'" }) + ($mainJsRel + $chunkJsRel | ForEach-Object { "  './$_'" })
$precache = $assetLines -join ",`n"
$swTpl = @'
/* 本文件由 sync.ps1 自动生成，请勿手动编辑。 */
const CACHE_VERSION = 'deepseek-pwa-__STAMP__';
const PRECACHE = [
__PRECACHE__
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_VERSION)
      .then(cache => cache.addAll(PRECACHE))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(
        keys.filter(key => key !== CACHE_VERSION).map(key => caches.delete(key))
      ))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', event => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;

  event.respondWith(
    caches.match(request).then(cached => {
      if (cached) return cached;
      return fetch(request)
        .then(response => {
          if (response && response.status === 200) {
            const copy = response.clone();
            caches.open(CACHE_VERSION)
              .then(cache => cache.put(request, copy))
              .catch(() => {});
          }
          return response;
        })
        .catch(() => {
          if (request.mode === 'navigate') return caches.match('./index.html');
        });
    })
  );
});
'@
($swTpl -replace '__STAMP__', $stamp -replace '__PRECACHE__', $precache) |
  Set-Content -Path (Join-Path $root 'sw.js') -Encoding UTF8

Set-Content -Path $stateFile -Value $signature -Encoding UTF8
Write-Host "`n同步完成。提交并推送到 GitHub 后，iPhone 上重新打开即可自动更新。" -ForegroundColor Green
