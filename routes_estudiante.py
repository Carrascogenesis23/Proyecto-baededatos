from flask import Blueprint, render_template, request, redirect, url_for, flash
from db import get_connection

estudiante_bp = Blueprint('estudiante_bp', __name__)

@estudiante_bp.route('/registro', methods=['GET', 'POST'])
def registro():

    if request.method == 'POST':

        nombre1 = request.form['nombre1']
        nombre2 = request.form['nombre2']
        apellido1 = request.form['apellido1']
        apellido2 = request.form['apellido2']
        correo = request.form['correo']
        universidad = request.form['universidad']
        carrera = request.form['carrera']
        nivel = request.form['nivel']
        indice = request.form['indice']

        try:

            conn = get_connection()
            cur = conn.cursor()

            cur.execute(
                """
                SELECT registrar_estudiante(
                    %s,%s,%s,%s,%s,%s,%s,%s,%s
                )
                """,
                (
                    nombre1,
                    nombre2,
                    apellido1,
                    apellido2,
                    correo,
                    universidad,
                    carrera,
                    nivel,
                    indice
                )
            )

            conn.commit()

            cur.close()
            conn.close()

            flash("Estudiante registrado correctamente")

            return redirect(url_for('estudiante_bp.registro'))

        except Exception as e:

          print("ERROR DE POSTGRESQL:")
          print(e)

          flash(f"Error: {str(e)}")
    return render_template("registro_estudiante.html")