# Backlog

Trabajo pendiente para el MVP de la entrega final (09/12/2026), después de la segunda entrega. Está ordenado por prioridad dentro de cada categoría.

## Obligatorio

Lo que pide la consigna para la entrega final (secciones 7.2 a 7.4) y todavía no está hecho.

| # | Tarea | Por qué |
|---|---|---|
| 1 | `cost_anomaly_mart` en streaming (con su checkpoint) y carga continua en Cassandra | Es el consumidor que justifica el camino streaming (D02) y uno de los marts de referencia (7.3) |
| 2 | Bronze y Silver de `support_tickets` con las reglas TK-01 a TK-03 | P3 (tickets críticos y SLA) |
| 3 | Silver de `billing_monthly` con las reglas BI-01 a BI-03 y resolver D13 y D14 | P4 (revenue mensual en USD) |
| 4 | Gold y Cassandra de `tickets_by_org_date`, `revenue_by_org_month` y `genai_tokens_by_org_date` | P3, P4 y P5 desde Cassandra (7.4) |
| 5 | Bronze y Silver de `users`, `marketing_touches` y `nps_surveys` | Completar el lake con todas las fuentes (7.2, punto 3) |
| 6 | Componente analítico final (ver [`docs/analitica_ml.md`](docs/analitica_ml.md)) | 7.2, punto 6 |
| 7 | Diagrama final y documentación técnica actualizados | La arquitectura tiene que coincidir con lo implementado |
| 8 | Presentación ejecutiva, video y defensa | Artefactos finales (7.5) |

## Deseable

Mejoras que suman pero no ponen en riesgo el MVP.

| # | Tarea | Por qué |
|---|---|---|
| 1 | Compactar los archivos chicos de Bronze y Silver | El streaming escribe un archivo por día y por micro-batch |
| 2 | Aviso automático si el atraso del monitoreo supera 10 minutos | Criterio de éxito del diseño (1.4) |
| 3 | Anonimizar los emails de `users` y marcar en Gold lo que viene de recursos con `pii:true` | Gobierno y Ley 25.326 |
| 4 | Recalcular los umbrales de anomalía en forma periódica | D17 |
| 5 | Agregar el mes a la clave de partición de Cassandra (bucket) | Por si las particiones crecen mucho (D19) |
| 6 | Comparar el costo del camino streaming con el del batch nocturno al cierre del día | Riesgo "los dos caminos dan números distintos" (diseño 10.2) |

## Fuera de alcance

Lo que no se va a hacer en el proyecto, con el motivo.

| Tarea | Motivo |
|---|---|
| Cluster real con almacenamiento distribuido y replicación (HDFS o nube) | El proyecto corre en Colab, en una sola máquina. El diseño ya está pensado para un cluster |
| Orquestador o programador de tareas (cron, Airflow) | El proceso nocturno se lanza a mano corriendo el notebook (diseño 11.3) |
| Kafka u otra cola de mensajes | La fuente de eventos son archivos; el streaming de archivos alcanza para el caso |
| Historial de cambios de los maestros (SCD) | D09 |
| Tipos de cambio reales de una fuente externa | Se usa la tasa que trae la factura (D14) |
