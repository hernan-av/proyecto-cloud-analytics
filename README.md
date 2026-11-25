# Cloud Provider Analytics

Proyecto integrador de Minería de Datos II · ISTEA · 2C 2026

**Integrantes:** Alberto Hernán Avalos y Pedro Alves

Pipeline de datos para un proveedor de nube. Recibe los datos de clientes, uso, facturación, soporte, marketing y encuestas, los limpia y los deja listos para tres áreas: FinOps, Soporte y Producto. Usa una arquitectura Lambda (batch para maestros y facturación, streaming para los eventos de uso), un Data Lake por zonas (Landing, Bronze, Silver y Gold) procesado con Spark, y Cassandra (AstraDB) para las consultas.

**Estado:** segunda entrega. El pipeline corre de punta a punta para los eventos de uso: Landing → Bronze → Silver → Gold → Cassandra, con las consultas P1 y P2. Lo que falta para el final está en el [backlog](BACKLOG.md).

---

## Qué revisar y dónde

| | Qué es | Dónde está |
|:-:|---|---|
| 1 | **Pipeline**<br>Notebook con todas las zonas, las reglas de calidad, la cuarentena, Gold, Cassandra, las pruebas de idempotencia y las evidencias. Está guardado con los resultados a la vista | [`notebooks/03_pipeline.ipynb`](notebooks/03_pipeline.ipynb) |
| 2 | **Diagrama de arquitectura v2**<br>Lo implementado y, en gris, lo pendiente para el final. También está el original editable en draw.io | [`docs/diagramas/arquitectura_v2_vertical.png`](docs/diagramas/arquitectura_v2_vertical.png)<br>[`docs/diagramas/arquitectura_v2_vertical.drawio`](docs/diagramas/arquitectura_v2_vertical.drawio) |
| 3 | **Registro de decisiones**<br>Incluye las nuevas: simulación de la llegada (D15), watermark (D16), umbrales de anomalía (D17), anomalías en el costo (D18) y claves de Cassandra (D19) | [`DECISIONS.md`](DECISIONS.md) |
| 4 | **Scripts CQL**<br>Tablas y consultas de Cassandra | [`cql/serving.cql`](cql/serving.cql) |
| 5 | **Evidencias**<br>Registro de ejecución, inventario del lake, muestras de cuarentena, conteos de idempotencia, resultados y capturas de las consultas | [`evidence/`](evidence/) |
| 6 | **Gobierno**<br>Responsables, controles, metadatos, linaje y acceso | [`docs/gobierno.md`](docs/gobierno.md) |
| 7 | **Analítica o ML**<br>Qué se implementó y plan de cierre | [`docs/analitica_ml.md`](docs/analitica_ml.md) |
| 8 | **Backlog**<br>Obligatorio, deseable y fuera de alcance | [`BACKLOG.md`](BACKLOG.md) |
| 9 | **Primera entrega**<br>Documento de diseño, diccionario de datos y exploración | [`docs/`](docs/) y [`notebooks/`](notebooks/) |

---

## Quickstart

### Requisitos

- Una cuenta de Google (para Colab).
- Una base en AstraDB con un keyspace `cloud_analytics`, un token (rol Database Administrator) y su Secure Connect Bundle (`.zip`). Solo hacen falta para la sección 6 (Cassandra); sin ellos el resto del notebook corre igual.

Versiones con las que se probó: Python 3.13, PySpark 4.0.5, cassandra-driver 3.29 o superior (las instala el notebook), Cassandra 4.0 (AstraDB).

### Configuración

1. Abrir [`notebooks/03_pipeline.ipynb`](notebooks/03_pipeline.ipynb) en Colab (Archivo → Abrir notebook → GitHub).
2. Cargar el token: ícono de la llave a la izquierda → Agregar nuevo secreto → nombre `ASTRA_TOKEN`, valor `AstraCS:…` → activar "Acceso del notebook".
3. Tener a mano el Secure Connect Bundle: el notebook lo pide en la sección 6. No se descomprime y **no se sube al repositorio**.

### Ejecución

Entorno de ejecución → **Ejecutar todo**. Tarda unos 5 minutos.

