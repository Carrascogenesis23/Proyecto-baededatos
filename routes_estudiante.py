from contextlib import contextmanager
from decimal import Decimal, InvalidOperation

import psycopg2
from flask import Blueprint, flash, redirect, render_template, request, session, url_for
from psycopg2.extras import RealDictCursor

from db import get_connection


estudiante_bp = Blueprint("estudiante", __name__)


@contextmanager
def _database_cursor():
    connection = get_connection()
    try:
        with connection:
            with connection.cursor(cursor_factory=RealDictCursor) as cursor:
                yield cursor
    finally:
        connection.close()


def _extraer_mensaje_pg(error: psycopg2.Error) -> str:
    diag = getattr(error, "diag", None)
    if diag is not None and diag.message_primary:
        return diag.message_primary
    texto = str(error).strip()
    if texto:
        return texto.splitlines()[0]
    return "Ocurrió un error al procesar la solicitud en PostgreSQL."


def _safe_next_url(fallback_endpoint: str) -> str:
    next_url = (request.form.get("next") or request.args.get("next") or "").strip()
    if next_url.startswith("/") and not next_url.startswith("//"):
        return next_url
    return url_for(fallback_endpoint)


def _obtener_perfil_estudiante(cursor, id_estudiante: int):
    cursor.execute(
        """
        SELECT
            e.id_estudiante,
            e.id_usuario,
            e.id_carrera,
            e.id_nivel,
            e.indice_academico,
            u.nombre1,
            u.nombre2,
            u.apellido1,
            u.apellido2,
            u.correo,
            u.id_universidad_de_origen,
            i.nombre AS universidad_origen,
            c.nombre AS carrera,
            n.nombre AS nivel_academico
        FROM estudiante AS e
        JOIN usuario AS u
          ON u.id_usuario = e.id_usuario
        JOIN institucion AS i
          ON i.id_institucion = u.id_universidad_de_origen
        JOIN carrera AS c
          ON c.id_carrera = e.id_carrera
        JOIN nivel_academico AS n
          ON n.id_nivel = e.id_nivel
        WHERE e.id_estudiante = %s
        """,
        (id_estudiante,),
    )
    return cursor.fetchone()


def _cargar_catalogos_registro(cursor):
    cursor.execute(
        """
        SELECT i.id_institucion, i.nombre
        FROM institucion AS i
        JOIN pais AS p
          ON p.id_pais = i.id_pais
        WHERE p.nombre = 'Honduras'
        ORDER BY i.nombre
        """
    )
    universidades = cursor.fetchall()

    cursor.execute("SELECT id_carrera, nombre FROM carrera ORDER BY nombre")
    carreras = cursor.fetchall()

    cursor.execute("SELECT id_nivel, nombre FROM nivel_academico ORDER BY nombre")
    niveles = cursor.fetchall()

    cursor.execute(
        """
        SELECT
            e.id_estudiante,
            u.nombre1,
            u.apellido1,
            u.correo,
            i.nombre AS universidad_origen,
            c.nombre AS carrera,
            n.nombre AS nivel_academico,
            e.indice_academico
        FROM estudiante AS e
        JOIN usuario AS u
          ON u.id_usuario = e.id_usuario
        JOIN institucion AS i
          ON i.id_institucion = u.id_universidad_de_origen
        JOIN carrera AS c
          ON c.id_carrera = e.id_carrera
        JOIN nivel_academico AS n
          ON n.id_nivel = e.id_nivel
        ORDER BY u.nombre1, u.apellido1
        """
    )
    estudiantes = cursor.fetchall()

    return universidades, carreras, niveles, estudiantes


@estudiante_bp.app_context_processor
def inyectar_estudiante_actual():
    id_estudiante = session.get("id_estudiante")
    if not id_estudiante:
        return {"estudiante_actual": None}

    try:
        with _database_cursor() as cursor:
            perfil = _obtener_perfil_estudiante(cursor, id_estudiante)
    except (psycopg2.Error, RuntimeError):
        return {"estudiante_actual": None}

    if perfil is None:
        session.pop("id_estudiante", None)
    return {"estudiante_actual": perfil}


