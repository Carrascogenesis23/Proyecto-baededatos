# Cambios recientes en la base de datos

Este documento resume los cambios incorporados a `Script.sql` y `Datos_becas.sql` para que el equipo conozca las nuevas reglas y pueda integrarse con ellas. La descripción general de tablas y relaciones está en [README_BASE_DE_DATOS.md](./README_BASE_DE_DATOS.md).

## Cambios en el esquema (`Script.sql`)

### Integridad entre oportunidad y detalle

Las oportunidades de tipo `Beca` deben tener un registro en `beca`; las de tipo `Intercambio`, uno en `intercambio`. No se permite guardar ambos detalles para una misma oportunidad. Triggers diferidos validan esta correspondencia al confirmar la transacción, por lo que la inserción de la oportunidad y su detalle puede hacerse dentro de una misma transacción.

El tipo `Práctica profesional` no tiene una tabla de detalle en el esquema actual y no admite postulaciones.

### Requisitos para postularse

Al crear o cambiar una interacción a un estado que representa postulación (`Postulado`, `En revision` o `aceptado`), la base valida que:

- Para una beca, el índice académico del estudiante alcance el mínimo definido en `beca`.
- Para un intercambio, la universidad de origen del estudiante coincida con la universidad de origen indicada en `intercambio`.

El estado `Favorito` no ejecuta estas validaciones ni reserva un cupo.

### Reserva y devolución de cupos

Para intercambios, los estados `Postulado`, `En revision` y `aceptado` reservan un cupo. La base rechaza la operación cuando no quedan cupos. Al cambiar a `Favorito` o `rechazado`, o al eliminar una interacción con cupo reservado, el cupo se devuelve. Pasar entre estados que reservan cupo mantiene la reserva.

**Importante para la aplicación:** no descuenten ni devuelvan cupos desde las rutas Flask; los triggers realizan ese trabajo. `intercambio.cupos_disponibles` representa los cupos que quedan disponibles.

### Multimedia e índices

- Un índice único parcial permite como máximo una multimedia marcada como portada por oportunidad.
- Se añadieron índices para acelerar búsquedas y relaciones frecuentes, como las consultas por tipo de oportunidad, institución, estudiante, oportunidad y multimedia.
- `vw_intercambios_disponibles` reúne los datos del convenio, sus instituciones de origen y destino, el país de destino, el nivel, la modalidad, los cupos y la imagen de portada. Solo incluye convenios desde Honduras hacia el exterior, vigentes y con cupos disponibles.

### Reinicio del esquema

El script ahora también elimina `usuario` durante el reinicio, junto con las demás tablas dependientes. Esto permite volver a crear el esquema desde cero, pero **no convierte el script en una migración segura**: elimina las tablas y sus datos.

## Cambios en los datos de catálogo (`Datos_becas.sql`)

- Los tipos de beca acordados son `Completa`, `Parcial` y `Manutención`. Los registros que usaban el tipo antiguo `Anual` se reasignan a `Completa`; los tipos antiguos sin becas asociadas se eliminan.
- Se añadió el estado de interacción `Favorito`.
- Se añadió `PDF` al catálogo `tipo_multimedia`, además de `Imagen` y `Video`.
- Los ejemplos incluyen oportunidades de beca e intercambio y las interacciones correspondientes.
- El catálogo de modalidad de intercambio incluye `Semestral`, `Anual` y `Verano`.

Los nombres de estado se guardan tal como aparecen en el catálogo, por lo que las consultas y formularios deben usar esos valores. Para distinguir estados que reservan cupo, la base compara el nombre sin distinguir mayúsculas/minúsculas.

## Consideraciones para los integrantes

1. Al crear una beca o intercambio, inserten la fila en `oportunidad` y su detalle correspondiente en `beca` o `intercambio` dentro de la misma transacción. No dejen una oportunidad sin detalle.
2. Al postular, inserten o actualicen la fila de `interaccion`; no actualicen `cupos_disponibles` directamente.
3. La restricción única de `interaccion` permite una sola fila por pareja estudiante/oportunidad. Para cambiar entre `Favorito`, `Postulado` u otro estado, actualicen esa fila en vez de insertar otra.
4. Manejen los rechazos de PostgreSQL en las operaciones de postulación: pueden deberse a índice insuficiente, universidad de origen no elegible, tipo no postulable o falta de cupos.
5. Las vistas `vw_becas_disponibles` y `vw_intercambios_disponibles` se crean en `Script.sql`; debe existir el esquema actualizado antes de usar las rutas correspondientes.

## Cómo aplicar los cambios

Para una instalación nueva, creen una base vacía y ejecuten `Script.sql`, seguido de `Datos_becas.sql`. **No ejecuten `Script.sql` en una base compartida o con datos que deban conservarse.** Este repositorio no incluye una migración incremental para aplicar los nuevos triggers a una base existente.

Las pruebas realizadas sobre el esquema se ejecutaron dentro de una transacción revertida; por ello, no se debe asumir que los triggers nuevos ya están instalados en una base local o compartida.