El notebook:
1. Clona este repositorio (los datos provistos están en `datalake/landing/`).
2. Simula la llegada de los archivos a Landing (sección 1, fuera del pipeline; ver D15).
3. Construye Bronze, Silver y Gold en `/content/lake/` (Parquet).
4. Carga Gold en Cassandra y corre las consultas P1 y P2.
5. Prueba la idempotencia y guarda las evidencias en `evidence/`; al final descarga un `evidence.zip`.

### Pruebas

Los controles corren solos en cada ejecución (`assert`): si alguno falla, el notebook se detiene en esa celda con el motivo. La lista completa está en la sección 7.6 del notebook (completitud, sin duplicados, sin pérdidas, totales de Gold, Cassandra = Gold, reejecución sin duplicados).

### Limpieza y reinicio

- **Data Lake:** se borra y se regenera al principio de cada corrida (celda 0.2). Los datos provistos del repositorio no se tocan.
- **Cassandra:** las tablas se crean con `IF NOT EXISTS` y la carga es un upsert, así que volver a correr no duplica. Para empezar de cero: `TRUNCATE cloud_analytics.org_daily_usage_by_service;` y `TRUNCATE cloud_analytics.org_top_services_14d;` en la CQL Console de Astra.

### Problemas comunes

| Error | Causa | Solución |
|---|---|---|
| `SecretNotFoundError: ASTRA_TOKEN` | Falta el secreto en Colab | Cargarlo (paso 2 de Configuración) |
| "Sin conexión a Cassandra; se saltea la sección 6" | Falta el token, el zip o la conexión | Revisar los pasos 2 y 3; el resto del notebook no se afecta |
| `Improper USE command` en la CQL Console | Se usó el nombre de la base en vez del keyspace | `USE cloud_analytics;` o nombrar las tablas como `cloud_analytics.tabla` |
| `FILE_NOT_EXIST` al volver a correr una celda suelta | Una tabla se reescribió y un DataFrame viejo apuntaba a los archivos anteriores | Volver a correr desde la celda que lee esa tabla, o Ejecutar todo |

---

## Estructura del repositorio

```
proyecto-cloud-analytics/
├── README.md                          este archivo
├── DECISIONS.md                       registro de decisiones
├── BACKLOG.md                         trabajo pendiente para el final
├── cql/
│   └── serving.cql                    tablas y consultas de Cassandra
├── datalake/
│   ├── README_dataset.txt             descripción del dataset (profesor)
│   └── landing/                       datos provistos del caso
├── docs/
│   ├── documento_diseno_v1.md         documento de diseño (primera entrega)
│   ├── diccionario_datos.md           diccionario de datos y reglas de calidad
│   ├── gobierno.md                    gobierno de datos (preliminar)
│   ├── analitica_ml.md                analítica o ML y plan de cierre
│   └── diagramas/                     arquitectura v1 y v2, MapReduce
├── evidence/                          evidencias de ejecución
└── notebooks/
    ├── 01_exploracion_csv.ipynb       exploración de los 7 CSV
    ├── 02_exploracion_json.ipynb      exploración de los eventos JSONL
    └── 03_pipeline.ipynb              pipeline de la segunda entrega
```

## Datos

Dataset sintético provisto por el profesor, en `datalake/landing/`: 7 archivos CSV y la carpeta `usage_events_stream/` con 120 archivos JSONL. Los archivos originales no se modifican.

## Uso de IA

Usamos IA como apoyo para entender algunos conceptos que no vimos en clase, consolidar el diccionario de datos con los hallazgos, documentar las decisiones, generar las imágenes de vista general y MapReduce, y corregir la redacción. También para estimar roles, esfuerzo y recursos, porque no teníamos experiencia en dimensionar un proyecto de este tipo. En la segunda entrega, además, para escribir y depurar el código del pipeline a partir de las decisiones de diseño; cada paso lo revisamos y lo corrimos nosotros, y las decisiones las tomamos nosotros. La exploración de los datos, el análisis de los resultados, las decisiones de diseño y los diagramas de arquitectura los hicimos nosotros.

## Convenciones

- Un notebook por integrante y por tema, para no editar el mismo archivo a la vez.
- Nombres de tablas en inglés; documentación en castellano.
- Ningún secreto en el repositorio: el token va en los Secretos de Colab y el Secure Connect Bundle se sube en cada sesión.
