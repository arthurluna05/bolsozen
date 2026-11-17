// Diagnóstico somente de leitura das APIs de gerenciamento, usando login da CLI.
// Não acessa documentos, não usa Admin SDK e nunca imprime credenciais.
const path = require('node:path');
const fs = require('node:fs');
const crypto = require('node:crypto');
const cliLib = path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib');
const {getGlobalDefaultAccount} = require(path.join(cliLib, 'auth.js'));
const {requireAuth} = require(path.join(cliLib, 'requireAuth.js'));
const {Client} = require(path.join(cliLib, 'apiv2.js'));
const project = 'bolsozen-f2f35';
const canonical = text => text.replace(/^\uFEFF/, '').replace(/\r\n/g, '\n').trim();
const sha = text => crypto.createHash('sha256').update(canonical(text)).digest('hex');

(async () => {
  const account = getGlobalDefaultAccount();
  if (!account) throw new Error('CLI_LOGIN_REQUIRED');
  await requireAuth({project, user: account.user, tokens: account.tokens, nonInteractive: true});
  const firestore = new Client({urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1'});
  const rules = new Client({urlPrefix: 'https://firebaserules.googleapis.com', apiVersion: 'v1'});
  const indexResponse = await firestore.get(`/projects/${project}/databases/(default)/collectionGroups/transactions/indexes`, {skipLog: {resBody: true}});
  const releaseResponse = await rules.get(`/projects/${project}/releases/cloud.firestore`, {skipLog: {resBody: true}});
  const release = releaseResponse.body;
  const sourceResponse = await rules.get(`/${release.rulesetName}`, {skipLog: {resBody: true}});
  const remoteFile = sourceResponse.body.source.files.find(file => file.name === 'firestore.rules');
  const local = fs.readFileSync(path.join(__dirname, '../firestore.rules'), 'utf8');
  const output = {
    project,
    rules: {release: release.name, ruleset: release.rulesetName, publishedAt: release.updateTime || release.createTime,
      matchesLocal: !!remoteFile && canonical(remoteFile.content) === canonical(local), localSha256: sha(local),
      remoteSha256: remoteFile ? sha(remoteFile.content) : null},
    indexes: (indexResponse.body.indexes || []).map(index => ({name: index.name, state: index.state, queryScope: index.queryScope, fields: index.fields})),
  };
  console.log(JSON.stringify(output, null, 2));
})().catch(error => {
  console.error(JSON.stringify({preflight: 'failed', status: error.status || error.code || null, type: error.name}));
  process.exitCode = 1;
});