@estudiante_bp.route("/registro", methods=["GET", "POST"])
def registro():
    form_data = {}

    if request.method == "POST":
        nombre1 = request.form.get("nombre1", "").strip()
        nombre2 = request.form.get("nombre2", "").strip() or None
        apellido1 = request.form.get("apellido1", "").strip()
        apellido2 = request.form.get("apellido2", "").strip() or None
        correo = request.form.get("correo", "").strip().lower()
        universidad_raw = request.form.get("universidad", "").strip()
        carrera_raw = request.form.get("carrera", "").strip()
        nivel_raw = request.form.get("nivel", "").strip()
        indice_raw = request.form.get("indice", "").strip()

        form_data = {
            "nombre1": nombre1,
            "nombre2": nombre2 or "",
            "apellido1": apellido1,
            "apellido2": apellido2 or "",
            "correo": correo,
            "universidad": universidad_raw,
            "carrera": carrera_raw,
            "nivel": nivel_raw,
            "indice": indice_raw,
        }

        errores = []
        if not nombre1 or not apellido1 or not correo:
            errores.append("Completa primer nombre, primer apellido y correo electrónico.")

        try:
            id_universidad = int(universidad_raw)
            id_carrera = int(carrera_raw)
            id_nivel = int(nivel_raw)
        except ValueError:
            errores.append("Selecciona una universidad, carrera y nivel académico válidos.")
            id_universidad = id_carrera = id_nivel = 0

        try:
            indice = Decimal(indice_raw)
            if not indice.is_finite() or not Decimal("0") <= indice <= Decimal("100"):
                errores.append("El índice académico debe estar entre 0 y 100.")
        except InvalidOperation:
            errores.append("Ingresa un índice académico numérico válido.")
            indice = Decimal("0")

        if errores:
            for mensaje in errores:
                flash(mensaje, "warning")
        else:
            try:
                with _database_cursor() as cursor:
                    cursor.execute(
                        """
                        SELECT registrar_estudiante(
                            %s, %s, %s, %s, %s, %s, %s, %s, %s
                        ) AS id_usuario
                        """,
                        (
                            nombre1,
                            nombre2,
                            apellido1,
                            apellido2,
                            correo,
                            id_universidad,
                            id_carrera,
                            id_nivel,
                            indice,
                        ),
                    )
                    id_usuario = cursor.fetchone()["id_usuario"]

                    cursor.execute(
                        "SELECT id_estudiante FROM estudiante WHERE id_usuario = %s",
                        (id_usuario,),
                    )
                    estudiante_row = cursor.fetchone()

                if estudiante_row is not None:
                    session["id_estudiante"] = estudiante_row["id_estudiante"]

                flash(
                    f"¡Bienvenido(a), {nombre1}! Tu perfil de estudiante fue registrado y tu sesión está activa.",
                    "success",
                )
                return redirect(url_for("estudiante.mi_panel"))

            except psycopg2.Error as exc:
                if getattr(exc, "pgcode", None) == "23505":
                    flash(
                        "Ya existe un usuario registrado con ese correo electrónico. Puedes iniciar sesión con él.",
                        "danger",
                    )
                else:
                    flash(f"No se pudo completar el registro: {_extraer_mensaje_pg(exc)}", "danger")

    with _database_cursor() as cursor:
        universidades, carreras, niveles, estudiantes = _cargar_catalogos_registro(cursor)

    return render_template(
        "registro_estudiante.html",
        universidades=universidades,
        carreras=carreras,
        niveles=niveles,
        estudiantes=estudiantes,
        form_data=form_data,
        next_url=request.args.get("next", ""),
    )


