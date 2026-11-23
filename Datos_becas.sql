insert into pais(nombre) values 
    ('Alemania'), ('Argentina'), ('Bélgica'), ('Brasil'), ('Chile'), ('China'),
    ('Colombia'), ('Corea del Sur'), ('Costa Rica'), ('Croacia'), ('Cuba'),
    ('Ecuador'), ('El Salvador'), ('Eslovaquia'), ('España'), ('Estados Unidos'),
    ('Francia'), ('Grecia'), ('Guatemala'), ('Honduras'), ('Italia'), ('Japón'),
    ('México'), ('Nicaragua'), ('Países Bajos'), ('Panamá'), ('Polonia'),
    ('Portugal'), ('República Dominicana'), ('Rumania'), ('Suiza'), ('Turquía'), ('Qatar')
on conflict(nombre) do nothing;

insert into nivel_academico(nombre) values 
    ('Pregrado'), ('postgrado'), ('Doctorado') 
on conflict (nombre) do nothing;

insert into tipo_beca(nombre) values 
    ('Anual'), ('Parcial'), ('Equidad social'), ('talento')
on conflict (nombre) do nothing;


insert into estado_interaccion(nombre) values
   ('Postulado'), ('En revision'), ('aceptado'), ('rechazado') 
on conflict (nombre) do nothing;


insert into modalidad_intercambio(nombre) values
     ('Semestral'), ('Anual')
on conflict (nombre) do nothing;

insert into carrera (nombre) values
    ('Administración de Empresas'), ('Administración de Empresas Turísticas'),
    ('Arquitectura'), ('Comercio Internacional'), ('Comunicación Audiovisual y Publicitaria'),
    ('Contaduría Pública'), ('Derecho'), ('Diseño Gráfico'),
    ('Economía'), ('Enfermería'), ('Finanzas'), ('Física'),
    ('Gastronomía'), ('Ingeniería Ambiental'), ('Ingeniería Biomédica'),
    ('Ingeniería Civil'), ('Ingeniería Eléctrica Industrial'),
    ('Ingeniería en Sistemas Computacionales'), ('Ingeniería Industrial'),
    ('Ingeniería Mecánica Industrial'), ('Ingeniería Mecatrónica'),
    ('Ingeniería Química Industrial'), ('Lenguas Extranjeras'), ('Matemáticas'), ('Medicina'),
    ('Mercadotecnia'), ('Nutrición'), ('Odontología'), ('Pedagogía y Ciencias de la Educación'),
    ('Periodismo'), ('Psicología'), ('Química y Farmacia'), ('Relaciones Internacionales'),
    ('Trabajo Social')
on conflict (nombre) do nothing;

insert into tipo_multimedia (nombre) values
    ('Imagen'), ('Video')
on conflict (nombre) do nothing;

insert into tipo_oportunidad (nombre) values
    ('Beca'), ('Intercambio'), ('Práctica profesional')
on conflict (nombre) do nothing;

insert into institucion(nombre, id_pais, logo_url) 
select v.nombre, pais.id_pais, null 
from (values 
    ('Universidad Nacional Autónoma de Honduras(UNAH)'),
    ('Universidad Pedagógica Nacional Francisco Morazán(UPNFM)'),
    ('Universidad Tecnológica Centroamericana(UNITEC)'),
    ('Universidad Católica de Honduras(UNICAH)'),
    ('Universidad José Cecilio del Valle(UJCV)'),
    ('Universidad Tecnológica de Honduras(UTH)')
) as v(nombre) 
cross join pais 
where pais.nombre = 'Honduras' 
on conflict (nombre, id_pais) do nothing;

insert into institucion (nombre, id_pais, logo_url)
select distinct v.nombre, p.id_pais, null
from (values
    ('Universidad Complutense de Madrid', 'España'),
    ('Universidad Nacional Autónoma de México (UNAM)', 'México'),
    ('Universidad Técnica de Múnich (TUM)', 'Alemania'),
    ('Universidad de Costa Rica (UCR)', 'Costa Rica'),
    ('Universidad de Málaga (UMA)', 'España'),
    ('Universidad de Valladolid (UVa)', 'España'),
    ('Universidad de Granada (UGR)', 'España'),
    ('Tecnológico de Monterrey', 'México'),
    ('Universidad Andrés Bello', 'Chile'),
    ('Universidad Europea (UE)', 'España'),
    ('Universidad Latinoamericana de Ciencia y Tecnología (ULACIT)', 'Costa Rica'),
    ('Universidad de Sevilla (US)', 'España'),
    ('Pontificia Universidad Javeriana', 'Colombia'),
    ('Universidad de Guadalajara (UdeG)', 'México'),
    ('Universidad Autónoma de Nuevo León (UANL)', 'México')
) as v(nombre, pais_nombre)
join pais p on p.nombre = v.pais_nombre
on conflict (nombre, id_pais) do nothing;

