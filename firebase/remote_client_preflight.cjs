// Apenas APIs de gerenciamento: configuração, regras, índice e lookup por email.
// Credenciais da CLI nunca são usadas para operações em documentos Firestore.
const path = require('node:path');
const fs = require('node:fs');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const project = 'bolsozen-f2f35';
const appId = '1:691532851056:web:4590b99cc5ded05cc0d1b5';
const emails = ['bolsozen-m3r20261117a01-a@example.com', 'bolsozen-m3r20261117a01-b@example.com'];
const canonical = value => value.replace(/^\uFEFF/, '').replace(/\r\n/g, '\n').trim();

module.exports = async function preflight() {
  const lib = path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib');
  const {getGlobalDefaultAccount} = require(path.join(lib, 'auth.js'));
  const {requireAuth} = require(path.join(lib, 'requireAuth.js'));
  const {Client} = require(path.join(lib, 'apiv2.js'));
  const account = getGlobalDefaultAccount();
  assert.ok(account, 'CLI_LOGIN_REQUIRED');
  await requireAuth({project, user: account.user, tokens: account.tokens, nonInteractive: true});
  // A CLI modifica as opções recebidas; não reutilizar objeto entre GET e POST.
  const quiet = () => ({skipLog: {reqBody: true, resBody: true}});
  const rules = new Client({urlPrefix: 'https://firebaserules.googleapis.com', apiVersion: 'v1'});
  const release = (await rules.get(`/projects/${project}/releases/cloud.firestore`, quiet())).body;
  const files = (await rules.get(`/${release.rulesetName}`, quiet())).body.source.files;
  const remote = files.find(file => file.name === 'firestore.rules');
  const local = fs.readFileSync(path.join(__dirname, '../firestore.rules'), 'utf8');
  assert.ok(remote && canonical(remote.content) === canonical(local), 'REMOTE_RULES_DIFFER');
  const firestore = new Client({urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1'});
  const indexes = (await firestore.get(`/projects/${project}/databases/(default)/collectionGroups/transactions/indexes`, quiet())).body.indexes || [];
  const expected = [
    {fieldPath: 'occurredAt', order: 'DESCENDING'},
    {fieldPath: 'createdAt', order: 'DESCENDING'},
    {fieldPath: '__name__', order: 'ASCENDING'},
  ];
  const index = indexes.find(value => value.queryScope === 'COLLECTION' && JSON.stringify(value.fields) === JSON.stringify(expected));
  assert.equal(index?.state, 'READY', 'INDEX_NOT_READY');
  const auth = new Client({urlPrefix: 'https://identitytoolkit.googleapis.com', apiVersion: 'v1'});
  const users = (await auth.post(`/projects/${project}/accounts:lookup`, {email: emails, targetProjectId: project}, quiet())).body.users || [];
  assert.equal(users.length, 0, 'PLANNED_ACCOUNT_ALREADY_EXISTS_ABORT');
  const management = new Client({urlPrefix: 'https://firebase.googleapis.com', apiVersion: 'v1beta1'});
  const options = (await management.get(`/projects/${project}/webApps/${appId}/config`, quiet())).body;
  assert.equal(options.projectId, project);
  assert.equal(options.appId, appId);
  assert.equal(typeof options.apiKey, 'string');
  return {
    options,
    summary: {project, appId, accountsAbsent: emails, rulesMatch: true,
      rulesSha256: crypto.createHash('sha256').update(canonical(local)).digest('hex'),
      index: index.name, indexState: index.state},
  };
};

if (require.main === module) {
  module.exports().then(result => console.log(JSON.stringify(result.summary, null, 2))).catch(error => {
    console.error(JSON.stringify({preflight: 'failed', type: error.name, status: error.status || null,
      check: error.name === 'AssertionError' ? String(error.message).split('\n')[0] : null}));
    process.exitCode = 1;
  });
}
