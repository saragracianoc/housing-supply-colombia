-- =============================================================================
-- VISTAS ANALÍTICAS
-- Esquema: vivienda_col
-- Estas vistas separan la lógica de agregación de las consultas de análisis.
-- =============================================================================

USE `vivienda_col`;

-- -----------------------------------------------------------------------------
-- Vista: vw_total_vivienda_trimestre
-- Agrega unidades construidas y área por municipio, año y trimestre.
-- Base para análisis de estacionalidad y comparación entre ciudades.
-- -----------------------------------------------------------------------------

DROP VIEW IF EXISTS vw_total_vivienda_trimestre;

CREATE VIEW vw_total_vivienda_trimestre AS
SELECT
    m.Municipio,
    cv.Año,
    cv.Trimestre,
    SUM(cv.Unidades_vivienda)  AS total_unidades,
    SUM(cv.area_m2_constr)     AS total_area_m2
FROM construccion_vivienda cv
JOIN municipio m ON cv.cod_muni = m.cod_muni
GROUP BY m.Municipio, cv.Año, cv.Trimestre
ORDER BY m.Municipio, cv.Año, cv.Trimestre;

-- -----------------------------------------------------------------------------
-- Vista: vw_total_vivienda_anio
-- Agrega unidades y área por municipio y año, sin desagregación trimestral.
-- Útil para comparaciones interanuales entre ciudades.
-- -----------------------------------------------------------------------------

DROP VIEW IF EXISTS vw_total_vivienda_anio;

CREATE VIEW vw_total_vivienda_anio AS
SELECT
    m.Municipio,
    cv.Año,
    SUM(cv.Unidades_vivienda) AS total_unidades,
    SUM(cv.area_m2_constr)    AS total_area_m2
FROM construccion_vivienda cv
JOIN municipio m ON cv.cod_muni = m.cod_muni
GROUP BY m.Municipio, cv.Año
ORDER BY m.Municipio, cv.Año;

-- -----------------------------------------------------------------------------
-- Vista: vw_total_licencias_trimestre
-- Agrega licencias por municipio y trimestre. La tabla de hechos tiene
-- granularidad mensual, así que esta vista convierte mes a trimestre
-- con un CASE para alinearla con construccion_vivienda y rango_precio.
-- -----------------------------------------------------------------------------

DROP VIEW IF EXISTS vw_total_licencias_trimestre;

CREATE VIEW vw_total_licencias_trimestre AS
SELECT
    m.Municipio,
    lc.año_licencia                          AS Año,
    CASE
        WHEN lc.mes_licencia BETWEEN 1  AND 3  THEN 1
        WHEN lc.mes_licencia BETWEEN 4  AND 6  THEN 2
        WHEN lc.mes_licencia BETWEEN 7  AND 9  THEN 3
        WHEN lc.mes_licencia BETWEEN 10 AND 12 THEN 4
    END                                      AS Trimestre,
    SUM(lc.licencias)                        AS total_licencias,
    SUM(lc.area_m2_licencia)                 AS total_area_m2,
    SUM(lc.unidades_vivienda_licencia)       AS total_unidades
FROM licencia_construccion lc
JOIN municipio m ON lc.cod_municipio = m.cod_muni
GROUP BY m.Municipio, lc.año_licencia, Trimestre
ORDER BY m.Municipio, lc.año_licencia, Trimestre;
