// Node nativo, sem bibliotecas; conecta apenas ao Chrome local do runner visual.
const fs = require('node:fs');
const path = require('node:path');
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
let browserSocket;
let flushReport;
process.exitCode = 1; // Sem manifesto final, uma interrupção nunca é aprovação.

(async () => {
  const port = process.argv[2];
  if (!/^\d{4,5}$/.test(port || '')) throw Error('LOCAL_CDP_PORT_REQUIRED');
  const pages = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
  const page = pages.find(p => p.type === 'page' && /^http:\/\/(localhost|127\.0\.0\.1):7364\//.test(p.url));
  if (!page) throw Error('LOCAL_VISUAL_RUNNER_NOT_FOUND');
  const ws = new WebSocket(page.webSocketDebuggerUrl);
  browserSocket = ws;
  await new Promise(resolve => ws.addEventListener('open', resolve, {once: true}));
  const pending = new Map(); let id = 0;
  const runtimeErrors = [];
  ws.addEventListener('message', event => {
    const message = JSON.parse(event.data);
    if (message.id && pending.has(message.id)) { pending.get(message.id)(message); pending.delete(message.id); }
    if (message.method === 'Runtime.exceptionThrown') runtimeErrors.push('runtime_exception');
    if (message.method === 'Runtime.consoleAPICalled') {
      const text = message.params.args.map(a => a.value || '').join(' ');
      if (/A RenderFlex overflowed|EXCEPTION CAUGHT BY (WIDGETS|RENDERING)/.test(text)) runtimeErrors.push('flutter_layout_exception');
    }
  });
  const send = (method, params = {}) => new Promise((resolve, reject) => {
    const request = ++id;
    const timeout = setTimeout(() => {pending.delete(request); reject(Error(`CDP_TIMEOUT:${method}`));}, 15000);
    pending.set(request, m => {clearTimeout(timeout); m.error ? reject(Error(m.error.message)) : resolve(m.result);});
    ws.send(JSON.stringify({id: request, method, params}));
  });
  await send('Runtime.enable'); await send('Page.enable'); await send('Accessibility.enable');
  const m45 = process.argv.includes('--m4-5');
  const output = path.resolve(m45 ? 'build/m4-5-visual' : 'build/m4-4-visual'); fs.mkdirSync(output, {recursive: true});
  const manifest = [];
  flushReport = (status, failure = null) => fs.writeFileSync(path.join(output, 'manifest.json'),
    JSON.stringify({runner: 'Flutter Chrome; fakes locais; TESTE VISUAL', remoteFirebase: false,
      status, failure, runtimeErrors, captures: manifest}, null, 2));
  const ax = async () => (await send('Accessibility.getFullAXTree')).nodes.filter(n => !n.ignored);
  async function enableSemantics() {
    await send('Runtime.evaluate', {expression: `(()=>{const walk=r=>{for(const e of r.querySelectorAll('*')){if(e.getAttribute('aria-label')==='Enable accessibility'){e.click();return true;}if(e.shadowRoot&&walk(e.shadowRoot))return true;}return false;};return walk(document);})()`});
  }
  async function waitFor(label) {
    for (let i = 0; i < 80; i++) {
      await enableSemantics();
      if ((await ax()).some(n => n.name?.value === label)) return;
      await delay(250);
    }
    throw Error(`SCREEN_NOT_READY:${label}`);
  }
  async function click(label, role = 'button') {
    const nodes = (await ax()).filter(n => n.name?.value === label && n.role?.value === role && n.backendDOMNodeId);
    for (const node of nodes) {
      const result = await send('DOM.resolveNode', {backendNodeId: node.backendDOMNodeId});
      if (role === 'textbox') {
        const box = (await send('DOM.getBoxModel', {backendNodeId: node.backendDOMNodeId})).model.content;
        const x = (box[0] + box[4]) / 2, y = (box[1] + box[5]) / 2;
        await send('Input.dispatchMouseEvent', {type: 'mousePressed', x, y, button: 'left', clickCount: 1});
        await send('Input.dispatchMouseEvent', {type: 'mouseReleased', x, y, button: 'left', clickCount: 1});
      } else {
        await send('Runtime.callFunctionOn', {objectId: result.object.objectId, functionDeclaration: 'function(){this.click();}'});
      }
      await delay(200); return;
    }
    throw Error(`CONTROL_NOT_FOUND:${label}/${role}`);
  }
  async function viewport(width) {
    await send('Emulation.setDeviceMetricsOverride', {width, height: 900, deviceScaleFactor: 1, mobile: false});
    await delay(350);
  }
  async function capture(name, width, scale = 1, keyboard = 0) {
    await viewport(width);
    const shot = await send('Page.captureScreenshot', {format: 'png'});
    const file = `${name}-${width}.png`; fs.writeFileSync(path.join(output, file), Buffer.from(shot.data, 'base64'));
    manifest.push({file, width, height: 900, scale, simulatedKeyboardInset: keyboard,
      labels: (await ax()).filter(n => n.name?.value).map(n => n.name.value)});
    flushReport('running');
    console.log(JSON.stringify({captured: file, scale, keyboard}));
  }
  async function load(screen = 'public', scale = 1, keyboard = 0) {
    await send('Page.navigate', {url: `http://localhost:7364/?screen=${screen}&scale=${scale}&keyboard=${keyboard}`});
    await delay(900);
    await waitFor(screen === 'profile' ? 'Perfil' : screen === 'missing' ? 'Completar perfil' : screen === 'error' ? 'Não foi possível carregar sua conta' : 'Entrar');
  }
  if (m45) {
    // Uma única página/compilação, sem reloads ou criação de conta Firebase.
    await viewport(390); await waitFor('Entrar');
    await click('Criar conta'); await waitFor('Criar sua conta');
    for (const width of [360, 390, 412]) await capture('cadastro', width);
    await click('Já tenho conta'); await waitFor('Entrar no BolsoZen');
    await click('E-mail', 'textbox'); await send('Input.insertText', {text: 'visual@example.test'});
    await click('Senha', 'textbox'); await send('Input.insertText', {text: 'senha visual local'});
    await click('Entrar'); await waitFor('Completar perfil');
    for (const width of [360, 390, 412]) await capture('completar-perfil-teste', width);
    flushReport(runtimeErrors.length ? 'failed' : 'm4_5_complete');
    ws.close(); process.exitCode = runtimeErrors.length ? 1 : 0; return;
  }
  await viewport(390); await waitFor('Entrar');
  await click('Entrar'); await waitFor('Entrar no BolsoZen');
  for (const width of [360, 390, 412]) await capture('login', width);
  await click('Esqueci minha senha'); await waitFor('Recuperar senha');
  for (const width of [360, 390, 412]) await capture('recuperacao', width);
  await click('E-mail', 'textbox');
  await send('Input.insertText', {text: 'visual@example.test'});
  await click('Enviar link de recuperação');
  await waitFor('Se houver uma conta com este e-mail, você receberá as instruções para redefinir sua senha.');
  await capture('recuperacao-confirmacao-teste', 390);
  await load('profile');
  for (const width of [360, 390, 412]) await capture('perfil-teste', width);
  // Modo básico limita reloads do DWDS em máquinas de 8 GB; extensões opcionais.
  if (!process.argv.includes('--extended')) {
    flushReport(runtimeErrors.length ? 'failed' : 'basic_complete');
    ws.close();
    process.exitCode = runtimeErrors.length ? 1 : 0;
    return;
  }
  for (const screen of ['missing', 'error']) { await load(screen); await capture(screen, 390); }
  await load('public', 2); await click('Entrar'); await waitFor('Entrar no BolsoZen');
  await capture('login-texto2', 390, 2);
  await click('Esqueci minha senha'); await waitFor('Recuperar senha'); await capture('recuperacao-texto2', 390, 2);
  await load('profile', 2); await capture('perfil-texto2', 390, 2);
  await load('public', 1, 300); await click('Entrar'); await waitFor('Entrar no BolsoZen');
  await click('E-mail', 'textbox'); await capture('login-teclado-simulado', 390, 1, 300);
  await click('Esqueci minha senha'); await waitFor('Recuperar senha');
  await click('E-mail', 'textbox'); await capture('recuperacao-teclado-simulado', 390, 1, 300);
  flushReport(runtimeErrors.length ? 'failed' : 'extended_complete');
  ws.close();
  if (runtimeErrors.length) throw Error('BROWSER_RUNTIME_ERRORS_RECORDED');
  process.exitCode = 0;
})().catch(error => {flushReport?.('interrupted', error.message); browserSocket?.close(); console.error(error.message); process.exitCode = 1;});
