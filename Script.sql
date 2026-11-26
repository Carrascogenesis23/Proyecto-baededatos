DROP VIEW IF EXISTS vw_intercambios_disponibles CASCADE;
DROP VIEW IF EXISTS vw_becas_disponibles CASCADE;

DROP TABLE IF EXISTS multimedia_oportunidad CASCADE;
DROP TABLE IF EXISTS interaccion CASCADE;
DROP TABLE IF EXISTS intercambio CASCADE;
DROP TABLE IF EXISTS beca CASCADE;
DROP TABLE IF EXISTS oportunidad CASCADE;
DROP TABLE IF EXISTS administrador_universidad CASCADE;
DROP TABLE IF EXISTS estudiante CASCADE;
DROP TABLE IF EXISTS usuario CASCADE;
DROP TABLE IF EXISTS tipo_oportunidad CASCADE;
DROP TABLE IF EXISTS tipo_multimedia CASCADE;
DROP TABLE IF EXISTS carrera CASCADE;
DROP TABLE IF EXISTS estado_interaccion CASCADE;
DROP TABLE IF EXISTS modalidad_intercambio CASCADE;
DROP TABLE IF EXISTS tipo_beca CASCADE;
DROP TABLE IF EXISTS nivel_academico CASCADE;
DROP TABLE IF EXISTS institucion CASCADE;
DROP TABLE IF EXISTS pais CASCADE;


