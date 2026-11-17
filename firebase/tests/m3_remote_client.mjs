// SDK cliente Web em Node. Nenhum Admin SDK nem acesso financeiro via OAuth CLI.
import assert from 'node:assert/strict';
import {randomBytes} from 'node:crypto';
import {mkdirSync, writeFileSync, appendFileSync, existsSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import preflight from '../remote_client_preflight.cjs';

const run = 'm3r20261117a01';
const journal = fileURLToPath(new URL(`../../build/${run}-js-events.jsonl`, import.meta.url));
const reportFile = fileURLToPath(new URL(`../../build/${run}-js-report.json`, import.meta.url));
let active = false;
let passed = 0;
let failed = 0;
let securityFailure = false;
const checks = [];
const accounts = {};
const tracked = new Map();
const removed = [];
let profilePath;
let profileMayExist = false;
let profileRemaining = false;

function record(event, fields = {}) {
  const line = JSON.stringify({run, at: new Date().toISOString(), event, ...fields});
  console.log(line);
  if (active) appendFileSync(journal, `${line}\n`);
}
function safeError(error) {
  return {type: error?.name || 'Error', code: /^[a-z-]+(?:\/[a-z-]+)?$/.test(error?.code || '') ? error.code : null};
}
async function check(name, operation) {
  try {
    await operation();
    passed++;
    checks.push({name, result: 'passed'});
    record('check_passed', {name});
  } catch (error) {
    failed++;
    checks.push({name, result: 'failed', ...safeError(error)});
    record('check_failed', {name, ...safeError(error)});
    throw error;
  }
}
async function denied(name, operation) {
  await check(name, async () => {
    try {
      await operation();
    } catch (error) {
      assert.equal(error.code, 'permission-denied', name);
      record('permission_denied', {name, code: error.code});
      return;
    }
    securityFailure = true;
    record('SECURITY_FAILURE_STOP', {name});
    throw new Error('UNAUTHORIZED_OPERATION_ALLOWED');
  });
}

async function execute() {
  if (!process.argv.includes('--execute-approved')) {
    record('disabled', {message: 'Nenhuma conexão ou mutação; execução requer --execute-approved e --allow-profile-remainder.'});
    return;
  }
  assert.ok(process.argv.includes('--allow-profile-remainder'), 'PROFILE_REMAINDER_APPROVAL_REQUIRED');
  assert.ok(!process.env.FIRESTORE_EMULATOR_HOST && !process.env.FIREBASE_AUTH_EMULATOR_HOST, 'REMOTE_ONLY_ABORT_EMULATOR_ENV');
  assert.ok(!existsSync(journal), 'RUN_JOURNAL_EXISTS_ABORT_NO_AUTOMATIC_RERUN');
  const {options, summary} = await preflight();
  record('preflight_passed', summary);
  mkdirSync(fileURLToPath(new URL('../../build/', import.meta.url)), {recursive: true});
  active = true;
  record('execution_started', {sdk: 'Firebase JavaScript client', dartRepositoriesTested: false});

  const core = await import('firebase/app');
  const auth = await import('firebase/auth');
  const db = await import('firebase/firestore');
  core.setLogLevel('silent');
  db.setLogLevel('silent');
  const clients = [];
  let root;
  let transactionRefs = [];
  let budgetRef;
  let overallPassed = false;
  const leftovers = [];
  try {
    for (const role of ['a', 'b', 'guest']) {
      const app = core.initializeApp(options, `${run}-js-${role}`);
      const identity = auth.initializeAuth(app, {persistence: auth.inMemoryPersistence});
      const store = db.initializeFirestore(app, {localCache: db.memoryLocalCache()});
      clients.push({role, app, identity, store});
      assert.equal(identity.currentUser, null);
    }
    for (const client of clients.slice(0, 2)) {
      await check(`Authentication ${client.role}: criar e entrar`, async () => {
        const email = `bolsozen-${run}-${client.role}@example.com`;
        const password = `M3!aA9_${randomBytes(24).toString('hex')}`;
        const credential = await auth.createUserWithEmailAndPassword(client.identity, email, password);
        accounts[client.role] = {uid: credential.user.uid, email};
        record('account_created', {role: client.role, ...accounts[client.role]});
        await auth.signOut(client.identity);
        const login = await auth.signInWithEmailAndPassword(client.identity, email, password);
        assert.equal(login.user.uid, accounts[client.role].uid);
        assert.equal(client.identity.currentUser.uid, login.user.uid);
      });
    }
    const [a, b, guest] = clients;
    await check('Sessões A/B isoladas e guest sem autenticação', async () => {
      assert.notEqual(accounts.a.uid, accounts.b.uid);
      assert.equal(a.identity.currentUser.uid, accounts.a.uid);
      assert.equal(b.identity.currentUser.uid, accounts.b.uid);
      assert.equal(guest.identity.currentUser, null);
    });
    root = `users/${accounts.a.uid}`;
    profilePath = root;
    const profile = db.doc(a.store, root);
    await check('Perfil A: criar e ler do servidor', async () => {
      assert.equal((await db.getDocFromServer(profile)).exists(), false);
      profileMayExist = true;
      record('profile_planned', {path: root});
      await db.runTransaction(a.store, async tx => {
        assert.equal((await tx.get(profile)).exists(), false);
        tx.set(profile, {displayName: `TESTE M3 A ${run}`, email: accounts.a.email, createdAt: db.serverTimestamp()});
      });
      const restored = await db.getDocFromServer(profile);
      assert.equal(restored.data().email, accounts.a.email);
      assert.equal(restored.data().displayName, `TESTE M3 A ${run}`);
      assert.ok(restored.data().createdAt instanceof db.Timestamp);
      record('profile_created', {path: root});
    });
    const occurredAt = db.Timestamp.fromDate(new Date(2099, 11, 10));
    for (let index = 0; index < 3; index++) {
      await check(`Receita ${index + 1}: criar e ler do servidor`, async () => {
        const ref = db.doc(db.collection(a.store, `${root}/transactions`));
        tracked.set(ref.path, {ref, kind: 'transaction'});
        transactionRefs.push(ref);
        record('transaction_planned', {path: ref.path});
        await db.runTransaction(a.store, async tx => {
          assert.equal((await tx.get(ref)).exists(), false);
          tx.set(ref, {userId: accounts.a.uid, type: 'income', amountCents: (index + 1) * 101,
            categoryId: 'salary', description: `TESTE_M3 ${run} receita ${index + 1}`, occurredAt,
            createdAt: db.serverTimestamp(), updatedAt: db.serverTimestamp()});
        });
        const value = (await db.getDocFromServer(ref)).data();
        assert.equal(value.amountCents, (index + 1) * 101);
        assert.equal(value.userId, accounts.a.uid);
        assert.ok(value.createdAt instanceof db.Timestamp && value.updatedAt instanceof db.Timestamp);
        record('transaction_created', {path: ref.path});
      });
    }
    const primary = transactionRefs[0];
    await check('Receita: editar, consultar novamente e preservar createdAt', async () => {
      const before = (await db.getDocFromServer(primary)).data();
      await db.runTransaction(a.store, async tx => {
        assert.equal((await tx.get(primary)).exists(), true);
        tx.update(primary, {amountCents: 111, description: `TESTE_M3 ${run} receita atualizada`, updatedAt: db.serverTimestamp()});
      });
      const after = (await db.getDocFromServer(primary)).data();
      assert.equal(after.amountCents, 111);
      assert.equal(after.description, `TESTE_M3 ${run} receita atualizada`);
      assert.ok(after.createdAt.isEqual(before.createdAt));
    });
    await check('Consulta ordenada e paginação 2+1+0 sem repetição', async () => {
      const ordered = db.query(db.collection(a.store, `${root}/transactions`),
        db.orderBy('occurredAt', 'desc'), db.orderBy('createdAt', 'desc'), db.orderBy(db.documentId(), 'asc'));
      const full = await db.getDocsFromServer(ordered);
      assert.equal(full.size, 3);
      const first = await db.getDocsFromServer(db.query(ordered, db.limit(2)));
      const cursor1 = first.docs.at(-1);
      const second = await db.getDocsFromServer(db.query(ordered, db.startAfter(cursor1.get('occurredAt'), cursor1.get('createdAt'), cursor1.id), db.limit(2)));
      const cursor2 = second.docs.at(-1);
      const third = await db.getDocsFromServer(db.query(ordered, db.startAfter(cursor2.get('occurredAt'), cursor2.get('createdAt'), cursor2.id), db.limit(2)));
      assert.equal(first.size, 2); assert.equal(second.size, 1); assert.equal(third.size, 0);
      const ids = [...first.docs, ...second.docs].map(item => item.id);
      assert.equal(new Set(ids).size, 3);
      assert.deepEqual(new Set(ids), new Set(transactionRefs.map(ref => ref.id)));
      assert.deepEqual(ids, full.docs.map(item => item.id));
      for (let index = 1; index < full.size; index++) {
        const left = full.docs[index - 1], right = full.docs[index];
        const l = left.get('createdAt'), r = right.get('createdAt');
        assert.ok(l.seconds > r.seconds || (l.seconds === r.seconds && l.nanoseconds > r.nanoseconds) ||
          (l.isEqual(r) && left.id < right.id));
      }
      record('pagination_verified', {pages: [first.size, second.size, third.size], ids});
    });
    budgetRef = db.doc(a.store, `${root}/budgets/2099-12_food`);
    const monthQuery = db.query(db.collection(a.store, `${root}/budgets`), db.where('monthKey', '==', '2099-12'));
    await check('Orçamento: criar e consultar por competência', async () => {
      assert.equal((await db.getDocFromServer(budgetRef)).exists(), false);
      tracked.set(budgetRef.path, {ref: budgetRef, kind: 'budget'});
      record('budget_planned', {path: budgetRef.path});
      await db.runTransaction(a.store, async tx => {
        assert.equal((await tx.get(budgetRef)).exists(), false);
        tx.set(budgetRef, {userId: accounts.a.uid, monthKey: '2099-12', categoryId: 'food', limitCents: 1000,
          createdAt: db.serverTimestamp(), updatedAt: db.serverTimestamp()});
      });
      const result = await db.getDocsFromServer(monthQuery);
      assert.equal(result.size, 1); assert.equal(result.docs[0].get('limitCents'), 1000);
    });
    await check('Orçamento: atualizar e consultar novamente', async () => {
      const before = (await db.getDocFromServer(budgetRef)).data();
      await db.runTransaction(a.store, async tx => {
        assert.equal((await tx.get(budgetRef)).exists(), true);
        tx.update(budgetRef, {limitCents: 1200, updatedAt: db.serverTimestamp()});
      });
      const restored = (await db.getDocsFromServer(monthQuery)).docs[0].data();
      assert.equal(restored.limitCents, 1200); assert.ok(restored.createdAt.isEqual(before.createdAt));
    });
    for (const client of [b, guest]) {
      const role = client.role === 'b' ? 'B' : 'sem autenticação';
      const foreign = db.doc(client.store, primary.path);
      const probePath = `${root}/transactions/${run}-probe-${client.role}`;
      tracked.set(probePath, {ref: db.doc(a.store, probePath), kind: 'probe'});
      await denied(`${role}: ler receita de A`, () => db.getDocFromServer(foreign));
      await denied(`${role}: criar em caminho de A`, () => db.setDoc(db.doc(client.store, probePath), {
        userId: accounts.a.uid, type: 'income', amountCents: 111, categoryId: 'salary',
        description: `TESTE_M3 ${run} acesso indevido`, occurredAt,
        createdAt: db.serverTimestamp(), updatedAt: db.serverTimestamp(),
      }));
      await denied(`${role}: alterar receita de A`, () => db.updateDoc(foreign, {amountCents: 222, updatedAt: db.serverTimestamp()}));
      await denied(`${role}: excluir receita de A`, () => db.deleteDoc(foreign));
      await denied(`${role}: ler perfil de A`, () => db.getDocFromServer(db.doc(client.store, root)));
      await denied(`${role}: ler orçamento de A`, () => db.getDocFromServer(db.doc(client.store, budgetRef.path)));
    }
    await check('Receita permanece íntegra após tentativas indevidas', async () => {
      assert.equal((await db.getDocFromServer(primary)).data().amountCents, 111);
      for (const role of ['b', 'guest']) assert.equal((await db.getDocFromServer(db.doc(a.store, `${root}/transactions/${run}-probe-${role}`))).exists(), false);
    });
    await check('Orçamento: remover e confirmar ausência por documento e consulta', async () => {
      await db.deleteDoc(budgetRef);
      assert.equal((await db.getDocFromServer(budgetRef)).exists(), false);
      assert.equal((await db.getDocsFromServer(monthQuery)).size, 0);
      removed.push(budgetRef.path); tracked.delete(budgetRef.path);
      record('document_removed_verified', {path: budgetRef.path});
    });
    for (let index = 0; index < transactionRefs.length; index++) {
      const ref = transactionRefs[index];
      await check(`Receita ${index + 1}: excluir e confirmar ausência`, async () => {
        await db.deleteDoc(ref);
        assert.equal((await db.getDocFromServer(ref)).exists(), false);
        removed.push(ref.path); tracked.delete(ref.path);
        record('document_removed_verified', {path: ref.path});
      });
    }
    overallPassed = true;
  } catch (error) {
    record('execution_stopped', {...safeError(error), securityFailure});
    process.exitCode = securityFailure ? 2 : 1;
  } finally {
    const a = clients[0];
    if (a && accounts.a && a.identity.currentUser?.uid === accounts.a.uid) {
      for (const [path, value] of tracked) {
        try {
          const snapshot = await db.getDocFromServer(value.ref);
          if (snapshot.exists()) {
            const data = snapshot.data();
            assert.equal(data.userId, accounts.a.uid);
            if (value.kind === 'budget') {
              assert.equal(path, `${root}/budgets/2099-12_food`);
              assert.equal(data.monthKey, '2099-12'); assert.equal(data.categoryId, 'food');
            } else assert.ok(data.description.startsWith(`TESTE_M3 ${run} `));
            await db.deleteDoc(value.ref);
            if (!removed.includes(path)) removed.push(path);
          }
          assert.equal((await db.getDocFromServer(value.ref)).exists(), false);
          record('cleanup_absence_verified', {path});
        } catch (error) {
          leftovers.push(path); record('cleanup_pending', {path, ...safeError(error)});
        }
      }
      if (profileMayExist) {
        try { profileRemaining = (await db.getDocFromServer(db.doc(a.store, profilePath))).exists(); }
        catch { profileRemaining = true; }
      }
    } else if (tracked.size) leftovers.push(...tracked.keys());
    if (leftovers.length) process.exitCode = 1;
    record('cleanup_report', {removedFinancialDocuments: removed, remainingFinancialDocuments: leftovers,
      retainedProfile: profileRemaining ? profilePath : null, retainedAccounts: accounts});
    for (const client of clients) {
      try { if (Object.values(accounts).some(value => value.uid === client.identity.currentUser?.uid)) await auth.signOut(client.identity); }
      catch (error) { record('local_signout_failed', {role: client.role, ...safeError(error)}); }
      try { await db.terminate(client.store); await core.deleteApp(client.app); }
      catch (error) { record('local_sdk_dispose_failed', {role: client.role, ...safeError(error)}); }
    }
    const report = {run, project: options.projectId, sdk: 'Firebase JavaScript client in Node.js', dartRepositoriesTested: false,
      passed, failed, overallPassed: overallPassed && !leftovers.length && !securityFailure, securityFailure, checks,
      removedFinancialDocuments: removed, remainingFinancialDocuments: leftovers,
      retainedProfile: profileRemaining ? profilePath : null, retainedAccounts: accounts,
      rssMiB: Math.round(process.memoryUsage().rss / 1048576)};
    writeFileSync(reportFile, JSON.stringify(report, null, 2));
    record('result', {passed, failed, overallPassed: report.overallPassed, securityFailure, rssMiB: report.rssMiB});
  }
}

execute().catch(error => {
  record('runner_blocked', safeError(error));
  process.exitCode = 1;
});
