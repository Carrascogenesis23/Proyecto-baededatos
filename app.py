from flask import Flask
from routes_estudiante import estudiante_bp

app = Flask(__name__)
app.secret_key = "proyecto_becas_secret"

app.register_blueprint(estudiante_bp)

@app.route("/")
def inicio():
    return """
    <h1>Sistema de Becas e Intercambios</h1>
    <a href='/registro'>Registrar Estudiante</a>
    """

if __name__ == "__main__":
    app.run(debug=True)