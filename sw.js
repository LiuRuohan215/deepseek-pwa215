/* 本文件由 sync.ps1 自动生成，请勿手动编辑。 */
const CACHE_VERSION = 'deepseek-pwa-202611181625';
const PRECACHE = [
  './',
  './index.html',
  './manifest.webmanifest',
  './icons/icon-192.png',
  './icons/icon-512.png',
  './icons/apple-touch-icon.png',
  './static/css/main.7361e32c.css',
  './static/css/async/4959.1382f613.css',
  './static/js/main.9820cd3a.js',
  './static/js/async/1031.575fa503.js',
  './static/js/async/1085.769e13d5.js',
  './static/js/async/1086.4d3be1fa.js',
  './static/js/async/1097.4f798919.js',
  './static/js/async/1299.0ef86619.js',
  './static/js/async/1393.6ef1efab.js',
  './static/js/async/1401.88487cba.js',
  './static/js/async/1505.8913966f.js',
  './static/js/async/160.81018107.js',
  './static/js/async/1679.153f9f03.js',
  './static/js/async/1690.fe25bdfe.js',
  './static/js/async/2110.a1d33f2f.js',
  './static/js/async/2152.97b0a90c.js',
  './static/js/async/2168.9925ab2d.js',
  './static/js/async/2312.4fd0ef8e.js',
  './static/js/async/2348.41564e59.js',
  './static/js/async/2356.631a6aca.js',
  './static/js/async/2415.00900482.js',
  './static/js/async/2461.15199935.js',
  './static/js/async/2541.f8eac009.js',
  './static/js/async/2607.abb8bc11.js',
  './static/js/async/265.b43cee3f.js',
  './static/js/async/2696.60d5ecf0.js',
  './static/js/async/3014.c8e9b88f.js',
  './static/js/async/3111.e2cca965.js',
  './static/js/async/3251.0b9c608e.js',
  './static/js/async/3339.ed293391.js',
  './static/js/async/3376.3aa54d1a.js',
  './static/js/async/3465.845187e8.js',
  './static/js/async/3477.94bd21ab.js',
  './static/js/async/3594.edfe4411.js',
  './static/js/async/3806.28abb895.js',
  './static/js/async/3909.4b4bd806.js',
  './static/js/async/4138.104dbc81.js',
  './static/js/async/426.6fedaabe.js',
  './static/js/async/4387.151c5858.js',
  './static/js/async/4468.d0c907eb.js',
  './static/js/async/4471.b0874c8d.js',
  './static/js/async/4568.cf5e547d.js',
  './static/js/async/4580.f1bc120a.js',
  './static/js/async/4695.8f4b8910.js',
  './static/js/async/4959.deb41780.js',
  './static/js/async/509.f3e093b4.js',
  './static/js/async/5172.e1e3bd11.js',
  './static/js/async/535.e10ba324.js',
  './static/js/async/5546.89da376c.js',
  './static/js/async/5597.3018e134.js',
  './static/js/async/5636.61075f0b.js',
  './static/js/async/5638.7cfdcd7e.js',
  './static/js/async/5706.d34ac064.js',
  './static/js/async/5856.d75c4e3b.js',
  './static/js/async/6061.7cfcc3e9.js',
  './static/js/async/6152.d3a64904.js',
  './static/js/async/6297.6e694780.js',
  './static/js/async/6325.cafe9e55.js',
  './static/js/async/6332.682f48c9.js',
  './static/js/async/6349.e9992b47.js',
  './static/js/async/6389.1bb952e3.js',
  './static/js/async/6443.95da1923.js',
  './static/js/async/6526.56ce7dc4.js',
  './static/js/async/6600.6e0dfb69.js',
  './static/js/async/6689.d0bd8935.js',
  './static/js/async/6751.54c80aba.js',
  './static/js/async/680.5aa7dcb4.js',
  './static/js/async/6948.9cd716f4.js',
  './static/js/async/7262.f680270f.js',
  './static/js/async/7515.20c14480.js',
  './static/js/async/7536.34769b35.js',
  './static/js/async/7630.ed725458.js',
  './static/js/async/7853.0a4b794a.js',
  './static/js/async/8180.4d4299ef.js',
  './static/js/async/828.56686119.js',
  './static/js/async/8379.1b75211c.js',
  './static/js/async/8389.4f120664.js',
  './static/js/async/8538.d5f92d14.js',
  './static/js/async/8560.1bdf90ec.js',
  './static/js/async/8794.759831e8.js',
  './static/js/async/8821.2b444259.js',
  './static/js/async/925.897d4231.js',
  './static/js/async/9252.3c22a9cd.js',
  './static/js/async/9261.1e796956.js',
  './static/js/async/9324.b3518ebf.js',
  './static/js/async/9354.4425ac3c.js',
  './static/js/async/9501.a7851380.js',
  './static/js/async/9560.d604e606.js',
  './static/js/async/9640.5f6a6734.js',
  './static/js/async/9765.ecc8b5dc.js',
  './static/js/async/9821.b1897048.js'
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
