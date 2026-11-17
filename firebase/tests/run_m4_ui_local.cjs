// UI Flutter real + SDKs clientes nos emuladores; nenhuma credencial nos logs.
const {spawn} = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');
const {randomBytes} = require('node:crypto');
const {isConfirmedProfile} = require('./m4_ui_assertions.cjs');
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
const output = path.resolve('build/m4-6-web');
const results = [];
let child, browser, pageSocket, failure = null;
if (!process.argv.includes('--execute-local')) {
  console.log('Desabilitado: exige emulators:exec demo-bolsozen e --execute-local.'); process.exit(0);
}
if (process.env.GCLOUD_PROJECT !== 'demo-bolsozen' ||
    process.env.FIREBASE_AUTH_EMULATOR_HOST !== '127.0.0.1:9099' ||
    process.env.FIRESTORE_EMULATOR_HOST !== '127.0.0.1:8080') {
  console.error('LOCAL_UI_ENV_REQUIRED'); process.exit(1);
}
fs.mkdirSync(output, {recursive: true});
function record(name, passed = true) {
  results.push({name, passed});
  fs.writeFileSync(path.join(output, 'results.json'), JSON.stringify({project: 'demo-bolsozen',
    origin: 'http://localhost:7366', sdk: 'FlutterFire UI; Node Firebase Auth only for missing-profile fixture',
    remoteOperations: false, status: 'running', results}, null, 2));
  console.log(JSON.stringify({check: name, passed}));
}
function cdp(ws) {
  let id = 0;
  const pending = new Map();
  ws.addEventListener('message', event => {
    const m = JSON.parse(event.data);
    if (pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); }
  });
  return (method, params = {}) => new Promise((resolve, reject) => {
    const request = ++id;
    const timer = setTimeout(() => { pending.delete(request); reject(Error('CDP_TIMEOUT')); }, 15000);
    pending.set(request, m => { clearTimeout(timer); m.error ? reject(Error('CDP_ERROR')) : resolve(m.result); });
    ws.send(JSON.stringify({id: request, method, params}));
  });
}
async function socket(url) {
  const ws = new WebSocket(url);
  await new Promise((resolve, reject) => { ws.addEventListener('open', resolve, {once: true}); ws.addEventListener('error', reject, {once: true}); });
  return ws;
}
(async () => {
  const command = 'flutter run -d chrome --no-pub --target=integration_test/m4_ui_local_app.dart ' +
    '--web-port=7366 --web-browser-debug-port=9226 --web-browser-flag=--headless --web-browser-flag=--disable-gpu ' +
    '--dart-define=M4_UI_LOCAL=true --dart-define=M4_EMULATOR_PROJECT=demo-bolsozen ' +
    '--dart-define=M4_AUTH_ENDPOINT=127.0.0.1:9099 --dart-define=M4_FIRESTORE_ENDPOINT=127.0.0.1:8080';
  child = spawn('cmd.exe', ['/d', '/s', '/c', command], {stdio: ['pipe', 'pipe', 'pipe'], windowsHide: true});
  child.stdin.on('error', () => {});
  // Somente diagnóstico sanitizado; não gravar URLs de depurador ou exceções brutas.
  let oom = false;
  const inspect = chunk => { if (/Out of memory|Java heap space/i.test(chunk.toString())) oom = true; };
  child.stdout.on('data', inspect); child.stderr.on('data', inspect);
  let pages;
  for (let i = 0; i < 150; i++) {
    if (oom) throw Error('OUT_OF_MEMORY_STOP_NO_RETRY');
    try { pages = await (await fetch('http://127.0.0.1:9226/json/list')).json(); } catch {}
    if (pages?.some(p => p.url.startsWith('http://localhost:7366/'))) break;
    await delay(1000);
  }
  const page = pages?.find(p => p.type === 'page' && p.url.startsWith('http://localhost:7366/'));
  if (!page) throw Error('LOCAL_BROWSER_NOT_READY');
  browser = await socket((await (await fetch('http://127.0.0.1:9226/json/version')).json()).webSocketDebuggerUrl);
  pageSocket = await socket(page.webSocketDebuggerUrl);
  const send = cdp(pageSocket);
  await send('Page.enable'); await send('Runtime.enable'); await send('Accessibility.enable');
  await send('Emulation.setDeviceMetricsOverride', {width: 390, height: 844, deviceScaleFactor: 1, mobile: false});
  async function nodes() {
    await send('Runtime.evaluate', {expression: `(()=>{const walk=r=>{for(const e of r.querySelectorAll('*')){if(e.getAttribute('aria-label')==='Enable accessibility'){e.click();return;}if(e.shadowRoot)walk(e.shadowRoot);}};walk(document);})()`});
    return (await send('Accessibility.getFullAXTree')).nodes.filter(n => !n.ignored);
  }
  async function wait(label, timeout = 45000) {
    const end = Date.now() + timeout;
    while (Date.now() < end) {
      if (oom) throw Error('OUT_OF_MEMORY_STOP_NO_RETRY');
      if ((await nodes()).some(n => n.name?.value === label)) return;
      await delay(250);
    }
    throw Error('UI_EXPECTATION_TIMEOUT');
  }
  async function assertAbsent(label, name) {
    if ((await nodes()).some(n => n.name?.value === label)) throw Error('PRIVATE_DATA_EXPOSED_STOP');
    record(name);
  }
  async function profile(name, email) {
    const end = Date.now() + 45000;
    while (Date.now() < end) {
      if (oom) throw Error('OUT_OF_MEMORY_STOP_NO_RETRY');
      if (isConfirmedProfile(await nodes(), name, email)) return;
      await delay(250);
    }
    throw Error('UI_EXPECTATION_TIMEOUT');
  }
  async function click(label, role = 'button') {
    const n = (await nodes()).find(n => n.name?.value === label && n.role?.value === role && n.backendDOMNodeId);
    if (!n) throw Error('CONTROL_NOT_FOUND');
    if (role === 'textbox') {
      const q = (await send('DOM.getBoxModel', {backendNodeId: n.backendDOMNodeId})).model.content;
      const x = (q[0] + q[4]) / 2, y = (q[1] + q[5]) / 2;
      await send('Input.dispatchMouseEvent', {type: 'mousePressed', x, y, button: 'left', clickCount: 1});
      await send('Input.dispatchMouseEvent', {type: 'mouseReleased', x, y, button: 'left', clickCount: 1});
    } else {
      const object = (await send('DOM.resolveNode', {backendNodeId: n.backendDOMNodeId})).object.objectId;
      await send('Runtime.callFunctionOn', {objectId: object, functionDeclaration: 'function(){this.click();}'});
    }
    await delay(150);
  }
  async function fill(label, text) {
    await click(label, 'textbox');
    await send('Input.dispatchKeyEvent', {type: 'keyDown', key: 'a', code: 'KeyA', modifiers: 2, windowsVirtualKeyCode: 65});
    await send('Input.dispatchKeyEvent', {type: 'keyUp', key: 'a', code: 'KeyA', modifiers: 2, windowsVirtualKeyCode: 65});
    await send('Input.insertText', {text});
  }
  async function capture(name) {
    const shot = await send('Page.captureScreenshot', {format: 'png'});
    fs.writeFileSync(path.join(output, `${name}.png`), Buffer.from(shot.data, 'base64'));
  }
  async function welcome() { await wait('Entrar'); await assertAbsent('Perfil', 'public_gate_hides_profile'); }
  async function logout() { await click('Sair'); await welcome(); }
  const emailA = 'm46-ui-a@example.test', emailB = 'm46-ui-b@example.test', emailC = 'm46-ui-c@example.test';
  const password = ` M46a!${randomBytes(18).toString('hex')} `;
  await welcome(); record('firebase_bootstrap_public_ui'); await capture('web-boas-vindas');
  await click('Criar conta'); await wait('Criar sua conta');
  await click('Criar conta'); await wait('Informe um e-mail válido.'); record('registration_empty_validation');
  await fill('Nome', 'TESTE LOCAL M4.6 A'); await fill('E-mail', emailA);
  await fill('Senha', password); await fill('Confirmar senha', password);
  await capture('web-cadastro-local'); await click('Criar conta'); await profile('TESTE LOCAL M4.6 A', emailA);
  record('registration_firestore_profile_confirmed'); await capture('web-perfil-local');
  await send('Page.reload', {ignoreCache: false}); await delay(1500); await profile('TESTE LOCAL M4.6 A', emailA);
  record('same_origin_reload_restores_session_and_profile');
  await logout(); record('logout_confirmed');
  // Histórico real, mesma instância/origem e armazenamento do navegador.
  await send('Page.navigate', {url: 'about:blank'}); await delay(300);
  const history = await send('Page.getNavigationHistory');
  await send('Page.navigateToHistoryEntry', {entryId: history.entries[history.currentIndex - 1].id});
  await welcome(); await assertAbsent('TESTE LOCAL M4.6 A', 'browser_back_after_logout_hides_previous_profile');
  await send('Page.navigateToHistoryEntry', {entryId: history.entries[history.currentIndex].id}); await delay(200);
  await send('Page.navigateToHistoryEntry', {entryId: history.entries[history.currentIndex - 1].id});
  await welcome(); record('browser_forward_back_remains_public');
  await click('Entrar'); await wait('Entrar no BolsoZen');
  await fill('E-mail', emailA); await fill('Senha', 'senha incorreta local'); await click('Entrar');
  await wait('E-mail ou senha inválidos.'); record('wrong_password_neutral_message');
  await fill('Senha', password); await click('Entrar'); await profile('TESTE LOCAL M4.6 A', emailA); record('correct_login_same_account');
  await logout(); await click('Entrar'); await wait('Entrar no BolsoZen');
  await click('Esqueci minha senha'); await wait('Recuperar senha'); await fill('E-mail', emailA);
  await click('Enviar link de recuperação');
  await wait('Se houver uma conta com este e-mail, você receberá as instruções para redefinir sua senha.');
  record('existing_email_reset_neutral_in_emulator'); await capture('web-recuperacao-local');
  await click('Voltar para entrar'); await wait('Entrar no BolsoZen');
  await click('Criar conta'); await wait('Criar sua conta');
  await fill('Nome', 'TESTE LOCAL M4.6 B'); await fill('E-mail', emailB);
  await fill('Senha', password); await fill('Confirmar senha', password);
  await click('Criar conta'); await profile('TESTE LOCAL M4.6 B', emailB);
  await assertAbsent('TESTE LOCAL M4.6 A', 'second_user_hides_previous_name');
  await assertAbsent(emailA, 'second_user_hides_previous_email'); await logout();
  // Fixture só de Authentication, SDK cliente Node, explicitamente no emulador.
  const {initializeApp, deleteApp} = require('firebase/app');
  const {getAuth, connectAuthEmulator, createUserWithEmailAndPassword, signOut} = require('firebase/auth');
  const fixtureApp = initializeApp({apiKey: 'demo-api-key', projectId: 'demo-bolsozen'}, 'm46-node-fixture');
  const fixtureAuth = getAuth(fixtureApp);
  connectAuthEmulator(fixtureAuth, 'http://127.0.0.1:9099', {disableWarnings: true});
  await createUserWithEmailAndPassword(fixtureAuth, emailC, password); await signOut(fixtureAuth); await deleteApp(fixtureApp);
  await click('Entrar'); await wait('Entrar no BolsoZen');
  await fill('E-mail', emailC); await fill('Senha', password); await click('Entrar'); await wait('Completar perfil');
  record('real_account_missing_firestore_profile'); await capture('web-completar-perfil-local');
  await send('Page.reload', {ignoreCache: false}); await delay(1500); await wait('Completar perfil');
  record('reload_preserves_partial_account_without_duplicate_registration');
  await fill('Nome', 'TESTE LOCAL M4.6 C'); await click('Salvar perfil'); await profile('TESTE LOCAL M4.6 C', emailC);
  record('complete_profile_confirmed_via_flutter_repository'); await logout();
  await click('Entrar'); await wait('Entrar no BolsoZen'); await fill('E-mail', emailA); await fill('Senha', password);
  await send('Network.enable');
  await send('Network.emulateNetworkConditions', {offline: true, latency: 0, downloadThroughput: -1, uploadThroughput: -1});
  await click('Entrar'); await wait('Não foi possível conectar. Verifique sua conexão e tente novamente.', 60000);
  record('offline_login_explicit_network_failure');
  await send('Network.emulateNetworkConditions', {offline: false, latency: 0, downloadThroughput: -1, uploadThroughput: -1});
  await click('Entrar'); await profile('TESTE LOCAL M4.6 A', emailA); record('network_recovery_without_losing_form');
  await logout();
})().catch(error => { failure = error.message === 'PRIVATE_DATA_EXPOSED_STOP' || error.message === 'OUT_OF_MEMORY_STOP_NO_RETRY'
  ? error.message : ['UI_EXPECTATION_TIMEOUT','CONTROL_NOT_FOUND','LOCAL_BROWSER_NOT_READY','CDP_TIMEOUT','CDP_ERROR'].includes(error.message) ? error.message : 'LOCAL_UI_OPERATION_FAILED';
  console.error(failure);
}).finally(async () => {
  pageSocket?.close();
  if (browser) { try { await cdp(browser)('Browser.close'); } catch {} browser.close(); }
  if (child) {
    child.stdin.write('q\n');
    const done = new Promise(resolve => child.once('exit', resolve));
    if (child.exitCode === null) {
      const timer = setTimeout(() => spawn('taskkill', ['/PID', String(child.pid), '/T', '/F'], {windowsHide: true, stdio: 'ignore'}), 20000);
      await done; clearTimeout(timer);
    }
  }
  const report = {project: 'demo-bolsozen', origin: 'http://localhost:7366', remoteOperations: false,
    status: failure ? 'interrupted' : 'passed', failure, checksPassed: results.filter(r => r.passed).length, results,
    limitation: 'Browser reload is not Android process restart; reset delivery only local emulator; missing-profile fixture, when reached, uses Node client SDK.'};
  fs.writeFileSync(path.join(output, 'results.json'), JSON.stringify(report, null, 2));
  console.log(JSON.stringify({result: true, status: report.status, checksPassed: report.checksPassed, failure}));
  process.exitCode = failure ? 1 : 0;
});
