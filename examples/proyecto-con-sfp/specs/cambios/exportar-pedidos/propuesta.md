# Propuesta: exportar los pedidos a un archivo CSV

Estado: **borrador, esperando aprobación.** Todavía no se programa nada.

Este cambio sirve para mostrar el punto central de la metodología: el asistente escribe la propuesta y se detiene hasta que una persona la aprueba.

## Problema
Contabilidad copia a mano los pedidos del mes a una hoja de cálculo. Tarda medio día y a veces se pierde alguno.

## Qué se propone
Un botón "Exportar pedidos del mes" que descargue un archivo CSV con fecha, cliente, productos y total.

## Preguntas que necesitan respuesta antes de seguir
1. ¿Incluye pedidos cancelados, o solo los entregados?
2. ¿El archivo contiene datos personales de clientes? Si es así, ¿quién puede descargarlo?
3. ¿Hay un tamaño máximo? Con más de 50 000 pedidos, la descarga directa podría fallar.

## Riesgo
Medio, por los datos personales. Por eso, antes de implementar se pedirá la aprobación explícita de la persona responsable.

README: añadir "Exportar pedidos" a la lista de características cuando el cambio se apruebe e implemente.
