# Cloud Provider Analytics

Proyecto integrador de Minería de Datos II · ISTEA · 2C 2026

**Integrantes:** Alberto Hernán Avalos y Pedro Alves

Diseño de un pipeline de datos para un proveedor de nube. Recibe los datos de clientes, uso, facturación, soporte, marketing y encuestas, los limpia y los deja listos para tres áreas: FinOps, Soporte y Producto. Usa una arquitectura Lambda (batch para maestros y facturación, streaming para los eventos de uso), un Data Lake por zonas (Landing, Bronze, Silver y Gold) procesado con Spark, y Cassandra (AstraDB) para las consultas.

**Estado:** primera entrega. Incluye el diseño y la exploración de los datos; el pipeline se implementa en la segunda entrega.

---

## Qué revisar y dónde

| | Qué es | Dónde está |
|:-:|---|---|
| 1 | **Documento de diseño**<br>Problema, 5V, arquitectura, patrón, Data Lake, flujos, MapReduce, supuestos, riesgos y esfuerzo | [`docs/documento_diseno_v1.md`](docs/documento_diseno_v1.md) |
| 2 | **Diccionario de datos**<br>Cada fuente con sus campos, problemas encontrados, tratamiento, relaciones (diagrama ER) y consistencia de fechas | [`docs/diccionario_datos.md`](docs/diccionario_datos.md) |
| 3 | **Diagrama de arquitectura completo**<br>Todas las zonas con sus tablas y reglas. También subimos el original editable en draw.io, por si se quiere abrir en [app.diagrams.net](https://app.diagrams.net); la versión de referencia es el PNG | [`docs/diagramas/arquitectura_v1_vertical.png`](docs/diagramas/arquitectura_v1_vertical.png)<br>[`docs/diagramas/arquitectura_v1_vertical.drawio`](docs/diagramas/arquitectura_v1_vertical.drawio) |
| 4 | **Exploración de los datos**<br>Notebooks con los resultados guardados; es la evidencia de la exploración | [`notebooks/`](notebooks/) |
| 5 | **Registro de decisiones**<br>Decisiones tomadas y abiertas | [`DECISIONS.md`](DECISIONS.md) |

---

## Estructura del repositorio

```
proyecto-cloud-analytics/
├── README.md                          este archivo
├── DECISIONS.md                       registro de decisiones
├── datalake/
│   ├── README_dataset.txt             descripción del dataset (profesor)
│   └── landing/                       datos originales del caso
├── docs/
│   ├── documento_diseno_v1.md         documento de diseño
│   ├── diccionario_datos.md           diccionario de datos
│   └── diagramas/
│       ├── arquitectura_v1_vertical.png    diagrama completo
│       ├── arquitectura_v1_vertical.drawio original editable (draw.io)
│       ├── arquitectura_v1_general.png     vista general
│       └── mapreduce_costo_diario.png      ejemplo MapReduce
└── notebooks/
    ├── 01_exploracion_csv.ipynb       exploración de los 7 CSV
    └── 02_exploracion_json.ipynb   exploración de los eventos JSONL
```

## Datos

Dataset sintético provisto por el profesor, en `datalake/landing/`: 7 archivos CSV y la carpeta `usage_events_stream/` con 120 archivos JSONL. Los archivos originales no se modifican.

## Cómo correr los notebooks

Solo hace falta una cuenta de Google.

1. Abrir el notebook en Colab: desde GitHub con el botón "Open in Colab", o en Colab con Archivo → Abrir notebook → GitHub.
2. Entorno de ejecución → Ejecutar todo.

La primera celda clona este repositorio y define las rutas a `datalake/landing/`. Los notebooks están guardados con sus resultados, así que también se pueden leer sin ejecutarlos.

## Uso de IA

Usamos IA como apoyo para entender algunos conceptos que no vimos en clase, consolidar el diccionario de datos con los hallazgos, documentar las decisiones, generar las imágenes de vista general y MapReduce, y corregir la redacción. También para estimar roles, esfuerzo y recursos, porque no teníamos experiencia en dimensionar un proyecto de este tipo. La exploración de los datos, el análisis de los resultados, las decisiones de diseño y el diagrama de arquitectura los hicimos nosotros.

## Convenciones

- Un notebook por integrante y por tema, para no editar el mismo archivo a la vez.
- Nombres de tablas en inglés; documentación en castellano.
