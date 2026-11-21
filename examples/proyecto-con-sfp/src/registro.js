// Registro de clientes de la tienda (código de ejemplo, funciona de verdad).

/**
 * Comprueba que un correo tenga una forma válida.
 * Regla (requisitos 1 y 2 de specs/cambios/validar-correo): texto, arroba, dominio con al menos un punto.
 * Se acepta el signo más: ana+pedidos@ejemplo.com es válido.
 */
function validarCorreo(texto) {
  if (typeof texto !== 'string' || texto.trim() === '') {
    return { valido: false, motivo: 'Revisa el correo: está vacío' };
  }
  const correo = texto.trim();
  if (!correo.includes('@')) {
    return { valido: false, motivo: 'Revisa el correo: falta la arroba' };
  }
  const [local, dominio, ...resto] = correo.split('@');
  if (resto.length > 0 || !local || /\s/.test(local)) {
    return { valido: false, motivo: 'Revisa el correo: el texto antes de la arroba no es válido' };
  }
  if (!dominio || !/^[^\s.]+(\.[^\s.]+)+$/.test(dominio)) {
    return { valido: false, motivo: 'Revisa el correo: el dominio debe tener al menos un punto, como ejemplo.com' };
  }
  return { valido: true, motivo: '' };
}

const clientes = [];

/** Registra a una persona si su correo es válido. */
function registrar({ nombre, correo }) {
  const resultado = validarCorreo(correo);
  if (!resultado.valido) {
    return { ok: false, error: resultado.motivo };
  }
  const cliente = { nombre, correo: correo.trim() };
  clientes.push(cliente);
  return { ok: true, cliente };
}

module.exports = { validarCorreo, registrar };
