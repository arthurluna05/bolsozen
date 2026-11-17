const {test} = require('node:test');
const assert = require('node:assert/strict');
const {isConfirmedProfile} = require('./m4_ui_assertions.cjs');
const nodes = labels => labels.map(value => ({name: {value}, ignored: false}));
const name = 'TESTE LOCAL', email = 'local@example.test';
test('Perfil exige destino, ação Sair e identidade correspondente', () => {
  assert.equal(isConfirmedProfile(nodes(['Perfil', 'Sair', name, email]), name, email), true);
});
test('Nome digitado no cadastro não comprova perfil', () => {
  assert.equal(isConfirmedProfile(nodes(['Criar sua conta', name, email]), name, email), false);
});
test('E-mail digitado no login não comprova perfil', () => {
  assert.equal(isConfirmedProfile(nodes(['Entrar no BolsoZen', email]), name, email), false);
});
test('Completar perfil continua fora da área pronta', () => {
  assert.equal(isConfirmedProfile(nodes(['Completar perfil', 'Sair', name, email]), name, email), false);
});
test('Perfil de outra identidade é rejeitado', () => {
  assert.equal(isConfirmedProfile(nodes(['Perfil', 'Sair', 'Outro', email]), name, email), false);
});
test('Nó oculto e formulário residual não liberam aprovação', () => {
  const hidden = nodes(['Perfil', 'Sair', name, email]); hidden[0].ignored = true;
  assert.equal(isConfirmedProfile(hidden, name, email), false);
  assert.equal(isConfirmedProfile(nodes(['Perfil', 'Sair', name, email, 'Criar sua conta']), name, email), false);
});
