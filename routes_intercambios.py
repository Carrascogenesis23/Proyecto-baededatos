from contextlib import contextmanager

from flask import Blueprint, flash, render_template, request
from psycopg2.extras import RealDictCursor

from db import get_connection


intercambios_bp = Blueprint("intercambios", __name__)


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


@intercambios_bp.get("/intercambios")
def listar_intercambios():
    university_id = _optional_id("origen", "universidad de origen")
    country_id = _optional_id("pais", "país de destino")
    level_id = _optional_id("nivel", "nivel académico")
    modality_id = _optional_id("modalidad", "modalidad")

    conditions = []
    parameters = []
    if university_id is not None:
        conditions.append("id_universidad_origen = %s")
        parameters.append(university_id)
    if country_id is not None:
        conditions.append("id_pais = %s")
        parameters.append(country_id)
    if level_id is not None:
        conditions.append("id_nivel = %s")
        parameters.append(level_id)
    if modality_id is not None:
        conditions.append("id_modalidad = %s")
        parameters.append(modality_id)

    query = "SELECT * FROM vw_intercambios_disponibles"
    if conditions:
        query += " WHERE " + " AND ".join(conditions)
    query += " ORDER BY cupos_disponibles DESC, fecha_limite ASC NULLS LAST, titulo"

    with _database_cursor() as cursor:
        cursor.execute(
            """
            SELECT institucion.id_institucion, institucion.nombre
            FROM institucion
            JOIN pais ON pais.id_pais = institucion.id_pais
            WHERE pais.nombre = 'Honduras'
            ORDER BY institucion.nombre
            """
        )
        universidades = cursor.fetchall()
        cursor.execute(
            "SELECT id_pais, nombre FROM pais WHERE nombre <> 'Honduras' ORDER BY nombre"
        )
        paises = cursor.fetchall()
        cursor.execute(
            "SELECT id_nivel, nombre FROM nivel_academico ORDER BY nombre"
        )
        niveles = cursor.fetchall()
        cursor.execute(
            "SELECT id_modalidad, nombre FROM modalidad_intercambio ORDER BY nombre"
        )
        modalidades = cursor.fetchall()
        cursor.execute(query, parameters)
        intercambios = cursor.fetchall()

    return render_template(
        "intercambios.html",
        intercambios=intercambios,
        universidades=universidades,
        paises=paises,
        niveles=niveles,
        modalidades=modalidades,
    )


@intercambios_bp.get("/universidades")
def listar_universidades():
    with _database_cursor() as cursor:
        cursor.execute(
            """
            SELECT
                institucion.id_institucion,
                institucion.nombre,
                institucion.logo_url,
                pais.nombre AS pais,
                COUNT(DISTINCT CASE
                    WHEN tipo_oportunidad.nombre = 'Intercambio'
                     AND pais_destino.nombre <> 'Honduras'
                     AND intercambio.cupos_disponibles > 0
                    THEN intercambio.id_oportunidad
                END) AS convenios_activos
            FROM institucion
            JOIN pais
              ON pais.id_pais = institucion.id_pais
            LEFT JOIN intercambio
              ON intercambio.id_universidad_origen = institucion.id_institucion
            LEFT JOIN oportunidad
              ON oportunidad.id_oportunidad = intercambio.id_oportunidad
             AND (oportunidad.fecha_limite IS NULL
                  OR oportunidad.fecha_limite >= CURRENT_DATE)
            LEFT JOIN tipo_oportunidad
              ON tipo_oportunidad.id_tipo_oportunidad = oportunidad.id_tipo_oportunidad
            LEFT JOIN institucion AS institucion_destino
              ON institucion_destino.id_institucion = oportunidad.id_institucion_destino
            LEFT JOIN pais AS pais_destino
              ON pais_destino.id_pais = institucion_destino.id_pais
            WHERE pais.nombre = 'Honduras'
            GROUP BY institucion.id_institucion, institucion.nombre,
                     institucion.logo_url, pais.nombre
            ORDER BY institucion.nombre
            """
        )
        universidades = cursor.fetchall()

    return render_template(
        "universidades.html",
        universidades=universidades,
    )
