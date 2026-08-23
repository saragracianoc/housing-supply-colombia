-- =============================================================================
-- ESQUEMA: vivienda_col
-- Creación de tablas para el análisis de oferta de vivienda en Colombia
-- Fuentes: DANE (CEE, ELIC), MVCT
-- Periodo: 2019-2023
-- Ciudades: Bogotá, Medellín, Cali, Cartagena, Barranquilla
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS `vivienda_col`;
USE `vivienda_col`;

-- -----------------------------------------------------------------------------
-- DIMENSIÓN: municipio
-- Tabla de referencia con los 5 municipios del análisis.
-- cod_muni se mantiene como VARCHAR(3) para preservar ceros iniciales (051, 081).
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS municipio;

CREATE TABLE municipio (
    cod_muni     VARCHAR(3)   NOT NULL,
    Municipio    VARCHAR(50)  NOT NULL,
    Departamento VARCHAR(50)  NOT NULL,
    PRIMARY KEY (cod_muni)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO municipio (cod_muni, Municipio, Departamento) VALUES
('051', 'Medellin',     'Antioquia'),
('081', 'Barranquilla', 'Atlantico'),
('111', 'Bogota',       'Bogota'),
('131', 'Cartagena',    'Bolivar'),
('761', 'Cali',         'Valle del Cauca');

-- -----------------------------------------------------------------------------
-- HECHO: construccion_vivienda
-- Unidades de vivienda iniciadas y área construida, por trimestre y tipo de
-- subsidio (VIS, VIP, No_VIS). Fuente: Censo de Edificaciones del DANE.
-- 270 registros.
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS construccion_vivienda;

CREATE TABLE construccion_vivienda (
    id                     INT           NOT NULL AUTO_INCREMENT,
    Año                    INT           NOT NULL,
    Trimestre              INT           NOT NULL,
    Subsidio_construccion  VARCHAR(10)   NOT NULL,
    Unidades_vivienda      INT           NOT NULL,
    area_m2_constr         FLOAT,
    cod_muni               VARCHAR(3)    NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_cv_municipio
        FOREIGN KEY (cod_muni) REFERENCES municipio(cod_muni)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- HECHO: licencia_construccion
-- Licencias de construcción aprobadas, con desagregación por clase de suelo,
-- tipo de vivienda, estrato y subsidio. Granularidad mensual.
-- Fuente: ELIC del DANE. 2.793 registros (filtrados a destino = vivienda).
--
-- Nota: la tabla cruda (licencias_construccion_raw) contenía columnas codificadas
-- numéricamente. La limpieza aplicó estos mapeos:
--   clase_suelo:       1=urbana, 2=suburbana, 3=rural
--   tipo_vivienda:     1=casas, 2=apartamentos
--   subsidio_licencia: 1=VIS, 2=No_VIS, 3=VIP
--   destino:           filtrado a destino=1 (vivienda), columna eliminada
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS licencia_construccion;

CREATE TABLE licencia_construccion (
    id                          INT          NOT NULL AUTO_INCREMENT,
    cod_municipio               VARCHAR(3)   NOT NULL,
    año_licencia                INT          NOT NULL,
    mes_licencia                INT          NOT NULL,
    estrato_licencia            INT,
    area_m2_licencia            FLOAT,
    unidades_vivienda_licencia  INT,
    licencias                   INT,
    clase_suelo                 VARCHAR(15)  NOT NULL,
    tipo_vivienda               VARCHAR(15)  NOT NULL,
    subsidio_licencia           VARCHAR(10)  NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_lc_municipio
        FOREIGN KEY (cod_municipio) REFERENCES municipio(cod_muni)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- HECHO: rango_precio
-- Distribución de unidades de vivienda nueva por rango de precio (en SMLMV).
-- Rango 1 a 5 corresponden a franjas definidas. Rango 6 = más de 435 SMLMV
-- (No VIS alto, sin tope superior definido). 515 registros.
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS rango_precio;

CREATE TABLE rango_precio (
    id_rango_precio    INT          NOT NULL AUTO_INCREMENT,
    cod_muni           VARCHAR(3)   NOT NULL,
    anio               INT          NOT NULL,
    Trimestre          INT          NOT NULL,
    Rango_precio       VARCHAR(15)  NOT NULL,
    Unidades_por_rango INT,
    area_m2_rango      FLOAT,
    PRIMARY KEY (id_rango_precio),
    CONSTRAINT fk_rp_municipio
        FOREIGN KEY (cod_muni) REFERENCES municipio(cod_muni)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- REFERENCIA: indice_precio_vivienda
-- Índice de precios de vivienda nueva (IPVN) por municipio y trimestre.
-- 100 registros. Excluida del modelo final de Power BI por diferencias de
-- granularidad y cobertura respecto a las demás tablas. Se conserva en el
-- esquema como referencia para análisis futuros.
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS indice_precio_vivienda;

CREATE TABLE indice_precio_vivienda (
    id_indice_precio  INT          NOT NULL AUTO_INCREMENT,
    cod_muni          VARCHAR(3)   NOT NULL,
    municipio         VARCHAR(50),
    anio              INT          NOT NULL,
    Trimestre         INT          NOT NULL,
    indice_precio     INT,
    PRIMARY KEY (id_indice_precio),
    CONSTRAINT fk_ipvn_municipio
        FOREIGN KEY (cod_muni) REFERENCES municipio(cod_muni)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- DIMENSIÓN: temporalidad_vivienda
-- Tabla de tiempo centralizada para Power BI. Permite filtrado cruzado
-- consistente entre las tres tablas de hechos sin relaciones directas
-- entre ellas. Generada con combinaciones año x trimestre para 2019-2023.
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS temporalidad_vivienda;

CREATE TABLE temporalidad_vivienda (
    id_tiempo   INT NOT NULL AUTO_INCREMENT,
    anio        INT NOT NULL,
    trimestre   INT NOT NULL,
    PRIMARY KEY (id_tiempo),
    UNIQUE KEY uq_periodo (anio, trimestre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO temporalidad_vivienda (anio, trimestre) VALUES
(2019, 1), (2019, 2), (2019, 3), (2019, 4),
(2020, 1), (2020, 2), (2020, 3), (2020, 4),
(2021, 1), (2021, 2), (2021, 3), (2021, 4),
(2022, 1), (2022, 2), (2022, 3), (2022, 4),
(2023, 1), (2023, 2), (2023, 3), (2023, 4);

-- =============================================================================
-- NOTA SOBRE ENCODING (BOM)
-- Los CSV exportados desde Excel llegaron con codificación UTF-8 con BOM,
-- lo que causó que MySQL importara la primera columna como ï»¿cod_muni.
-- Corrección aplicada:
--   ALTER TABLE rango_precio CHANGE `ï»¿cod_muni` cod_muni VARCHAR(3) NOT NULL;
-- Prevención: leer con encoding='utf-8-sig' en pandas, o exportar desde
-- Excel como "CSV UTF-8 (sin BOM)".
-- =============================================================================