CREATE TABLE pais (
    id_pais  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre   VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE institucion (
    id_institucion INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre         VARCHAR(200) NOT NULL,
    id_pais        INT NOT NULL REFERENCES pais(id_pais),
    logo_url       VARCHAR(255),
    UNIQUE (nombre, id_pais)
);

CREATE TABLE nivel_academico (
    id_nivel INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre   VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE tipo_oportunidad (
    id_tipo_oportunidad INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre              VARCHAR(30) NOT NULL UNIQUE 
);

CREATE TABLE tipo_beca (
    id_tipo_beca INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre       VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE modalidad_intercambio (
    id_modalidad INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre       VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE estado_interaccion (
    id_estado INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre    VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE carrera (
    id_carrera INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre     VARCHAR(120) NOT NULL UNIQUE
);

CREATE TABLE tipo_multimedia (
    id_tipo_multimedia INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre             VARCHAR(30) NOT NULL UNIQUE
);
CREATE TABLE usuario(
id_usuario    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
nombre1               VARCHAR(30) NOT NULL,
    nombre2               VARCHAR(30) NULL,
    apellido1             VARCHAR(30) NOT NULL,
    apellido2             VARCHAR(30) NULL,
    correo                VARCHAR(120) NOT NULL UNIQUE,
    id_universidad_de_origen INT NOT NULL REFERENCES institucion(id_institucion)
);
CREATE TABLE estudiante (
    id_estudiante         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_carrera            INT NOT NULL REFERENCES carrera(id_carrera),
    id_nivel              INT NOT NULL REFERENCES nivel_academico(id_nivel),
    indice_academico      NUMERIC(5,2) NOT NULL CHECK (indice_academico BETWEEN 0 AND 100),
    id_usuario          INT NOT NULL UNIQUE REFERENCES usuario(id_usuario)
    );


CREATE TABLE administrador_universidad (
    id_admin       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    password_hash  VARCHAR(255) NOT null,
    activo         BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id_usuario       INT NOT NULL UNIQUE REFERENCES usuario(id_usuario)
);
CREATE TABLE oportunidad (
    id_oportunidad         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tipo_oportunidad    INT NOT NULL REFERENCES tipo_oportunidad(id_tipo_oportunidad),
    titulo                 VARCHAR(150) NOT NULL,
    descripcion            VARCHAR(500),
    fecha_limite           DATE,
    id_institucion_destino INT NOT NULL REFERENCES institucion(id_institucion),
    id_nivel               INT NOT NULL REFERENCES nivel_academico(id_nivel),
    id_carrera             INT NULL REFERENCES carrera(id_carrera) ON DELETE SET NULL,
    id_admin_publicador    INT REFERENCES administrador_universidad(id_admin)
);

CREATE TABLE beca (
    id_oportunidad INT PRIMARY KEY REFERENCES oportunidad(id_oportunidad) ON DELETE CASCADE,
    indice_minimo  NUMERIC(5,2) NOT NULL CHECK (indice_minimo BETWEEN 70 AND 100),
    id_tipo_beca   INT NOT NULL REFERENCES tipo_beca(id_tipo_beca)
);

CREATE TABLE intercambio (
    id_oportunidad        INT PRIMARY KEY REFERENCES oportunidad(id_oportunidad) ON DELETE CASCADE,
    id_universidad_origen INT NOT NULL REFERENCES institucion(id_institucion),
    cupos_disponibles     INT NOT NULL CHECK (cupos_disponibles >= 0),
    id_modalidad          INT NOT NULL REFERENCES modalidad_intercambio(id_modalidad)
);


CREATE TABLE interaccion (
    id_interaccion INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_estudiante  INT NOT NULL REFERENCES estudiante(id_estudiante),
    id_oportunidad INT NOT NULL REFERENCES oportunidad(id_oportunidad),
    id_estado      INT NOT NULL REFERENCES estado_interaccion(id_estado),
    fecha_accion   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (id_estudiante, id_oportunidad)
);

CREATE TABLE multimedia_oportunidad (
    id_multimedia      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_oportunidad     INT NOT NULL REFERENCES oportunidad(id_oportunidad) ON DELETE CASCADE,
    id_tipo_multimedia INT NOT NULL REFERENCES tipo_multimedia(id_tipo_multimedia),
    url_archivo        VARCHAR(255) NOT NULL,
    titulo_descriptivo VARCHAR(100),
    es_portada         BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_subida       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);



CREATE OR REPLACE FUNCTION registrar_estudiante(
    p_nombre1 VARCHAR,
    p_nombre2 VARCHAR,
    p_apellido1 VARCHAR,
    p_apellido2 VARCHAR,
    p_correo VARCHAR,
    p_id_universidad INT,
    p_id_carrera INT,
    p_id_nivel INT,
    p_indice NUMERIC
)
RETURNS INT AS $$
DECLARE
    v_id_usuario INT;
BEGIN
    INSERT INTO usuario (nombre1, nombre2, apellido1, apellido2, correo, id_universidad_de_origen)
    VALUES (p_nombre1, p_nombre2, p_apellido1, p_apellido2, p_correo, p_id_universidad)
    RETURNING id_usuario INTO v_id_usuario;

    INSERT INTO estudiante (id_carrera, id_nivel, indice_academico, id_usuario)
    VALUES (p_id_carrera, p_id_nivel, p_indice, v_id_usuario);

    RETURN v_id_usuario;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION registrar_admin_universidad(
    p_nombre1 VARCHAR,
    p_nombre2 VARCHAR,
    p_apellido1 VARCHAR,
    p_apellido2 VARCHAR,
    p_correo VARCHAR,
    p_id_universidad INT,
    p_password_hash VARCHAR
)
RETURNS INT AS $$
DECLARE
    v_id_usuario INT;
BEGIN
    INSERT INTO usuario (nombre1, nombre2, apellido1, apellido2, correo, id_universidad_de_origen)
    VALUES (p_nombre1, p_nombre2, p_apellido1, p_apellido2, p_correo, p_id_universidad)
    RETURNING id_usuario INTO v_id_usuario;

    INSERT INTO administrador_universidad (password_hash, id_usuario)
    VALUES (p_password_hash, v_id_usuario);

    RETURN v_id_usuario;
END;
$$ LANGUAGE plpgsql;

CREATE INDEX idx_estudiante_carrera ON estudiante(id_carrera);
CREATE INDEX idx_oportunidad_tipo ON oportunidad(id_tipo_oportunidad);
CREATE INDEX idx_oportunidad_institucion ON oportunidad(id_institucion_destino);
CREATE INDEX idx_oportunidad_nivel ON oportunidad(id_nivel);
CREATE INDEX idx_oportunidad_admin ON oportunidad(id_admin_publicador);
CREATE INDEX idx_usuario_institucion ON usuario(id_universidad_de_origen);
CREATE INDEX idx_intercambio_origen ON intercambio(id_universidad_origen);
CREATE INDEX idx_interaccion_estudiante ON interaccion(id_estudiante);
CREATE INDEX idx_interaccion_oportunidad ON interaccion(id_oportunidad);
CREATE INDEX idx_multimedia_oportunidad ON multimedia_oportunidad(id_oportunidad);
CREATE INDEX idx_multimedia_tipo ON multimedia_oportunidad(id_tipo_multimedia);
CREATE UNIQUE INDEX uq_multimedia_una_portada_por_oportunidad
    ON multimedia_oportunidad(id_oportunidad)
    WHERE es_portada = TRUE;

CREATE OR REPLACE FUNCTION validar_detalle_oportunidad()
RETURNS TRIGGER AS $$
DECLARE
    v_ids INT[];
    v_id INT;
    v_tipo VARCHAR(30);
    v_tiene_beca BOOLEAN;
    v_tiene_intercambio BOOLEAN;
BEGIN
    IF TG_OP = 'INSERT' THEN
        v_ids := ARRAY[NEW.id_oportunidad];
    ELSIF TG_OP = 'DELETE' THEN
        v_ids := ARRAY[OLD.id_oportunidad];
    ELSE
        v_ids := ARRAY[OLD.id_oportunidad, NEW.id_oportunidad];
    END IF;

    FOREACH v_id IN ARRAY v_ids LOOP
        SELECT t.nombre
        INTO v_tipo
        FROM oportunidad AS o
        JOIN tipo_oportunidad AS t
          ON t.id_tipo_oportunidad = o.id_tipo_oportunidad
        WHERE o.id_oportunidad = v_id;

        IF NOT FOUND THEN
            CONTINUE;
        END IF;

        SELECT EXISTS (
            SELECT 1 FROM beca WHERE id_oportunidad = v_id
        )
        INTO v_tiene_beca;

        SELECT EXISTS (
            SELECT 1 FROM intercambio WHERE id_oportunidad = v_id
        )
        INTO v_tiene_intercambio;

        IF (v_tipo = 'Beca') IS DISTINCT FROM v_tiene_beca THEN
            RAISE EXCEPTION
                'La oportunidad % debe tener exactamente el detalle correspondiente al tipo Beca.',
                v_id
                USING ERRCODE = '23514';
        END IF;

        IF (v_tipo = 'Intercambio') IS DISTINCT FROM v_tiene_intercambio THEN
            RAISE EXCEPTION
                'La oportunidad % debe tener exactamente el detalle correspondiente al tipo Intercambio.',
                v_id
                USING ERRCODE = '23514';
        END IF;
    END LOOP;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trg_validar_detalle_oportunidad
AFTER INSERT OR UPDATE OR DELETE ON oportunidad
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION validar_detalle_oportunidad();

CREATE CONSTRAINT TRIGGER trg_validar_detalle_beca
AFTER INSERT OR UPDATE OR DELETE ON beca
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION validar_detalle_oportunidad();

CREATE CONSTRAINT TRIGGER trg_validar_detalle_intercambio
AFTER INSERT OR UPDATE OR DELETE ON intercambio
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION validar_detalle_oportunidad();

CREATE OR REPLACE FUNCTION estado_reserva_cupo(p_id_estado INT)
RETURNS BOOLEAN AS $$
    SELECT lower(nombre) IN ('postulado', 'en revision', 'aceptado')
    FROM estado_interaccion
    WHERE id_estado = p_id_estado;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION validar_interaccion_postulacion()
RETURNS TRIGGER AS $$
DECLARE
    v_indice NUMERIC(5,2);
    v_universidad_estudiante INT;
    v_tipo_oportunidad VARCHAR(30);
    v_indice_minimo NUMERIC(5,2);
    v_universidad_origen INT;
BEGIN
    IF NOT estado_reserva_cupo(NEW.id_estado) THEN
        RETURN NEW;
    END IF;

    SELECT e.indice_academico, u.id_universidad_de_origen
    INTO v_indice, v_universidad_estudiante
    FROM estudiante AS e
    JOIN usuario AS u
      ON u.id_usuario = e.id_usuario
    WHERE e.id_estudiante = NEW.id_estudiante;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró el perfil del estudiante %.', NEW.id_estudiante
            USING ERRCODE = '23514';
    END IF;

    SELECT t.nombre, b.indice_minimo, i.id_universidad_origen
    INTO v_tipo_oportunidad, v_indice_minimo, v_universidad_origen
    FROM oportunidad AS o
    JOIN tipo_oportunidad AS t
      ON t.id_tipo_oportunidad = o.id_tipo_oportunidad
    LEFT JOIN beca AS b
      ON b.id_oportunidad = o.id_oportunidad
    LEFT JOIN intercambio AS i
      ON i.id_oportunidad = o.id_oportunidad
    WHERE o.id_oportunidad = NEW.id_oportunidad;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró la oportunidad %.', NEW.id_oportunidad
            USING ERRCODE = '23514';
    END IF;

    IF v_tipo_oportunidad = 'Beca' THEN
        IF v_indice_minimo IS NULL OR v_indice < v_indice_minimo THEN
            RAISE EXCEPTION
                'El índice académico (%) no alcanza el mínimo requerido (%) para esta beca.',
                v_indice, v_indice_minimo
                USING ERRCODE = '23514';
        END IF;
    ELSIF v_tipo_oportunidad = 'Intercambio' THEN
        IF v_universidad_origen IS NULL
           OR v_universidad_estudiante <> v_universidad_origen THEN
            RAISE EXCEPTION
                'El intercambio no está disponible para la universidad de origen del estudiante.'
                USING ERRCODE = '23514';
        END IF;
    ELSE
        RAISE EXCEPTION
            'No se permiten postulaciones para este tipo de oportunidad.'
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION reservar_cupo_intercambio(p_id_oportunidad INT)
RETURNS VOID AS $$
BEGIN
    UPDATE intercambio
    SET cupos_disponibles = cupos_disponibles - 1
    WHERE id_oportunidad = p_id_oportunidad
      AND cupos_disponibles > 0;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'No quedan cupos disponibles para el intercambio %.',
            p_id_oportunidad
            USING ERRCODE = '23514';
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION reservar_cupo_al_insertar_interaccion()
RETURNS TRIGGER AS $$
BEGIN
    IF estado_reserva_cupo(NEW.id_estado)
       AND EXISTS (
           SELECT 1 FROM intercambio
           WHERE id_oportunidad = NEW.id_oportunidad
       ) THEN
        PERFORM reservar_cupo_intercambio(NEW.id_oportunidad);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ajustar_cupo_al_actualizar_interaccion()
RETURNS TRIGGER AS $$
DECLARE
    v_reserva_anterior BOOLEAN;
    v_nueva_reserva BOOLEAN;
BEGIN
    v_reserva_anterior := estado_reserva_cupo(OLD.id_estado);
    v_nueva_reserva := estado_reserva_cupo(NEW.id_estado);

    IF v_reserva_anterior
       AND (
           NOT v_nueva_reserva
           OR OLD.id_oportunidad <> NEW.id_oportunidad
       )
       AND EXISTS (
           SELECT 1 FROM intercambio
           WHERE id_oportunidad = OLD.id_oportunidad
       ) THEN
        UPDATE intercambio
        SET cupos_disponibles = cupos_disponibles + 1
        WHERE id_oportunidad = OLD.id_oportunidad;
    END IF;

    IF v_nueva_reserva
       AND (
           NOT v_reserva_anterior
           OR OLD.id_oportunidad <> NEW.id_oportunidad
       )
       AND EXISTS (
           SELECT 1 FROM intercambio
           WHERE id_oportunidad = NEW.id_oportunidad
       ) THEN
        PERFORM reservar_cupo_intercambio(NEW.id_oportunidad);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION liberar_cupo_al_eliminar_interaccion()
RETURNS TRIGGER AS $$
BEGIN
    IF estado_reserva_cupo(OLD.id_estado)
       AND EXISTS (
           SELECT 1 FROM intercambio
           WHERE id_oportunidad = OLD.id_oportunidad
       ) THEN
        UPDATE intercambio
        SET cupos_disponibles = cupos_disponibles + 1
        WHERE id_oportunidad = OLD.id_oportunidad;
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_interaccion_postulacion
BEFORE INSERT OR UPDATE ON interaccion
FOR EACH ROW EXECUTE FUNCTION validar_interaccion_postulacion();

CREATE TRIGGER trg_reservar_cupo_al_insertar_interaccion
AFTER INSERT ON interaccion
FOR EACH ROW EXECUTE FUNCTION reservar_cupo_al_insertar_interaccion();

CREATE TRIGGER trg_ajustar_cupo_al_actualizar_interaccion
BEFORE UPDATE ON interaccion
FOR EACH ROW EXECUTE FUNCTION ajustar_cupo_al_actualizar_interaccion();

CREATE TRIGGER trg_liberar_cupo_al_eliminar_interaccion
AFTER DELETE ON interaccion
FOR EACH ROW EXECUTE FUNCTION liberar_cupo_al_eliminar_interaccion();

CREATE OR REPLACE VIEW vw_becas_disponibles AS
SELECT
    o.id_oportunidad,
    o.titulo,
    o.descripcion,
    o.fecha_limite,
    i.nombre AS institucion_destino,
    p.id_pais,
    p.nombre AS pais_destino,
    n.id_nivel,
    n.nombre AS nivel_academico,
    c.nombre AS carrera,
    b.indice_minimo,
    tb.id_tipo_beca,
    tb.nombre AS tipo_beca,
    (
        SELECT m.url_archivo
        FROM multimedia_oportunidad AS m
        JOIN tipo_multimedia AS tm
          ON tm.id_tipo_multimedia = m.id_tipo_multimedia
        WHERE m.id_oportunidad = o.id_oportunidad
          AND m.es_portada = TRUE
          AND tm.nombre = 'Imagen'
        ORDER BY m.fecha_subida DESC, m.id_multimedia DESC
        LIMIT 1
    ) AS portada_url
FROM oportunidad AS o
JOIN tipo_oportunidad AS to_tipo
  ON to_tipo.id_tipo_oportunidad = o.id_tipo_oportunidad
JOIN beca AS b
  ON b.id_oportunidad = o.id_oportunidad
JOIN tipo_beca AS tb
  ON tb.id_tipo_beca = b.id_tipo_beca
JOIN institucion AS i
  ON i.id_institucion = o.id_institucion_destino
JOIN pais AS p
  ON p.id_pais = i.id_pais
JOIN nivel_academico AS n
  ON n.id_nivel = o.id_nivel
LEFT JOIN carrera AS c
  ON c.id_carrera = o.id_carrera
WHERE to_tipo.nombre = 'Beca'
  AND (o.fecha_limite IS NULL OR o.fecha_limite >= CURRENT_DATE);