@estudiante_bp.post("/estudiante/login")
def iniciar_sesion():
    correo = request.form.get("correo", "").strip().lower()
    id_estudiante_raw = request.form.get("id_estudiante", "").strip()

    perfil = None
    with _database_cursor() as cursor:
        if id_estudiante_raw:
            try:
                id_est = int(id_estudiante_raw)
            except ValueError:
                id_est = 0
            if id_est > 0:
                perfil = _obtener_perfil_estudiante(cursor, id_est)
        elif correo:
            cursor.execute(
                """
                SELECT e.id_estudiante
                FROM estudiante AS e
                JOIN usuario AS u
                  ON u.id_usuario = e.id_usuario
                WHERE lower(u.correo) = %s
                """,
                (correo,),
            )
            row = cursor.fetchone()
            if row is not None:
                perfil = _obtener_perfil_estudiante(cursor, row["id_estudiante"])

    if perfil is None:
        flash(
            "No se encontró un estudiante con esos datos. Verifica el correo o regístrate.",
            "danger",
        )
        return redirect(url_for("estudiante.registro"))

    session["id_estudiante"] = perfil["id_estudiante"]
    flash(
        f"Sesión iniciada como {perfil['nombre1']} {perfil['apellido1']} (Índice: {perfil['indice_academico']}%).",
        "success",
    )
    return redirect(_safe_next_url("estudiante.mi_panel"))


@estudiante_bp.post("/estudiante/salir")
def cerrar_sesion():
    session.pop("id_estudiante", None)
    flash("Has cerrado tu sesión de estudiante.", "info")
    return redirect(url_for("estudiante.registro"))


@estudiante_bp.post("/interaccion")
def registrar_interaccion():
    id_estudiante = session.get("id_estudiante")
    if not id_estudiante:
        flash(
            "Debes iniciar sesión o registrar tu perfil de estudiante antes de guardar favoritos o postularte.",
            "warning",
        )
        next_url = request.form.get("next", "").strip()
        if next_url.startswith("/") and not next_url.startswith("//"):
            return redirect(url_for("estudiante.registro", next=next_url))
        return redirect(url_for("estudiante.registro"))

    id_oportunidad_raw = request.form.get("id_oportunidad", "").strip()
    accion = request.form.get("accion", "").strip().lower()
    estado_nombre = request.form.get("estado", "").strip()

    try:
        id_oportunidad = int(id_oportunidad_raw)
        if id_oportunidad <= 0:
            raise ValueError
    except ValueError:
        flash("La oportunidad seleccionada no es válida.", "danger")
        return redirect(_safe_next_url("estudiante.mi_panel"))

    destino = _safe_next_url("estudiante.mi_panel")

    if accion == "eliminar":
        try:
            with _database_cursor() as cursor:
                cursor.execute(
                    """
                    DELETE FROM interaccion
                    WHERE id_estudiante = %s
                      AND id_oportunidad = %s
                    """,
                    (id_estudiante, id_oportunidad),
                )
            flash("Se eliminó la interacción de tu panel.", "info")
        except psycopg2.Error as exc:
            flash(f"Error de PostgreSQL: {_extraer_mensaje_pg(exc)}", "danger")
        return redirect(destino)

    if estado_nombre.lower() not in {"favorito", "postulado"}:
        flash("El estado de interacción solicitado no es válido.", "warning")
        return redirect(destino)

    try:
        with _database_cursor() as cursor:
            cursor.execute(
                """
                SELECT id_estado, nombre
                FROM estado_interaccion
                WHERE lower(nombre) = lower(%s)
                """,
                (estado_nombre,),
            )
            estado_row = cursor.fetchone()
            if estado_row is None:
                flash(
                    f"No existe el estado '{estado_nombre}' en el catálogo estado_interaccion.",
                    "danger",
                )
                return redirect(destino)

            cursor.execute(
                """
                INSERT INTO interaccion (id_estudiante, id_oportunidad, id_estado)
                VALUES (%s, %s, %s)
                ON CONFLICT (id_estudiante, id_oportunidad)
                DO UPDATE SET
                    id_estado = EXCLUDED.id_estado,
                    fecha_accion = CURRENT_TIMESTAMP
                """,
                (id_estudiante, id_oportunidad, estado_row["id_estado"]),
            )

        if estado_row["nombre"].lower() == "postulado":
            flash("¡Postulación registrada correctamente!", "success")
        else:
            flash("Oportunidad guardada en tus favoritos.", "success")

    except psycopg2.Error as exc:
        flash(
            f"Validación de PostgreSQL rechazada: {_extraer_mensaje_pg(exc)}",
            "danger",
        )

    return redirect(destino)


