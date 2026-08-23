# Comportamiento de la oferta de vivienda en Colombia (2019–2023)

Análisis del mercado de vivienda nueva en cinco ciudades colombianas (Bogotá, Medellín, Cali, Cartagena y Barranquilla) para evaluar la dinámica entre licencias de construcción, unidades efectivamente construidas, rangos de precio y distribución por tipo de subsidio (VIS, VIP, No VIS).

El proyecto responde a una necesidad del Gobierno Nacional de contar con una base de datos integrada que permita comparar el comportamiento histórico de la oferta de vivienda entre ciudades, detectar patrones temporales y evaluar políticas de vivienda existentes.

## Pregunta de negocio

¿Cómo se comportó la oferta de vivienda nueva entre 2019 y 2023 en las cinco principales ciudades del país, y qué relación existe entre las licencias aprobadas, las unidades construidas y la distribución por estrato y tipo de subsidio?

## Stack técnico

| Herramienta | Rol en el pipeline |
|---|---|
| Excel | Reestructuración de archivos crudos del DANE (unpivot de columnas VIS/No VIS/VIP, alineación de hojas con encabezados desplazados) |
| Python / pandas | Limpieza de encoding (UTF-8 BOM), formato numérico colombiano (`.` miles, `,` decimal), transformaciones wide-to-long |
| Databricks | Procesamiento en arquitectura lakehouse Bronze/Silver/Gold |
| MySQL (Workbench) | Modelo relacional con esquema estrella, vistas analíticas, consultas de exploración |
| draw.io | Diagrama entidad-relación del modelo |
| Power BI | Dashboard final con modelo semántico estrella y medidas DAX |

## Fuentes de datos

Todas las fuentes provienen de datos abiertos del DANE y el MVCT:

- **Censo de Edificaciones (CEE):** unidades de vivienda iniciadas por trimestre, clasificadas por tipo de subsidio (VIS/VIP/No VIS) y ciudad
- **Estadísticas de Licencias de Construcción (ELIC):** metros cuadrados aprobados, unidades autorizadas, conteo de licencias; desagregado por clase de suelo (urbana/suburbana/rural), tipo de vivienda (casas/apartamentos), estrato socioeconómico y subsidio
- **Rangos de precio de vivienda nueva:** distribución de unidades por rango de precio (SMLMV) y ciudad

## Modelo de datos

### Esquema estrella en MySQL (`vivienda_col`)

**Tablas de hechos:**
- `construccion_vivienda` — 270 registros, granularidad trimestral, unidades y área por tipo de subsidio
- `licencia_construccion` — 2.793 registros, granularidad mensual, desagregación por estrato, clase de suelo y tipo de vivienda
- `rango_precio` — 515 registros, distribución trimestral por rango de precio

**Tablas de dimensión:**
- `municipio` — 5 ciudades con código DANE de 3 dígitos y departamento
- `temporalidad_vivienda` — dimensión de tiempo centralizada (2019–2023), utilizada en Power BI como eje temporal único para filtrado cruzado entre tablas de hechos

### Decisiones de diseño documentadas

**Exclusión de la tabla IPVN.** La tabla `indice_precio_vivienda` se procesó y cargó en MySQL, pero se excluyó del modelo final de Power BI. Su granularidad y cobertura no eran directamente compatibles con las demás tablas sin introducir supuestos de comparabilidad que no estaban validados. Quedó como referencia en la capa Bronze de Databricks.

**Preservación de `municipio` como dimensión.** Se evaluó desnormalizar `municipio` directamente en las tablas de hechos (son solo 5 registros). Se decidió conservarla como tabla separada para mantener un único punto de verdad sobre nombres y departamentos, dado que el costo del join es negligible.

**Dimensión de tiempo centralizada.** Sin `temporalidad_vivienda`, cada visual en Power BI que cruzara tablas de hechos requería relaciones directas entre ellas, generando ambigüedad de filtrado. Centralizar el eje temporal resuelve el filtrado cruzado sin relaciones muchos-a-muchos entre tablas de hechos.

**Códigos de municipio como texto.** Los códigos DANE (`051`, `081`, `111`, `131`, `761`) se preservan como `VARCHAR(3)` en todo el pipeline. Interpretarlos como entero elimina el cero inicial y rompe la integridad referencial contra cualquier tabla que use el estándar oficial.

## Hallazgos principales

**Rezago entre licencias y construcción.** El conteo de licencias otorgadas (trámites) cayó de forma sostenida entre 2019 (3.553) y 2023 (2.595). Las unidades efectivamente construidas siguieron una trayectoria distinta: subieron hasta un pico de 81.494 en 2022 y cayeron a 41.217 en 2023. La lectura es que se ejecutaron proyectos que llevaban años en trámite, no que el sector creciera por nuevas licencias.

**Concentración VIS en Bogotá.** Bogotá lidera la construcción VIS en todos los años del rango, con un salto de 9.504 unidades en 2019 a 23.357 en 2022. Ninguna de las otras cuatro ciudades supera las 8.000 unidades VIS en su mejor año.

**Estacionalidad en el primer trimestre.** El trimestre 1 concentra 92.556 unidades construidas (acumulado 2019–2023) contra un rango de 70.044 a 77.875 en los demás trimestres. El patrón es consistente entre ciudades.

**Correlación licencias-construcción.** La correlación entre unidades autorizadas en licencias y unidades construidas, agregada por ciudad y trimestre, es de 0.79 en el pooled, con variación por ciudad (desde 0.01 en Barranquilla hasta 0.59 en Cartagena). La correlación entre el conteo de trámites de licencia y unidades construidas a nivel nacional anual es prácticamente nula, lo cual confirma que la métrica relevante es unidades autorizadas, no conteo de trámites.

## Estructura del repositorio

```
├── README.md
├── sql/
│   ├── 01_schema.sql          -- Creación del esquema y tablas
│   ├── 02_vistas.sql          -- Vistas analíticas
│   └── 03_consultas_analisis.sql  -- Consultas exploratorias y hallazgos
├── python/
│   └── limpieza_datos.py      -- Limpieza de CSV crudos del DANE
└── data/
    ├── municipio.csv
    ├── construccion_vivienda.csv
    ├── licencia_construccion.csv
    ├── rango_precio.csv
    └── indice_precio_vivienda.csv
```
