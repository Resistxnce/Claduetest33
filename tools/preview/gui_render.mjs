// Draws the ScreenGui JSON from gui.luau into PNG screenshots, one per screen,
// at the screen's viewport size (1280x720 unless the screens file says
// otherwise), so a menu can be checked without opening Studio.
//
//   node tools/preview/gui_render.mjs <jsonDir> <pngDir> [nameFilter]
//
// Layout and drawing happen in gui_page.html inside headless Chromium
// (Playwright). Problems it notices (text that doesn't fit, things off
// screen, game errors from the Lune run) are printed under each screen.
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
  console.log('usage: node tools/preview/gui_render.mjs <jsonDir> <pngDir> [nameFilter]')
  process.exit(2)
}
fs.mkdirSync(pngDir, { recursive: true })

const IMAGE_TYPES = { '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.webp': 'image/webp' }
const server = http.createServer((req, res) => {
  const url = new URL(req.url, 'http://localhost')
  let file
  let type = 'text/html'
  if (url.pathname === '/') file = path.join(here, 'gui_page.html')
  else if (url.pathname === '/file') {
    // Backdrop pictures named in the JSON
    file = url.searchParams.get('path')
    type = IMAGE_TYPES[path.extname(file || '').toLowerCase()]
    if (!type) file = null
  }
  if (!file || !fs.existsSync(file)) {
    res.writeHead(404)
    res.end()
    return
  }
  res.writeHead(200, { 'Content-Type': type })
  fs.createReadStream(file).pipe(res)
})
await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve))
const port = server.address().port

const browser = await chromium.launch()
const page = await browser.newPage({ viewport: { width: 1280, height: 720 } })
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
    const data = JSON.parse(fs.readFileSync(path.join(jsonDir, file), 'utf8'))
    const [width, height] = data.viewport
    await page.setViewportSize({ width, height })
    const result = await page.evaluate(async (screen) => window.renderScreen(screen), data)
    await page.screenshot({ path: path.join(pngDir, `${name}.png`), clip: { x: 0, y: 0, width, height } })
    console.log(`ok   ${name}.png ${width}x${height} (${((Date.now() - started) / 1000).toFixed(1)}s)`)
    const errors = Array.isArray(data.errors) ? data.errors : []
    for (const text of errors) console.log(`     [client error] ${text.split('\n')[0]}`)
    const warnings = [...(Array.isArray(data.warnings) ? data.warnings : []), ...result.warnings]
    for (const text of warnings.slice(0, 40)) console.log(`     ! ${text}`)
    if (warnings.length > 40) console.log(`     ! ...and ${warnings.length - 40} more`)
  } catch (err) {
    failed++
    console.log(`FAIL ${name}: ${err.message.split('\n')[0]}`)
  }
}
await browser.close()
server.close()
process.exit(failed ? 1 : 0)
