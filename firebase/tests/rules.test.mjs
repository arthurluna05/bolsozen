import { readFile } from 'node:fs/promises';
import { after, before, beforeEach, test } from 'node:test';
import assert from 'node:assert/strict';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, getDocs, updateDoc, deleteDoc, collection, query, orderBy, documentId, limit, startAfter, where, Timestamp, serverTimestamp } from 'firebase/firestore';

// Fail closed before creating clients: never infer a remote/default project.
const projectId = 'demo-bolsozen';
assert.equal(process.env.FIRESTORE_EMULATOR_HOST, '127.0.0.1:8080', 'Execute via Emulator Suite local em 127.0.0.1:8080');
let env;
const timestamp = Timestamp.fromMillis(1000);
const email = 'a@example.test';
const profile = () => ({displayName: 'Pessoa A', email, createdAt: serverTimestamp()});
const transaction = (overrides = {}) => ({userId: 'A', type: 'expense', amountCents: 12050,
  categoryId: 'food', description: 'Mercado', occurredAt: timestamp,
  createdAt: serverTimestamp(), updatedAt: serverTimestamp(), ...overrides});
const budget = (overrides = {}) => ({userId: 'A', monthKey: '2026-11', categoryId: 'food',
  limitCents: 30000, createdAt: serverTimestamp(), updatedAt: serverTimestamp(), ...overrides});
const db = (uid = 'A') => uid === null ? env.unauthenticatedContext().firestore() : env.authenticatedContext(uid, {email: uid === 'A' ? email : 'b@example.test'}).firestore();
const txPath = 'users/A/transactions/t';
const budgetPath = 'users/A/budgets/2026-11_food';

before(async () => {
  env = await initializeTestEnvironment({projectId, firestore: {
    host: '127.0.0.1', port: 8080,
    rules: await readFile(new URL('../../firestore.rules', import.meta.url), 'utf8'),
  }});
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    const admin = context.firestore();
    await setDoc(doc(admin, 'users/A'), {...profile(), createdAt: timestamp});
    await setDoc(doc(admin, txPath), transaction({createdAt: timestamp, updatedAt: timestamp}));
    await setDoc(doc(admin, budgetPath), budget({createdAt: timestamp, updatedAt: timestamp}));
  });
});
after(async () => { await env?.cleanup(); });

for (const path of ['users/A', txPath, budgetPath]) {
  test(`Proprietário lê ${path}`, async () => assertSucceeds(getDoc(doc(db(), path))));
  for (const uid of ['B', null]) {
    test(`${uid ?? 'anônimo'} não lê ${path}`, async () => assertFails(getDoc(doc(db(uid), path))));
    test(`${uid ?? 'anônimo'} não modifica ${path}`, async () => {
      // Payload válido para a coleção: a recusa deve decorrer do acesso,
      // não de campos inesperados ou de auditoria ausente.
      const patch = path === 'users/A' ? {displayName: 'Outro nome'}
        : path === txPath ? {amountCents: 1, updatedAt: serverTimestamp()}
        : {limitCents: 1, updatedAt: serverTimestamp()};
      await assertFails(updateDoc(doc(db(uid), path), patch));
    });
    test(`${uid ?? 'anônimo'} não exclui ${path}`, async () => assertFails(deleteDoc(doc(db(uid), path))));
  }
}
test('Proprietário cria/edita/exclui transação com auditoria real', async () => {
  const ref = doc(db(), 'users/A/transactions/new');
  await assertSucceeds(setDoc(ref, transaction()));
  await assertSucceeds(updateDoc(ref, {amountCents: 1, updatedAt: serverTimestamp()}));
  await assertSucceeds(deleteDoc(ref));
});
test('Receita válida aceita catálogo income', async () => assertSucceeds(setDoc(doc(db(), 'users/A/transactions/salary'), transaction({type: 'income', categoryId: 'salary'}))));
test('Proprietário cria/edita/exclui limite, preservando transações', async () => {
  const ref = doc(db(), 'users/A/budgets/2026-12_transport');
  await assertSucceeds(setDoc(ref, budget({monthKey: '2026-12', categoryId: 'transport'})));
  await assertSucceeds(updateDoc(ref, {limitCents: 20000, updatedAt: serverTimestamp()}));
  await assertSucceeds(deleteDoc(ref));
  assert.equal((await getDoc(doc(db(), txPath))).exists(), true);
});
test('Criação de perfil apenas próprio, campos válidos e email autenticado', async () => {
  await assertSucceeds(setDoc(doc(db('B'), 'users/B'), {...profile(), email: 'b@example.test'}));
  await assertSucceeds(updateDoc(doc(db(), 'users/A'), {displayName: 'Novo nome'}));
  await assertFails(deleteDoc(doc(db(), 'users/A')));
  await assertFails(setDoc(doc(db('B'), 'users/C'), profile()));
});

