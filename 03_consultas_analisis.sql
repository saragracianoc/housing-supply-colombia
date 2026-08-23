-- =============================================================================
-- CONSULTAS DE ANÁLISIS EXPLORATORIO
-- Esquema: vivienda_col
-- Estas consultas documentan los hallazgos del proyecto.
-- Dependen de las vistas creadas en 02_vistas.sql.
-- =============================================================================

USE `vivienda_col`;

-- =============================================================================
-- 1. COMPARACIÓN LICENCIAS vs. CONSTRUCCIÓN POR TRIMESTRE
-- Cruza las dos vistas principales para tener en una sola tabla las unidades
-- construidas junto con las licencias aprobadas, por municipio y trimestre.
-- =============================================================================

SELECT
    v.Municipio,
    v.Año,
    v.Trimestre,
    v.total_unidades        AS unidades_construidas,
    l.total_licencias       AS licencias_aprobadas,
    l.total_unidades        AS unidades_autorizadas_licencia
FROM vw_total_vivienda_trimestre v
JOIN vw_total_licencias_trimestre l
    ON v.Municipio = l.Municipio
    AND v.Año      = l.Año
    AND v.Trimestre = l.Trimestre;

-- =============================================================================
-- 2. TRIMESTRE CON MÁS CONSTRUCCIÓN POR AÑO
-- Identifica cuál trimestre concentra la mayor actividad constructiva cada año.
-- Hallazgo: el Trimestre 1 domina consistentemente.
-- =============================================================================

WITH base AS (
    SELECT
        v.Municipio,
        v.Año,
        v.Trimestre,
        v.total_unidades  AS unidades_construidas,
        l.total_licencias AS licencias_aprobadas
    FROM vw_total_vivienda_trimestre v
    JOIN vw_total_licencias_trimestre l
        ON v.Municipio  = l.Municipio
        AND v.Año       = l.Año
        AND v.Trimestre = l.Trimestre
),

maximo_construccion AS (
    SELECT Año, Trimestre
    FROM base
    WHERE (Año, unidades_construidas) IN (
        SELECT Año, MAX(unidades_construidas)
        FROM base
        GROUP BY Año
    )
),

maximo_licencias AS (
    SELECT Año, Trimestre
    FROM base
    WHERE (Año, licencias_aprobadas) IN (
        SELECT Año, MAX(licencias_aprobadas)
        FROM base
        GROUP BY Año
    )
),

frecuencia_construccion AS (
    SELECT Trimestre, COUNT(*) AS veces_maximo_construccion
    FROM maximo_construccion
    GROUP BY Trimestre
),

frecuencia_licencias AS (
    SELECT Trimestre, COUNT(*) AS veces_maximo_licencias
    FROM maximo_licencias
    GROUP BY Trimestre
)

SELECT
    fc.Trimestre,
    fc.veces_maximo_construccion,
    fl.veces_maximo_licencias
FROM frecuencia_construccion fc
JOIN frecuencia_licencias fl ON fc.Trimestre = fl.Trimestre
ORDER BY fc.veces_maximo_construccion DESC;

-- =============================================================================
-- 3. EVOLUCIÓN DE LICENCIAS POR AÑO
-- Muestra la caída sostenida en el conteo de trámites de licencia.
-- =============================================================================

SELECT año_licencia, SUM(licencias) AS total_licencias
FROM licencia_construccion
GROUP BY año_licencia
ORDER BY total_licencias DESC;

-- =============================================================================
-- 4. RANGO DE PRECIO MÁS ALTO (RANGO 6) POR CIUDAD
-- Rango 6 = más de 435 SMLMV, segmento No VIS alto.
-- Identifica qué ciudad concentra la mayor oferta en el segmento premium.
-- =============================================================================

SELECT m.Municipio, SUM(rp.Unidades_por_rango) AS total_unidades
FROM rango_precio rp
JOIN municipio m ON rp.cod_muni = m.cod_muni
WHERE rp.Rango_precio = 'Rango 6'
GROUP BY m.Municipio
ORDER BY total_unidades DESC
LIMIT 1;

-- =============================================================================
-- 5. AÑO CON MÁS UNIDADES EN RANGO 6 (PREMIUM)
-- =============================================================================

SELECT anio, SUM(Unidades_por_rango) AS total_unidades
FROM rango_precio
WHERE Rango_precio = 'Rango 6'
GROUP BY anio
ORDER BY total_unidades DESC
LIMIT 1;

-- =============================================================================
-- 6. CONSTRUCCIÓN VIS POR AÑO EN BOGOTÁ
-- Documenta el pico VIS de 2022 en Bogotá.
-- =============================================================================

SELECT Año, SUM(Unidades_vivienda) AS total_unidades
FROM construccion_vivienda
WHERE cod_muni = '111' AND Subsidio_construccion = 'VIS'
GROUP BY Año
ORDER BY total_unidades DESC;

-- =============================================================================
-- 7. DETALLE TRIMESTRAL POR CIUDAD
-- Consultas puntuales para exploración por ciudad.
-- =============================================================================

-- Bogotá: trimestres ordenados por volumen de construcción
SELECT Municipio, Año, Trimestre, total_unidades
FROM vw_total_vivienda_trimestre
WHERE Municipio = 'Bogota'
ORDER BY total_unidades DESC;

-- Cartagena: trimestres con menor actividad
SELECT Municipio, Año, Trimestre, total_unidades
FROM vw_total_vivienda_trimestre
WHERE Municipio = 'Cartagena'
ORDER BY total_unidades ASC;