do $$
begin
 
    if not exists (select 1 from usuario where correo = 'movilidad@unah.edu.hn') then
        perform registrar_admin_universidad(
            'Carlos',
            null,
            'Reyes',
            'Mendoza',
            'movilidad@unah.edu.hn',
            (select id_institucion from institucion where nombre = 'Universidad Nacional Autónoma de Honduras(UNAH)'),
            '$2b$12$EjemploHashSeguroParaDesarrollo1234567890'
        );
    end if;

    
    if not exists (select 1 from usuario where correo = 'Maria.prueba@unah.hn') then
        perform registrar_estudiante(
            'Maria', null, 'Reyes', 'Cruz',
            'Maria.prueba@unah.hn',
            (select id_institucion from institucion where nombre = 'Universidad Nacional Autónoma de Honduras(UNAH)'),
            (select id_carrera from carrera where nombre = 'Ingeniería en Sistemas Computacionales'),
            (select id_nivel from nivel_academico where nombre = 'Pregrado'),
            91.50
        );
    end if;

   
    if not exists (select 1 from usuario where correo = 'diego.alvarez@unitec.edu') then
        perform registrar_estudiante(
            'Diego', null, 'Álvarez', 'Mejía',
            'diego.alvarez@unitec.edu',
            (select id_institucion from institucion where nombre = 'Universidad Tecnológica Centroamericana(UNITEC)'),
            (select id_carrera from carrera where nombre = 'Arquitectura'),
            (select id_nivel from nivel_academico where nombre = 'Pregrado'),
            86.00
        );
    end if;
end $$;


with op_beca_alemania as (
    insert into oportunidad (
        id_tipo_oportunidad, titulo, descripcion, fecha_limite,
        id_institucion_destino, id_nivel, id_carrera, id_admin_publicador
    )
    select
        (select id_tipo_oportunidad from tipo_oportunidad where nombre = 'Beca'),
        'Beca DAAD EPOS - Posgrado en Alemania (TUM)',
        'Programa de beca completa del Servicio Alemán de Intercambio Académico (DAAD) para cursar estudios de maestría en áreas STEM y desarrollo sostenible en Múnich. Incluye estipendio mensual, seguro médico y boletos aéreos.',
        '2027-12-15',
        (select id_institucion from institucion where nombre = 'Universidad Técnica de Múnich (TUM)'),
        (select id_nivel from nivel_academico where nombre = 'postgrado'),
        null,
        (select a.id_admin from administrador_universidad a join usuario u on a.id_usuario = u.id_usuario where u.correo = 'movilidad@unah.edu.hn')
    where not exists (
        select 1 from oportunidad where titulo = 'Beca DAAD EPOS - Posgrado en Alemania (TUM)'
    )
    returning id_oportunidad
)
insert into beca (id_oportunidad, indice_minimo, id_tipo_beca)
select
    id_oportunidad,
    85.00,
    (select id_tipo_beca from tipo_beca where nombre = 'Anual')
from op_beca_alemania;


with op_beca_espana as (
    insert into oportunidad (
        id_tipo_oportunidad, titulo, descripcion, fecha_limite,
        id_institucion_destino, id_nivel, id_carrera, id_admin_publicador
    )
    select
        (select id_tipo_oportunidad from tipo_oportunidad where nombre = 'Beca'),
        'Beca Fundación Carolina - Posgrado en Madrid (UCM)',
        'Beca parcial para cursar estudios de posgrado en la Universidad Complutense de Madrid.',
        '2027-02-20',
        (select id_institucion from institucion where nombre = 'Universidad Complutense de Madrid'),
        (select id_nivel from nivel_academico where nombre = 'postgrado'),
        null,
        (select a.id_admin from administrador_universidad a join usuario u on a.id_usuario = u.id_usuario where u.correo = 'movilidad@unah.edu.hn')
    where not exists (
        select 1 from oportunidad where titulo = 'Beca Fundación Carolina - Posgrado en Madrid (UCM)'
    )
    returning id_oportunidad
)
insert into beca (id_oportunidad, indice_minimo, id_tipo_beca)
select
    id_oportunidad,
    82.00,
    (select id_tipo_beca from tipo_beca where nombre = 'Parcial')
from op_beca_espana;