@estudiante_bp.get("/mi-panel")
def mi_panel():
    id_estudiante = session.get("id_estudiante")
    if not id_estudiante:
        flash("Inicia sesión o regístrate para ver tu panel de estudiante.", "warning")
        return redirect(url_for("estudiante.registro"))

    with _database_cursor() as cursor:
        perfil = _obtener_perfil_estudiante(cursor, id_estudiante)
        if perfil is None:
            session.pop("id_estudiante", None)
            flash("Tu sesión ya no es válida. Vuelve a iniciar sesión.", "warning")
            return redirect(url_for("estudiante.registro"))

        cursor.execute(
            """
            SELECT
                inter.id_interaccion,
                inter.id_oportunidad,
                inter.fecha_accion,
                est_int.nombre AS estado,
                o.titulo,
                o.fecha_limite,
                tipo_op.nombre AS tipo_oportunidad,
                dest.nombre AS institucion_destino,
                p_dest.nombre AS pais_destino,
                n.nombre AS nivel_academico,
                b.indice_minimo,
                tb.nombre AS tipo_beca,
                orig.nombre AS universidad_origen,
                inc.cupos_disponibles,
                mod_inc.nombre AS modalidad
            FROM interaccion AS inter
            JOIN estado_interaccion AS est_int
              ON est_int.id_estado = inter.id_estado
            JOIN oportunidad AS o
              ON o.id_oportunidad = inter.id_oportunidad
            JOIN tipo_oportunidad AS tipo_op
              ON tipo_op.id_tipo_oportunidad = o.id_tipo_oportunidad
            JOIN institucion AS dest
              ON dest.id_institucion = o.id_institucion_destino
            JOIN pais AS p_dest
              ON p_dest.id_pais = dest.id_pais
            JOIN nivel_academico AS n
              ON n.id_nivel = o.id_nivel
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
            WHERE inter.id_estudiante = %s
            ORDER BY inter.fecha_accion DESC, o.titulo
            """,
            (id_estudiante,),
        )
        interacciones = cursor.fetchall()

        estados_por_oportunidad = {
            item["id_oportunidad"]: item["estado"] for item in interacciones
        }
        favoritos = [
            item for item in interacciones if item["estado"].lower() == "favorito"
        ]
        postulaciones = [
            item for item in interacciones if item["estado"].lower() != "favorito"
        ]

        cursor.execute(
            """
            SELECT *
            FROM vw_becas_disponibles
            WHERE indice_minimo <= %s
            ORDER BY
                CASE WHEN id_nivel = %s THEN 0 ELSE 1 END,
                fecha_limite ASC NULLS LAST,
                titulo
            """,
            (perfil["indice_academico"], perfil["id_nivel"]),
        )
        becas_recomendadas = cursor.fetchall()

        cursor.execute(
            """
            SELECT *
            FROM vw_intercambios_disponibles
            WHERE id_universidad_origen = %s
            ORDER BY
                CASE WHEN id_nivel = %s THEN 0 ELSE 1 END,
                cupos_disponibles DESC,
                fecha_limite ASC NULLS LAST,
                titulo
            """,
            (perfil["id_universidad_de_origen"], perfil["id_nivel"]),
        )
        intercambios_recomendados = cursor.fetchall()

    return render_template(
        "mi_panel.html",
        perfil=perfil,
        favoritos=favoritos,
        postulaciones=postulaciones,
        becas_recomendadas=becas_recomendadas,
        intercambios_recomendados=intercambios_recomendados,
        estados_por_oportunidad=estados_por_oportunidad,
    )
