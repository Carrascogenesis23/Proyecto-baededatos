DROP VIEW IF EXISTS vw_intercambios_disponibles CASCADE;
DROP VIEW IF EXISTS vw_becas_disponibles CASCADE;

DROP TABLE IF EXISTS multimedia_oportunidad CASCADE;
DROP TABLE IF EXISTS interaccion CASCADE;
DROP TABLE IF EXISTS intercambio CASCADE;
DROP TABLE IF EXISTS beca CASCADE;
DROP TABLE IF EXISTS oportunidad CASCADE;
DROP TABLE IF EXISTS administrador_universidad CASCADE;
DROP TABLE IF EXISTS estudiante CASCADE;
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
CREATE INDEX idx_interaccion_estudiante ON interaccion(id_estudiante);
CREATE INDEX idx_multimedia_oportunidad ON multimedia_oportunidad(id_oportunidad);

