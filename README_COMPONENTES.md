# Componentes y herramientas

## Tecnologías

- **Python 3** para la aplicación.
- **Flask 3.1.3** para el servidor web y los Blueprints.
- **PostgreSQL** como base de datos relacional.
- **psycopg2-binary 2.9.13** para conectarse a PostgreSQL y ejecutar SQL parametrizado, sin ORM.
- **Jinja2 3.1.6** para renderizar páginas y heredar plantillas.
- **Bootstrap 5.3.3** para el diseño responsivo; se carga desde CDN en la plantilla base.
- **pgAdmin o `psql`** pueden usarse para administrar la base y ejecutar los scripts; son herramientas de desarrollo, no dependencias de Python.

## Componentes presentes

- [`app.py`](./app.py): crea la aplicación Flask y registra los Blueprints de becas e intercambios.
- [`db.py`](./db.py): crea conexiones PostgreSQL desde `DATABASE_URL` o las variables `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST` y `DB_PORT` (también reconoce `PGDATABASE`, `PGUSER`, `PGPASSWORD`, `PGHOST` y `PGPORT`).
- [`routes_becas.py`](./routes_becas.py): implementa `GET /becas` con filtros combinables y `GET /oportunidad/<id>` para la ficha y su multimedia.
- [`routes_intercambios.py`](./routes_intercambios.py): implementa `GET /intercambios` con filtros SQL parametrizados y `GET /universidades` con el directorio de universidades hondureñas y sus convenios vigentes.
- [`templates/base.html`](./templates/base.html): plantilla compartida, navegación y alertas flash.
- [`templates/404.html`](./templates/404.html): página de recurso no encontrado.
- [`templates/becas.html`](./templates/becas.html): formulario de filtros y tarjetas de resultados.
- [`templates/intercambios.html`](./templates/intercambios.html): filtros y resultados de intercambios con comparación de universidades y cupos restantes.
- [`templates/universidades.html`](./templates/universidades.html): directorio hondureño con conteo de convenios activos por institución.
- [`templates/detalle_oportunidad.html`](./templates/detalle_oportunidad.html): ficha de beca y galería/documentos.
- [`Script.sql`](./Script.sql): definición del esquema PostgreSQL, vistas, índices y reglas de integridad.
- [`Datos_becas.sql`](./Datos_becas.sql): datos de catálogo y ejemplos.

Los componentes de estudiantes y administración descritos en el plan del equipo aún no aparecen en este repositorio. El Blueprint de intercambios ya está registrado en `app.py`.

## Instalación y ejecución local

Desde la carpeta del proyecto, en PowerShell:

```powershell
python -m pip install -r requirements.txt
$env:DB_NAME = "becas_test"
$env:DB_USER = "postgres"
$env:DB_PASSWORD = "<tu contraseña local>"
$env:DB_HOST = "localhost"
$env:DB_PORT = "5432"
python app.py
```

No escribas la contraseña en el repositorio ni la compartas. También se puede configurar `DATABASE_URL` en vez de las cinco variables `DB_*`.

Antes de arrancar la app, la base debe tener el esquema y los datos de demostración. Para crear una base vacía, ejecutar [`Script.sql`](./Script.sql) y después [`Datos_becas.sql`](./Datos_becas.sql). **`Script.sql` borra y recrea tablas; no usarlo como migración de una base con información que se desea conservar.**

Las rutas de consulta son `http://127.0.0.1:5000/becas`, `http://127.0.0.1:5000/intercambios` y `http://127.0.0.1:5000/universidades`. Los enlaces de las plantillas usan `url_for()` en vez de rutas escritas manualmente.

## Dependencias

[`requirements.txt`](./requirements.txt) es el archivo estándar para instalar las dependencias de Python. `requerimientos.txt` se conserva como copia en español.
