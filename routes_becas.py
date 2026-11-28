from contextlib import contextmanager
from decimal import Decimal, InvalidOperation

from flask import Blueprint, abort, flash, render_template, request, session
from psycopg2.extras import RealDictCursor

from db import get_connection


becas_bp = Blueprint("becas", __name__)


@contextmanager
def _database_cursor():
    connection = get_connection()
    try:
        with connection:
            with connection.cursor(cursor_factory=RealDictCursor) as cursor:
                yield cursor
    finally:
        connection.close()


def _optional_id(parameter, label):
    value = request.args.get(parameter, "").strip()
    if not value:
        return None
    try:
        parsed = int(value)
    except ValueError:
        flash(f"El filtro de {label} no es válido.", "warning")
        return None
    if parsed <= 0:
        flash(f"El filtro de {label} no es válido.", "warning")
        return None
    return parsed


def _optional_academic_index():
    value = request.args.get("indice", "").strip()
    if not value:
        return None
    try:
        parsed = Decimal(value)
    except InvalidOperation:
        flash("El índice académico debe ser un número entre 0 y 100.", "warning")
        return None
    if not parsed.is_finite() or not Decimal("0") <= parsed <= Decimal("100"):
        flash("El índice académico debe ser un número entre 0 y 100.", "warning")
        return None
    return parsed


@becas_bp.get("/becas")
def listar_becas():
    country_id = _optional_id("pais", "país")
    level_id = _optional_id("nivel", "nivel académico")
    scholarship_type_id = _optional_id("tipo_beca", "tipo de beca")
    academic_index = _optional_academic_index()

    conditions = []
    parameters = []
    if country_id is not None:
        conditions.append("id_pais = %s")
        parameters.append(country_id)
    if level_id is not None:
        conditions.append("id_nivel = %s")
        parameters.append(level_id)
    if scholarship_type_id is not None:
        conditions.append("id_tipo_beca = %s")
        parameters.append(scholarship_type_id)
    if academic_index is not None:
        conditions.append("indice_minimo <= %s")
        parameters.append(academic_index)

    query = "SELECT * FROM vw_becas_disponibles"
    if conditions:
        query += " WHERE " + " AND ".join(conditions)
    query += " ORDER BY fecha_limite ASC NULLS LAST, titulo"

    with _database_cursor() as cursor:
        cursor.execute(
            "SELECT id_pais, nombre FROM pais ORDER BY nombre"
        )
        paises = cursor.fetchall()
        cursor.execute(
            "SELECT id_nivel, nombre FROM nivel_academico ORDER BY nombre"
        )
        niveles = cursor.fetchall()
        cursor.execute(
            """
            SELECT id_tipo_beca, nombre
            FROM tipo_beca
            WHERE nombre IN ('Completa', 'Parcial', 'Manutención')
            ORDER BY CASE nombre
                WHEN 'Completa' THEN 1
                WHEN 'Parcial' THEN 2
                ELSE 3
            END
            """
        )
        tipos_beca = cursor.fetchall()
        cursor.execute(query, parameters)
        becas = cursor.fetchall()

    return render_template(
        "becas.html",
        becas=becas,
        paises=paises,
        niveles=niveles,
        tipos_beca=tipos_beca,
    )


@becas_bp.get("/oportunidad/<int:id>")
def detalle_oportunidad(id):
    with _database_cursor() as cursor:
        cursor.execute(
            """
            SELECT o.id_oportunidad, o.titulo, o.descripcion, o.fecha_limite,
                   to_tipo.nombre AS tipo_oportunidad,
                   i.nombre AS institucion_destino, p.nombre AS pais_destino,
                   n.nombre AS nivel_academico, c.nombre AS carrera,
                   b.indice_minimo, tb.nombre AS tipo_beca,
                   orig.nombre AS universidad_origen,
                   inc.cupos_disponibles,
                   mod_inc.nombre AS modalidad
            FROM oportunidad AS o
            JOIN tipo_oportunidad AS to_tipo
              ON to_tipo.id_tipo_oportunidad = o.id_tipo_oportunidad
            JOIN institucion AS i
              ON i.id_institucion = o.id_institucion_destino
            JOIN pais AS p
              ON p.id_pais = i.id_pais
            JOIN nivel_academico AS n
              ON n.id_nivel = o.id_nivel
            LEFT JOIN carrera AS c
              ON c.id_carrera = o.id_carrera
            LEFT JOIN beca AS b
              ON b.id_oportunidad = o.id_oportunidad
            LEFT JOIN tipo_beca AS tb
              ON tb.id_tipo_beca = b.id_tipo_beca
            LEFT JOIN intercambio AS inc
              ON inc.id_oportunidad = o.id_oportunidad
            LEFT JOIN institucion AS orig
              ON orig.id_institucion = inc.id_universidad_origen
            LEFT JOIN modalidad_intercambio AS mod_inc
              ON mod_inc.id_modalidad = inc.id_modalidad
            WHERE o.id_oportunidad = %s
            """,
            (id,),
        )
        oportunidad = cursor.fetchone()
        if oportunidad is None:
            abort(404)

        cursor.execute(
            """
            SELECT tm.nombre AS tipo_multimedia, m.url_archivo,
                   m.titulo_descriptivo, m.es_portada
            FROM multimedia_oportunidad AS m
            JOIN tipo_multimedia AS tm
              ON tm.id_tipo_multimedia = m.id_tipo_multimedia
            WHERE m.id_oportunidad = %s
            ORDER BY m.es_portada DESC, m.fecha_subida, m.id_multimedia
            """,
            (id,),
        )
        multimedia = cursor.fetchall()

        interaccion_actual = None
        id_estudiante = session.get("id_estudiante")
        if id_estudiante:
            cursor.execute(
                """
                SELECT est.nombre AS estado, inter.fecha_accion
                FROM interaccion AS inter
                JOIN estado_interaccion AS est
                  ON est.id_estado = inter.id_estado
                WHERE inter.id_estudiante = %s
                  AND inter.id_oportunidad = %s
                """,
                (id_estudiante, id),
            )
            interaccion_actual = cursor.fetchone()

    return render_template(
        "detalle_oportunidad.html",
        oportunidad=oportunidad,
        multimedia=multimedia,
        interaccion_actual=interaccion_actual,
    )


@becas_bp.app_errorhandler(404)
def pagina_no_encontrada(error):
    return render_template("404.html"), 404
