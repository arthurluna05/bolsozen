// Uma string digitada em formulário não comprova navegação autenticada.
function isConfirmedProfile(nodes, name, email) {
  const labels = new Set(nodes.filter(n => !n.ignored).map(n => n.name?.value));
  return ['Perfil', 'Sair', name, email].every(label => labels.has(label)) &&
    !['Criar sua conta', 'Entrar no BolsoZen', 'Completar perfil'].some(label => labels.has(label));
}
module.exports = {isConfirmedProfile};
