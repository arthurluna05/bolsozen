// Diagnóstico Dart compilado para JS no Chrome real, sem Firebase/emuladores.
const fs = require('node:fs');
const path = require('node:path');
const http = require('node:http');
const {spawn} = require('node:child_process');
const script = path.resolve('build/m5-1-money-probe.js');
if (!fs.existsSync(script)) throw Error('COMPILE_DART_PROBE_FIRST');
const html = '<!doctype html><html><body><pre id="result"></pre><script>' +
  'self.dartPrint=console.log=function(text){if(typeof text==="string"&&text.startsWith("MONEY_PRECISION "))' +
  'document.getElementById("result").textContent=text.slice(16);};' +
  '</script><script src="/probe.js"></script></body></html>';
const server = http.createServer((req, res) => {
  if (req.url === '/probe.js') { res.setHeader('Content-Type', 'text/javascript'); res.end(fs.readFileSync(script)); }
  else if (req.url === '/') { res.setHeader('Content-Type', 'text/html; charset=utf-8'); res.end(html); }
  else {res.statusCode = 404; res.end();}
});
server.on('error', () => {console.error('LOCAL_PROBE_SERVER_ERROR'); process.exitCode = 1;});
server.listen(0, '127.0.0.1', () => {
  const chrome = path.join(process.env.PROGRAMFILES, 'Google/Chrome/Application/chrome.exe');
  const child = spawn(chrome, ['--headless', '--disable-gpu', '--disable-background-networking',
    '--no-first-run', '--no-default-browser-check', '--dump-dom', '--timeout=15000',
    '--user-data-dir=' + path.resolve('build/m5-1-chrome-profile'),
    `http://127.0.0.1:${server.address().port}/`], {windowsHide: true});
  let dom = '', memoryFailure = false;
  child.stdout.on('data', chunk => {dom += chunk.toString();});
  child.stderr.on('data', chunk => {if (/Out of memory|OOM/i.test(chunk.toString())) memoryFailure = true;});
  const timer = setTimeout(() => {child.kill();}, 30000);
  child.on('error', () => {clearTimeout(timer); server.close(); console.error('CHROME_START_FAILED'); process.exitCode = 1;});
  child.on('exit', code => {
    clearTimeout(timer); server.close();
    try {
      if (memoryFailure) throw Error('BROWSER_MEMORY_FAILURE_NO_RETRY');
      if (code !== 0) throw Error('CHROME_EXIT_FAILED');
      const encoded = /<pre id="result">([\s\S]*?)<\/pre>/.exec(dom)?.[1];
      if (!encoded) throw Error('BROWSER_PROBE_RESULT_MISSING');
      const result = JSON.parse(encoded.replaceAll('&quot;', '"').replaceAll('&amp;', '&').replaceAll('&lt;', '<').replaceAll('&gt;', '>'));
      if (result.cases?.length !== 8) throw Error('INCOMPLETE_BROWSER_PROBE');
      fs.writeFileSync('build/m5-1-money-chrome.json', JSON.stringify(result, null, 2));
      console.log(JSON.stringify({browser: 'Chrome headless', engine: 'Dart dart2js', cases: result.cases.length,
        precisionLossDetected: result.precisionLossDetected,
        differingCases: result.cases.filter(c => !c.parseExact).map(c => ({expected: c.expectedCents, actual: c.parsedCents, formatted: c.formatted}))}));
    } catch (error) {console.error(error.message); process.exitCode = 1;}
  });
});
