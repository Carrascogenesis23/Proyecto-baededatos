import os
import secrets

from flask import Flask

from routes_becas import becas_bp
from routes_intercambios import intercambios_bp


def create_app():
    app = Flask(__name__)
    app.config["SECRET_KEY"] = os.getenv("SECRET_KEY") or secrets.token_hex(32)
    app.register_blueprint(becas_bp)
    app.register_blueprint(intercambios_bp)
    return app


app = create_app()


if __name__ == "__main__":
    app.run()
