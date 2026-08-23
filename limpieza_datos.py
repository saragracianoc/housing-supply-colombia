"""
Limpieza y preparación de datos crudos del DANE para el proyecto de vivienda.

Este script toma los CSV generados desde Excel (después de reestructurar
manualmente los archivos originales del DANE) y los deja listos para
importar a MySQL Workbench.

Problemas que resuelve:
- Encoding UTF-8 con BOM (ï»¿ en la primera columna)
- Formato numérico colombiano (punto como separador de miles, coma como decimal)
- Codificación latin-1 en archivos del DANE
- Preservación de códigos de municipio con ceros iniciales (051, 081)
"""

import pandas as pd
import os

# ── Rutas de entrada y salida ────────────────────────────────────────────────
INPUT_DIR = "data/raw/"
OUTPUT_DIR = "data/clean/"
os.makedirs(OUTPUT_DIR, exist_ok=True)


def limpiar_formato_colombiano(series):
    """
    Convierte formato numérico colombiano a float.
    '12.091,50' → 12091.50
    """
    return (
        series
        .astype(str)
        .str.replace('.', '', regex=False)   # quitar punto de miles
        .str.replace(',', '.', regex=False)  # coma decimal → punto decimal
        .astype(float)
    )


# =============================================================================
# 1. MUNICIPIO
# =============================================================================
def limpiar_municipio():
    df = pd.read_csv(
        f"{INPUT_DIR}Municipio.csv",
        sep=';',
        encoding='utf-8-sig',        # elimina BOM si existe
        dtype={'cod_muni': str}
    )
    # Asegurar que cod_muni tenga 3 dígitos con cero inicial
    df['cod_muni'] = df['cod_muni'].str.zfill(3)

    df.to_csv(f"{OUTPUT_DIR}municipio.csv", index=False, encoding='utf-8')
    print(f"municipio: {len(df)} registros")
    return df


# =============================================================================
# 2. LICENCIA DE CONSTRUCCIÓN
# =============================================================================
def limpiar_licencias():
    df = pd.read_csv(
        f"{INPUT_DIR}Licencia_construccion.csv",
        sep=';',
        encoding='latin-1'
    )

    # Filtrar solo destino = vivienda (destino == 1)
    df = df[df['destino'] == 1].copy()
    df = df.drop(columns=['destino'])

    # Decodificar columnas categóricas
    df['clase_suelo'] = df['clase_suelo'].map({
        1: 'urbana',
        2: 'suburbana',
        3: 'rural'
    }).fillna('sin_clasificar')

    df['tipo_vivienda'] = df['tipo_vivienda'].map({
        1: 'casas',
        2: 'apartamentos'
    }).fillna('sin_tipo')

    df['subsidio_licencia'] = df['subsidio_licencia'].map({
        1: 'VIS',
        2: 'No_VIS',
        3: 'VIP'
    }).fillna('sin_subsidio')

    # Preservar cod_municipio como texto de 3 dígitos
    df['cod_municipio'] = df['cod_municipio'].astype(str).str.zfill(3)

    df.to_csv(f"{OUTPUT_DIR}licencia_construccion.csv", index=False, encoding='utf-8')
    print(f"licencia_construccion: {len(df)} registros")
    return df


# =============================================================================
# 3. CONSTRUCCIÓN DE VIVIENDA
# =============================================================================
def limpiar_construccion():
    """
    Nota: este CSV se genera a partir de un Excel del DANE que originalmente
    tiene columnas separadas para VIS, No VIS y VIP. La transformación
    wide-to-long (unpivot) se hizo manualmente en Excel antes de este paso,
    convirtiendo esas columnas en un atributo 'Subsidio_construccion' con
    valores VIS, No_VIS, VIP y las unidades correspondientes.
    """
    df = pd.read_csv(
        f"{INPUT_DIR}construccion_vivienda.csv",
        encoding='utf-8-sig',
        dtype={'cod_muni': str}
    )

    # Limpiar columnas numéricas si vienen en formato colombiano
    if df['area_m2_constr'].dtype == object:
        df['area_m2_constr'] = limpiar_formato_colombiano(df['area_m2_constr'])

    if df['Unidades_vivienda'].dtype == object:
        df['Unidades_vivienda'] = (
            df['Unidades_vivienda']
            .astype(str)
            .str.replace('.', '', regex=False)
            .astype(int)
        )

    df['cod_muni'] = df['cod_muni'].str.zfill(3)

    df.to_csv(f"{OUTPUT_DIR}construccion_vivienda.csv", index=False, encoding='utf-8')
    print(f"construccion_vivienda: {len(df)} registros")
    return df


# =============================================================================
# 4. RANGO DE PRECIO
# =============================================================================
def limpiar_rango_precio():
    df = pd.read_csv(
        f"{INPUT_DIR}Rango_precio.csv",
        sep=';',
        encoding='utf-8-sig',
        dtype={'cod_muni': str}
    )

    df['area_m2_rango'] = limpiar_formato_colombiano(df['area_m2_rango'])

    df['Unidades_por_rango'] = (
        df['Unidades_por_rango']
        .astype(str)
        .str.replace('.', '', regex=False)
        .str.replace(',', '.', regex=False)
        .astype(float)
        .astype(int)
    )

    df['cod_muni'] = df['cod_muni'].str.zfill(3)

    df.to_csv(f"{OUTPUT_DIR}rango_precio.csv", index=False, encoding='utf-8')
    print(f"rango_precio: {len(df)} registros")
    return df


# =============================================================================
# 5. ÍNDICE DE PRECIO DE VIVIENDA (IPVN)
# =============================================================================
def limpiar_ipvn():
    df = pd.read_csv(
        f"{INPUT_DIR}Indice_precio_vivienda.csv",
        encoding='latin-1'
    )

    # Corregir nombres de municipio con encoding roto
    df['municipio'] = df['municipio'].replace({
        'MedellÃ\xadn': 'Medellin',
        'BogotÃ¡': 'Bogota',
    })

    df['cod_muni'] = df['cod_muni'].astype(str).str.zfill(3)

    df.to_csv(f"{OUTPUT_DIR}indice_precio_vivienda.csv", index=False, encoding='utf-8')
    print(f"indice_precio_vivienda: {len(df)} registros")
    return df


# =============================================================================
# EJECUCIÓN
# =============================================================================
if __name__ == '__main__':
    print("Limpieza de datos - Proyecto Vivienda Colombia 2019-2023")
    print("=" * 60)
    limpiar_municipio()
    limpiar_licencias()
    limpiar_construccion()
    limpiar_rango_precio()
    limpiar_ipvn()
    print("=" * 60)
    print("Archivos listos en:", OUTPUT_DIR)
