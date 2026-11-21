// Una prueba por requisito de specs/cambios/validar-correo/requisitos.md
const test = require('node:test');
const assert = require('node:assert');
const { validarCorreo, registrar } = require('../src/registro');

test('requisito 1: rechaza correos sin forma válida', () => {
  for (const malo of ['sin-arroba.com', '@ejemplo.com', 'ana@ejemplo', 'ana@@ejemplo.com', '']) {
    assert.strictEqual(validarCorreo(malo).valido, false, malo);
  }
});

test('requisito 2: acepta el signo más', () => {
  assert.strictEqual(validarCorreo('ana+pedidos@ejemplo.com').valido, true);
});

test('requisito 3: el mensaje dice qué corregir', () => {
  assert.match(validarCorreo('sin-arroba.com').motivo, /falta la arroba/);
  assert.match(validarCorreo('ana@ejemplo').motivo, /dominio/);
});

test('requisito 4: un correo válido se registra como siempre', () => {
  const r = registrar({ nombre: 'Ana', correo: 'ana@ejemplo.com' });
  assert.strictEqual(r.ok, true);
  assert.strictEqual(r.cliente.nombre, 'Ana');
});

test('un correo inválido no registra a nadie', () => {
  const r = registrar({ nombre: 'Luis', correo: 'luis.com' });
  assert.strictEqual(r.ok, false);
});
