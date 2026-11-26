# Base de datos del sistema

## Propósito

El esquema PostgreSQL almacena catálogos académicos e institucionales, usuarios y sus perfiles, oportunidades de beca e intercambio, postulaciones/favoritos y archivos multimedia. La aplicación accede a PostgreSQL mediante SQL parametrizado con `psycopg2`; no usa ORM.

Para consultar qué se añadió recientemente al esquema y qué deben considerar los demás integrantes al integrarse, revisa [README_CAMBIOS_BASE_DE_DATOS.md](./README_CAMBIOS_BASE_DE_DATOS.md).

## Relaciones y cardinalidades

- **`pais` 1:N `institucion`**: cada institución pertenece a un país. El nombre del país es único y una institución no se repite con el mismo nombre dentro del mismo país.
- **`institucion` 1:N `usuario`**: `usuario.id_universidad_de_origen` relaciona la cuenta con su institución. En estudiantes indica su universidad de origen; en administradores, la institución a la que pertenecen.
- **`usuario` 1:0..1 `estudiante`** y **`usuario` 1:0..1 `administrador_universidad`**: las FK únicas evitan más de un perfil del mismo tipo por usuario. El esquema permite que un usuario no tenga perfil, o que tenga ambos perfiles.
- **`nivel_academico` 1:N `estudiante`** y **`nivel_academico` 1:N `oportunidad`**: los niveles se almacenan una vez y se referencian desde perfiles y convocatorias.
- **`carrera` 1:N `estudiante`** y **`carrera` 1:N `oportunidad`**: una oportunidad puede no especificar carrera; al borrar una carrera, esa referencia pasa a `NULL`.
- **`tipo_oportunidad` 1:N `oportunidad`**: cada oportunidad tiene un tipo, por ejemplo, beca o intercambio.
- **`oportunidad` 1:0..1 `beca`** y **`oportunidad` 1:0..1 `intercambio`**: el ID de cada detalle también es su FK a `oportunidad`. Triggers diferidos aseguran al confirmar la transacción que una beca tenga su detalle, que un intercambio tenga el suyo y que no tengan ambos.
- **`tipo_beca` 1:N `beca`** y **`modalidad_intercambio` 1:N `intercambio`**: los catálogos definen la clasificación de cada detalle.
- **`institucion` 1:N `oportunidad`** como institución de destino, y **`institucion` 1:N `intercambio`** como universidad de origen del convenio.
- **`administrador_universidad` 1:N `oportunidad`**: `id_admin_publicador` identifica quién publicó la oportunidad; es opcional para admitir registros sin publicador asignado.
- **`estudiante` N:M `oportunidad` mediante `interaccion`**: cada fila guarda el estado y la fecha. Una restricción `UNIQUE` por estudiante/oportunidad deja una sola interacción vigente para esa pareja; actualizarla cambia el estado.
- **`oportunidad` 1:N `multimedia_oportunidad`**: guarda imágenes, videos y PDFs. Un índice único parcial permite como máximo una portada por oportunidad.

## Integridad y reglas de negocio

Las claves foráneas evitan referencias a países, instituciones, estudiantes u oportunidades inexistentes. `UNIQUE` protege correos y nombres de catálogo; `CHECK` restringe el índice académico a 0–100, el mínimo de beca a 70–100 y los cupos a valores no negativos. Las eliminaciones de una oportunidad borran sus detalles, interacciones y multimedia mediante `ON DELETE CASCADE`.

Las restricciones/triggers también:

- Exigen que el tipo de la oportunidad coincida con su tabla de detalle.
- Al postularse a una beca, comparan el índice del estudiante con el mínimo requerido.
- Para un intercambio, exigen que la universidad de origen del estudiante coincida con el convenio.
- Reservan un cupo al crear una interacción `Postulado`, `En revision` o `aceptado`; bloquean la operación si no hay cupos.
- Devuelven el cupo al pasar a `Favorito` o `rechazado`, o al eliminar una interacción reservada. Las transiciones entre `Postulado`, `En revision` y `aceptado` conservan la reserva.
- No aplican requisitos de postulación a interacciones `Favorito`.

Estas reglas se ejecutan dentro de la transacción PostgreSQL; ante una excepción, también se revierte la inserción o actualización.

## Archivos SQL

- [`Script.sql`](./Script.sql) crea el esquema, índices, vista y funciones/triggers. **Es un script de reinicio: elimina las tablas existentes antes de crearlas. No ejecutarlo sobre una base con datos que se quieran conservar.**
- [`Datos_becas.sql`](./Datos_becas.sql) carga catálogos y datos de demostración. Ejecutarlo después del esquema.
- `vw_becas_disponibles` expone becas vigentes con país, nivel, tipo, índice mínimo e imagen de portada.

Para preparar una base vacía, crearla primero en PostgreSQL y ejecutar `Script.sql` seguido de `Datos_becas.sql`. Los scripts de esquema son destructivos; los datos reales deben tener respaldo antes de cualquier reinicialización.