with op_uma_sistemas as (
    insert into oportunidad (
        id_tipo_oportunidad, titulo, descripcion, fecha_limite,
        id_institucion_destino, id_nivel, id_carrera, id_admin_publicador
    )
    select
        (select id_tipo_oportunidad from tipo_oportunidad where nombre = 'Intercambio'),
        'Intercambio Académico en Ingeniería Informática y Sistemas - Universidad de Málaga (UMA)',
        'Movilidad semestral en la E.T.S. de Ingeniería Informática de la Universidad de Málaga (España) para cursar asignaturas de desarrollo de software, bases de datos y redes bajo convenio bilateral.',
        '2027-01-18',
        (select id_institucion from institucion where nombre = 'Universidad de Málaga (UMA)'),
        (select id_nivel from nivel_academico where nombre = 'Pregrado'),
        (select id_carrera from carrera where nombre = 'Ingeniería en Sistemas Computacionales'),
        (select a.id_admin from administrador_universidad a join usuario u on a.id_usuario = u.id_usuario where u.correo = 'movilidad@unah.edu.hn')
    where not exists (
        select 1 from oportunidad where titulo = 'Intercambio Académico en Ingeniería Informática y Sistemas - Universidad de Málaga (UMA)'
    )
    returning id_oportunidad
)
insert into intercambio (id_oportunidad, id_universidad_origen, cupos_disponibles, id_modalidad)
select
    id_oportunidad,
    (select id_institucion from institucion where nombre = 'Universidad Nacional Autónoma de Honduras(UNAH)'),
    4,
    (select id_modalidad from modalidad_intercambio where nombre = 'Anual')
from op_uma_sistemas;


with op_tec_arq as (
    insert into oportunidad (
        id_tipo_oportunidad, titulo, descripcion, fecha_limite,
        id_institucion_destino, id_nivel, id_carrera, id_admin_publicador
    )
    select
        (select id_tipo_oportunidad from tipo_oportunidad where nombre = 'Intercambio'),
        'Intercambio Académico en Arquitectura - Tecnológico de Monterrey',
        'Movilidad académica en México para cursar talleres de diseño arquitectónico y urbanismo.',
        '2027-02-10',
        (select id_institucion from institucion where nombre = 'Tecnológico de Monterrey'),
        (select id_nivel from nivel_academico where nombre = 'Pregrado'),
        (select id_carrera from carrera where nombre = 'Arquitectura'),
        (select a.id_admin from administrador_universidad a join usuario u on a.id_usuario = u.id_usuario where u.correo = 'movilidad@unah.edu.hn')
    where not exists (
        select 1 from oportunidad where titulo = 'Intercambio Académico en Arquitectura - Tecnológico de Monterrey'
    )
    returning id_oportunidad
)
insert into intercambio (id_oportunidad, id_universidad_origen, cupos_disponibles, id_modalidad)
select

    id_oportunidad,
    (select id_institucion from institucion where nombre = 'Universidad Tecnológica Centroamericana(UNITEC)'),
    3,
    (select id_modalidad from modalidad_intercambio where nombre = 'Presencial')
from op_tec_arq;


insert into multimedia_oportunidad (id_oportunidad, id_tipo_multimedia, url_archivo, titulo_descriptivo, es_portada)
select
    o.id_oportunidad,
    (select id_tipo_multimedia from tipo_multimedia where nombre = 'Imagen'),
    'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?w=800',
    'Campus TUM Múnich - Beca DAAD',
    true
from oportunidad o
where o.titulo = 'Beca DAAD EPOS - Posgrado en Alemania (TUM)'
  and not exists (select 1 from multimedia_oportunidad m where m.id_oportunidad = o.id_oportunidad);

insert into multimedia_oportunidad (id_oportunidad, id_tipo_multimedia, url_archivo, titulo_descriptivo, es_portada)
select
    o.id_oportunidad,
    (select id_tipo_multimedia from tipo_multimedia where nombre = 'Imagen'),
    'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=800',
    'Campus Universidad de Málaga (UMA)',
    true
from oportunidad o
where o.titulo = 'Intercambio Académico en Ingeniería Informática y Sistemas - Universidad de Málaga (UMA)'
  and not exists (select 1 from multimedia_oportunidad m where m.id_oportunidad = o.id_oportunidad);

insert into interaccion (id_estudiante, id_oportunidad, id_estado)
select
    e.id_estudiante,
    o.id_oportunidad,
    (select id_estado from estado_interaccion where nombre = 'Postulado')
from estudiante est
join usuario u on est.id_usuario = u.id_usuario
cross join oportunidad o
where u.correo = 'genesis.prueba@unah.hn'
  and o.titulo = 'Intercambio Académico en Ingeniería Informática y Sistemas - Universidad de Málaga (UMA)'
on conflict (id_estudiante, id_oportunidad) do nothing;


insert into interaccion (id_estudiante, id_oportunidad, id_estado)
select
    e.id_estudiante,
    o.id_oportunidad,
    (select id_estado from estado_interaccion where nombre = 'Postulado')
from estudiante est
join usuario u on est.id_usuario = u.id_usuario
cross join oportunidad o
where u.correo = 'diego.alvarez@unitec.edu'
  and o.titulo = 'Intercambio Académico en Arquitectura - Tecnológico de Monterrey'
on conflict (id_estudiante, id_oportunidad) do nothing;