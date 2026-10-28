// Renders the JSON scenes from scene.luau into PNG contact sheets: one image
// per scene with every view side by side, so a model can be checked at a
// glance without opening Studio.
//
//   node tools/preview/render.mjs <jsonDir> <pngDir> [nameFilter]
//
// Uses three.js in headless Chromium (Playwright). Parts are drawn from their
// Size, CFrame, Color and Material; Neon glows, Glass is see-through, and
// SurfaceGui text is painted on its face. It's an approximation of Studio,
// close enough to judge shapes, proportions and colors.
import { createRequire } from 'node:module'
import fs from 'node:fs'
import http from 'node:http'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const require = createRequire(import.meta.url)
const { chromium } = require('playwright')

const here = path.dirname(fileURLToPath(import.meta.url))
const [jsonDir, pngDir, filter] = process.argv.slice(2)
if (!jsonDir || !pngDir) {
  console.log('usage: node tools/preview/render.mjs <jsonDir> <pngDir> [nameFilter]')
  process.exit(2)
}
fs.mkdirSync(pngDir, { recursive: true })

const threeDir = path.join(here, 'node_modules', 'three')
const types = { '.js': 'text/javascript', '.html': 'text/html', '.json': 'application/json' }
const server = http.createServer((req, res) => {
  const url = decodeURIComponent(req.url.split('?')[0])
  let file
  if (url === '/') file = path.join(here, 'page.html')
  else if (url.startsWith('/three/')) file = path.join(threeDir, url.slice('/three/'.length))
  else if (url.startsWith('/scene/')) file = path.join(jsonDir, url.slice('/scene/'.length))
  if (!file || !fs.existsSync(file)) {
    res.writeHead(404)
    res.end()
    return
  }
  res.writeHead(200, { 'Content-Type': types[path.extname(file)] || 'application/octet-stream' })
  fs.createReadStream(file).pipe(res)
})
await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve))
const port = server.address().port

const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] })
const page = await browser.newPage({ viewport: { width: 1400, height: 900 } })
page.on('console', (msg) => {
  if (msg.type() === 'error') console.log('  [page]', msg.text())
})
page.on('pageerror', (err) => console.log('  [page error]', err.message))
await page.goto(`http://127.0.0.1:${port}/`)
await page.waitForFunction(() => window.ready === true, null, { timeout: 30000 })

const files = fs.readdirSync(jsonDir).filter((f) => f.endsWith('.json') && (!filter || f.includes(filter))).sort()
let failed = 0
for (const file of files) {
  const name = file.replace(/\.json$/, '')
  const started = Date.now()
  try {
    const dataUrl = await page.evaluate(async (scenePath) => window.renderSheet(scenePath), `/scene/${encodeURIComponent(file)}`)
    const png = Buffer.from(dataUrl.split(',')[1], 'base64')
    fs.writeFileSync(path.join(pngDir, `${name}.png`), png)
    console.log(`ok   ${name}.png (${((Date.now() - started) / 1000).toFixed(1)}s)`)
  } catch (err) {
    failed++
    console.log(`FAIL ${name}: ${err.message.split('\n')[0]}`)
  }
}
await browser.close()
server.close()
process.exit(failed ? 1 : 0)
