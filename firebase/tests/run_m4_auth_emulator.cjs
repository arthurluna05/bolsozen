// Supervisor de um runner Flutter/Dart real, exclusivamente em emuladores locais.
const {spawn} = require('node:child_process');

if (!process.argv.includes('--execute-local')) {
  console.log('Desabilitado: usar emulators:exec com demo-bolsozen e --execute-local.');
  process.exit(0);
}
if (process.env.GCLOUD_PROJECT !== 'demo-bolsozen' ||
    process.env.FIREBASE_AUTH_EMULATOR_HOST !== '127.0.0.1:9099' ||
    process.env.FIRESTORE_EMULATOR_HOST !== '127.0.0.1:8080') {
  console.error('LOCAL_EMULATOR_ENV_REQUIRED_ABORT');
  process.exit(1);
}
const command = 'flutter run -d chrome --no-pub --target=integration_test/m4_auth_emulator.dart ' +
  '--web-port=7362 --web-browser-flag=--headless --web-browser-flag=--disable-gpu ' +
  '--dart-define=M4_AUTH_EMULATOR=true --dart-define=M4_EMULATOR_PROJECT=demo-bolsozen ' +
  '--dart-define=M4_AUTH_ENDPOINT=127.0.0.1:9099 --dart-define=M4_FIRESTORE_ENDPOINT=127.0.0.1:8080';
const child = spawn('cmd.exe', ['/d', '/s', '/c', command], {stdio: ['pipe', 'pipe', 'pipe'], windowsHide: true});
let buffer = '', result, stopTimer;
const stop = () => {
  child.stdin.write('q\n');
  // Somente a árvore deste processo filho; nunca outros builds/navegadores.
  stopTimer = setTimeout(() => {
    spawn('taskkill', ['/PID', String(child.pid), '/T', '/F'], {windowsHide: true, stdio: 'ignore'});
  }, 20000);
};
const timeout = setTimeout(() => {console.error('LOCAL_RUN_TIMEOUT'); stop();}, 240000);
child.stdout.on('data', chunk => {
  buffer += chunk.toString();
  const lines = buffer.split(/\r?\n/); buffer = lines.pop();
  for (const line of lines) {
    const marker = line.indexOf('M4_EMULATOR ');
    if (marker < 0) continue; // Não gravar URIs/tokens do depurador ou logs brutos.
    let event;
    try {event = JSON.parse(line.slice(marker + 'M4_EMULATOR '.length));} catch {continue;}
    // Whitelist de evidências, nunca senhas ou tokens.
    console.log(JSON.stringify(event));
    if (event.result && !result) {result = event; clearTimeout(timeout); stop();}
  }
});
child.stderr.on('data', () => {}); // Falhas aparecem como exit code/timeout sanitizados.
child.stdin.on('error', () => {});
child.on('error', () => {console.error('FLUTTER_PROCESS_START_FAILED'); process.exitCode = 1;});
child.on('exit', code => {
  clearTimeout(timeout); clearTimeout(stopTimer);
  const passed = result?.success === true && code === 0;
  console.log(JSON.stringify({runnerExited: true, code, passed}));
  process.exitCode = passed ? 0 : 1;
});