for (const [name, patch] of Object.entries({
  uid: {userId: 'B'}, negative: {amountCents: -1}, zero: {amountCents: 0}, fraction: {amountCents: 1.5},
  string: {amountCents: '100'}, bool: {amountCents: true}, type: {type: 'transfer'},
  incompatible: {categoryId: 'salary'}, unknown: {categoryId: 'new_category'}, empty: {description: ''},
  blank: {description: '  \n  '}, long: {description: 'a'.repeat(121)}, extra: {extra: 'unexpected'},
  date: {occurredAt: '2026-11-01'}, created: {createdAt: Timestamp.fromMillis(2000)}, updated: {updatedAt: timestamp},
})) {
  test(`Transação rejeita criação ${name}`, async () => assertFails(setDoc(doc(db(), 'users/A/transactions/invalid'), transaction(patch))));
  test(`Transação rejeita edição ${name}`, async () => assertFails(updateDoc(doc(db(), txPath), {...patch, ...(name === 'updated' ? {} : {updatedAt: serverTimestamp()})})));
}
test('Transação exige todos os campos', async () => {
  const data = transaction(); delete data.description;
  await assertFails(setDoc(doc(db(), 'users/A/transactions/missing'), data));
});
for (const [name, patch, id] of [
  ['uid', {userId: 'B'}, '2026-11_food'],
  ['zero', {limitCents: 0}, '2026-11_food'],
  ['negativo', {limitCents: -1}, '2026-11_food'],
  ['decimal', {limitCents: 1.5}, '2026-11_food'],
  ['texto', {limitCents: '100'}, '2026-11_food'],
  ['receita', {categoryId: 'salary'}, '2026-11_salary'],
  ['categoria', {categoryId: 'invalid'}, '2026-11_invalid'],
  ['mes', {monthKey: '2026-13'}, '2026-13_food'],
  ['formato', {monthKey: '2026-1'}, '2026-1_food'],
  ['ano', {monthKey: '0000-11'}, '0000-11_food'],
  ['identidade', {}, 'wrong-id'],
  ['campo extra', {extra: true}, '2026-11_food'],
  ['criação', {createdAt: timestamp}, '2026-11_food'],
  ['atualização', {updatedAt: timestamp}, '2026-11_food'],
]) {
  test(`Orçamento rejeita ${name}`, async () => {
    await deleteDoc(doc(db(), budgetPath));
    await assertFails(setDoc(doc(db(), `users/A/budgets/${id}`), budget(patch)));
  });
}
test('Orçamento recusa alterações de criação, proprietário, categoria ou mês', async () => {
  for (const patch of [{createdAt: Timestamp.fromMillis(2000)}, {userId: 'B'}, {categoryId: 'transport'}, {monthKey: '2026-12'}, {limitCents: -1}]) {
    await assertFails(updateDoc(doc(db(), budgetPath), {...patch, updatedAt: serverTimestamp()}));
  }
});
test('Orçamento exige todos os campos', async () => {
  const data = budget(); delete data.limitCents;
  await assertFails(setDoc(doc(db(), 'users/A/budgets/2026-11_food'), data));
});
test('Perfil rejeita campos inválidos e criação imutável', async () => {
  for (const patch of [{displayName: ''}, {displayName: 'a'}, {displayName: ' '.repeat(3)}, {displayName: 'a'.repeat(81)},
    {email: 'invalid'}, {email: 'b@example.test'}, {extra: 'no'}, {createdAt: Timestamp.fromMillis(2000)}]) {
    await assertFails(updateDoc(doc(db(), 'users/A'), patch));
  }
});
test('Nega por padrão outras coleções e subcoleções', async () => {
  for (const path of ['public/t', 'users/A/unknown/t']) {
    await assertFails(getDoc(doc(db(), path)));
    await assertFails(setDoc(doc(db(), path), {value: 1}));
  }
});
test('Consultas por usuário, ordenação e cursor não repetem registros empatados', async () => {
  const database = db();
  for (const id of ['a', 'b', 'c']) await setDoc(doc(database, `users/A/transactions/${id}`), transaction());
  const base = query(collection(database, 'users/A/transactions'), orderBy('occurredAt', 'desc'), orderBy('createdAt', 'desc'), orderBy(documentId()));
  const first = await assertSucceeds(getDocs(query(base, limit(2))));
  const last = first.docs.at(-1);
  const next = await assertSucceeds(getDocs(query(base, startAfter(last.get('occurredAt'), last.get('createdAt'), last.id), limit(2))));
  assert.equal(new Set([...first.docs, ...next.docs].map(d => d.id)).size, 4);
  await assertFails(getDocs(collection(db('B'), 'users/A/transactions')));
  const limits = await assertSucceeds(getDocs(query(collection(database, 'users/A/budgets'), where('monthKey', '==', '2026-11'))));
  assert.equal(limits.size, 1);
});
