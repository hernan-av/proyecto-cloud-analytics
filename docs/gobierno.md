# Gobierno de datos (preliminar)

Controles, metadatos, linaje, responsables y acceso del pipeline de la segunda entrega. Lo que se implementó está en el [notebook](../notebooks/03_pipeline.ipynb); lo que es regla de operación (y no aplica en Colab) se indica.

## 1. Responsables

Supuesto para un entorno real: cada tabla tiene un dueño de negocio (decide qué significa el dato y si una corrección es válida) y un responsable técnico (mantiene el proceso). En el proyecto, el responsable técnico de todo el pipeline es el equipo.

| Datos | Dueño de negocio | Responsable técnico |
|---|---|---|
| Eventos de uso, facturación y marts de costos | FinOps | Equipo de datos |
| Tickets de soporte | Soporte | Equipo de datos |
| Tokens de GenAI y carbono | Producto | Equipo de datos |
| Clientes, usuarios y recursos | Ventas / Operaciones | Equipo de datos |
| Cuarentena | Dueño de la tabla de origen (decide qué se corrige) | Equipo de datos (la revisa y la informa) |

## 2. Controles

| Control | Dónde | Qué pasa si falla |
|---|---|---|
| Esquema explícito y `_corrupt_record` | Bronze | La fila sigue en Bronze; en Silver va a cuarentena (FMT-01) |
| Claves únicas en maestros y `event_id` único en eventos | Bronze | El notebook se detiene (`assert`) |
| Completitud Landing → Bronze | Bronze | Los eventos que el watermark descartó van a cuarentena (WM-01); si falta alguno, se detiene |
| Reglas de calidad del diccionario (diez reglas) | Silver | Marca (`flag_…`) o cuarentena con `regla` y `motivo` |
| Sin pérdidas Bronze → Silver | Silver | Se detiene |
| Grano, totales y MapReduce de referencia | Gold | Se detiene y no se carga Cassandra |
| Filas en Cassandra = filas en Gold | Serving | Se detiene |
| Reejecución sin duplicados | Pruebas | Se detiene |

Las reglas de calidad están en el [diccionario de datos](diccionario_datos.md#5-reglas-de-calidad) y en la sección 4 del notebook.

## 3. Metadatos

| Columna o archivo | Zona | Para qué sirve |
|---|---|---|
| `registro_llegadas_landing.csv` | Landing | Qué archivo llegó, cuándo y de qué tamaño |
| `fecha_carga` | Bronze (maestros) | De qué carga de Landing salió cada fila |
| `ingest_ts`, `source_file` | Bronze y Silver | Cuándo se cargó y de qué archivo vino |
| `value_raw`, `unit_raw` | Bronze / Silver y cuarentena | El valor original antes de convertir o completar |
| `silver_ts`, `flag_…` | Silver | Cuándo se procesó y qué reglas marcaron el registro |
| `regla`, `motivo`, `quarantine_ts` | Cuarentena | Por qué y cuándo se separó |
| `gold_ts`, `events`, `anomaly_events` | Gold | Cuándo se calculó y cuántos eventos (y anomalías) hay detrás de cada fila |
| `registro_ejecucion.csv` | Todas | Por etapa: filas leídas, escritas, marcadas, en cuarentena, tamaño y ruta |
| `_checkpoints/` | Streaming | Qué archivos procesó cada consulta de streaming |

## 4. Linaje

Un número de Cassandra se puede seguir hasta el archivo original:

```
Cassandra  org_daily_usage_by_service (org_id, usage_date, service)
   ↑ misma clave
Gold       org_daily_usage_by_service · gold_ts, events
   ↑ suma de los eventos con ese org_id, event_date y service
Silver     usage_events · event_id, source_file, ingest_ts, silver_ts
   ↑ mismo event_id
Bronze     usage_events · source_file (archivo de Landing), ingest_ts
   ↑ source_file
Landing    usage_events_stream/<archivo>.jsonl · registro de llegadas
```

Los eventos que no llegaron a Gold están en la cuarentena con su `event_id`, su archivo de origen y el motivo.

## 5. Acceso y seguridad

- **Credenciales:** el token de AstraDB va en los Secretos de Colab y el Secure Connect Bundle se sube en cada sesión. Ninguno está en el código ni en el repositorio.
- **Datos personales:** los emails de `users` y los recursos con la etiqueta `pii:true` (columna `has_pii` en Silver). En esta entrega no llegan a Gold ni a Cassandra. Anonimizarlos queda en el backlog.
- **Acceso por área (entorno real):** cada área consulta solo sus tablas de Cassandra (FinOps, Soporte, Producto). El lake completo, solo el equipo de datos.
- **Ley 25.326:** los datos personales se eliminan o anonimizan al cumplirse el plazo legal o a pedido del titular (D06).

## 6. Retención

Definida en D06: nada se elimina por antigüedad; Landing y Bronze 12 meses en acceso rápido, Silver 24, Gold todo el historial y la cuarentena 90 días en revisión. Es una regla de operación: en Colab el lake se regenera en cada corrida.
