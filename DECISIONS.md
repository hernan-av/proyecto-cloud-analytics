# Decisiones

Registro de las decisiones del proyecto. Cada una tiene estado, contexto, decisión y consecuencias (formato de registros de decisiones de Michael Nygard). Las de la primera entrega tienen el detalle en el [documento de diseño](docs/documento_diseno_v1.md); las de la segunda entrega están explicadas en el paso del [notebook](notebooks/03_pipeline.ipynb) donde se aplican. Si una decisión cambia, no se borra: se marca como reemplazada y se agrega la nueva.

---

## D01 · Patrón Lambda

- **Estado:** aceptada
- **Contexto:** los eventos de uso llegan todo el tiempo y FinOps necesita ver anomalías de costo en minutos. Maestros y facturación llegan por lotes.
- **Decisión:** camino batch para maestros, facturación y tickets; camino streaming para los eventos. Se unen en Silver.
- **Consecuencias:** hay dos caminos para construir y mantener, y el gasto del día puede no coincidir entre ambos (vale el del proceso nocturno). Descartados: batch, Kappa e híbrido. Diseño, sección 5.
- **Implementación (2da entrega):** eventos en streaming de Landing a Bronze y de Bronze a Silver; maestros en batch; Gold diario en batch leyendo Silver. Notebook, secciones 3 a 5.

## D02 · Streaming hasta Gold solo para anomalías de costo

- **Estado:** aceptada
- **Contexto:** las consultas P1 a P5 piden datos por día o por mes.
- **Decisión:** `cost_anomaly_mart` se actualiza cada pocos minutos. Las otras cuatro tablas de Gold se calculan en un proceso nocturno y quedan disponibles antes de las 6:00.
- **Consecuencias:** el streaming tiene un consumidor concreto (monitoreo de FinOps). Extenderlo a P1 y P2 queda abierto (D12). Diseño, secciones 1.4 y 8.
- **Implementación (2da entrega):** `org_daily_usage_by_service` se construye en batch. `cost_anomaly_mart` queda para la entrega final (backlog).

## D03 · Ingesta diaria de la facturación

- **Estado:** aceptada
- **Contexto:** con muchos clientes, cada día cierra algún ciclo de facturación.
- **Decisión:** la facturación llega todos los días con las facturas de los ciclos cerrados. Se particiona por mes.
- **Consecuencias:** supuesto: en la muestra todos cierran a fin de mes calendario. Si hay ciclos distintos, cambia el grano de revenue (D14).

## D04 · Data Lake en cuatro zonas, Parquet desde Bronze

- **Estado:** aceptada
- **Contexto:** la consigna pide Landing, Bronze, Silver y Gold.
- **Decisión:** Landing guarda los originales sin tocar; desde Bronze todo en Parquet. Cada zona tiene su regla para pasar a la siguiente.
- **Consecuencias:** se puede reprocesar desde Landing ante cualquier error. Diseño, sección 7.

## D05 · Partición por fecha solo en tablas de hechos

- **Estado:** aceptada
- **Contexto:** particionar tablas chicas genera muchos archivos pequeños.
- **Decisión:** eventos por día, tickets y marketing por fecha, facturación y NPS por mes. Clientes, usuarios y recursos sin partición.
- **Consecuencias:** el criterio se pensó para el volumen de producción, no para la muestra. Diseño, sección 7.3.
- **Implementación (2da entrega):** `usage_events` (Bronze y Silver) por `event_date`, `billing_monthly` por `billing_month`, Gold por `usage_date`. Maestros sin partición.

## D06 · Retención

- **Estado:** aceptada
- **Contexto:** las áreas necesitan información histórica y Landing es la única copia original.
- **Decisión:** nada se elimina por antigüedad. Landing y Bronze quedan 12 meses en acceso rápido y Silver 24; después pasan a almacenamiento de archivo. Gold conserva todo el historial. La cuarentena se revisa durante 90 días y después se archiva con su motivo.
- **Consecuencias:** el histórico siempre está disponible, aunque lo archivado es más lento de consultar. Excepción: los datos personales se eliminan o anonimizan al cumplirse el plazo legal o a pedido del titular. Diseño, sección 7.5.
- **Implementación (2da entrega):** es una regla de operación; no aplica en Colab, donde el lake se regenera en cada corrida.

## D07 · Nada se borra: se marca o va a cuarentena

- **Estado:** aceptada
- **Contexto:** la exploración encontró errores en casi todas las fuentes.
- **Decisión:** los registros con problemas se marcan y siguen; solo van a cuarentena los que no se pueden usar (por ejemplo, eventos sin `value` ni `unit`).
- **Consecuencias:** las áreas saben cuántos datos tenían problemas. Reglas en el diccionario, sección 5.
- **Implementación (2da entrega):** columnas `flag_…` en Silver y carpeta `silver/quarantine/` con `regla`, `motivo` y `quarantine_ts`. Solo se corrige lo que tiene una corrección segura (la unidad que falta, EV-03).

## D08 · Fechas fuera de orden entre tablas: marcar, no descartar

- **Estado:** aceptada
- **Contexto:** hay inconsistencias en casi todos los cruces con el alta del cliente y la creación de recursos (hasta 31 % de los casos).
- **Decisión:** se marcan en Silver y no se usan para descartar registros.
- **Consecuencias:** los análisis por fecha deben tener en cuenta la marca. Diccionario, sección 4.
- **Implementación (2da entrega):** `flag_before_resource` en los eventos de Silver.

## D09 · Sin SCD

- **Estado:** aceptada
- **Contexto:** los maestros llegan como foto completa, sin historial de cambios.
- **Decisión:** no se guarda historial de cambios de los maestros.
- **Consecuencias:** si un cliente cambia de plan, se ve solo el plan actual.

## D10 · Nombres de tablas en inglés

- **Estado:** aceptada
- **Contexto:** las columnas del dataset y las tablas de referencia de la consigna están en inglés.
- **Decisión:** tablas en inglés con los nombres de la consigna; documentación en castellano.
- **Consecuencias:** no hace falta una tabla de equivalencias.

## D11 · Corte del día de los eventos

- **Estado:** aceptada (antes propuesta)
- **Contexto:** los eventos vienen en hora UTC.
- **Decisión:** el día se corta en UTC. La sesión de Spark trabaja en UTC (`spark.sql.session.timeZone`).
- **Consecuencias:** un evento de las 01:00 UTC es del mismo día aunque en Argentina sean las 22:00 del día anterior. Si el negocio pide hora local, se cambia en un solo lugar.

## D15 · Simular la llegada de los eventos

- **Estado:** aceptada
- **Contexto:** el dataset no informa cuándo llegó cada archivo y los eventos están mezclados al azar entre los 120 archivos: cada archivo trae eventos de todo el período. Si el número del archivo fuera el orden de llegada, el watermark tendría que tolerar 60 días para no perder datos (medido en el notebook, sección 1.2).
- **Decisión:** una sección del notebook, **fuera del pipeline**, hace de sistema de origen: reenvía los eventos a Landing en archivos cada 10 minutos, en el orden en que habrían llegado (la mayoría a los pocos minutos de ocurrir, algunos con horas de atraso y unos pocos con días). Los CSV se copian a `landing/<tabla>/fecha_carga=2025-09-01/`. No se modifica ningún registro y el dataset provisto queda intacto. La regla usa una semilla fija.
- **Consecuencias:** el streaming se comporta como en un entorno real y se pueden mostrar los datos tardíos. En producción esta sección no existe. Notebook, sección 1.

## D16 · Watermark de 1 día

- **Estado:** aceptada
- **Contexto:** el watermark compara la fecha de cada evento con la más nueva que ya vio Spark; lo que queda más atrás que la tolerancia se descarta del stream. También define cuánto tiempo recuerda Spark los `event_id` para deduplicar.
- **Decisión:** tolerancia de 1 día, con deduplicación por `event_id` dentro del watermark (`dropDuplicatesWithinWatermark`). Los eventos que el watermark descarta no se pierden: un control de completitud los detecta y los manda a cuarentena con la regla WM-01.
- **Consecuencias:** entran los atrasos de horas; los de varios días van a cuarentena para revisión. Notebook, secciones 3.6 a 3.8.

## D17 · Umbrales de anomalía de costo

- **Estado:** aceptada
- **Contexto:** el costo normal depende mucho del servicio y de la métrica (un evento de `requests` de `genai` cuesta unos 14 USD; uno de `cpu_hours` de `networking`, 0,02). Un umbral único no sirve.
- **Decisión:** un evento es anomalía de costo (regla EV-05) si cuesta menos de −0,01 USD o si supera **2 veces el percentil 99** de su servicio y métrica. Los umbrales se calculan con el histórico de Bronze y se guardan en `silver/ref_cost_thresholds`.
- **Consecuencias:** por encima de 1,5 veces el p99 casi no cambia la cantidad de eventos marcados: los picos forman un grupo aparte, de 10 a 20 veces el costo normal. En producción los umbrales se recalcularían cada tanto (por ejemplo, una vez por mes). Notebook, sección 4.3.

## D18 · Las anomalías se suman al costo diario

- **Estado:** aceptada
- **Contexto:** hay que decidir si el costo diario de Gold incluye los eventos marcados como anomalía.
- **Decisión:** se incluyen en `daily_cost_usd`, porque el costo existió. Al lado se informa `anomaly_events` y `anomaly_cost_usd` para poder separarlos.
- **Consecuencias:** FinOps ve el gasto completo y sabe qué parte es anómala. Notebook, sección 5.

## D19 · Claves de Cassandra

- **Estado:** aceptada
- **Contexto:** modelo query-first: una tabla por consulta y cada consulta tiene que leer una sola partición (clase 14).
- **Decisión:** dos tablas, ambas con `org_id` como clave de partición:
  - `org_daily_usage_by_service` (P1): clustering `usage_date DESC, service`.
  - `org_top_services_14d` (P2): clustering `rank`. El ranking lo calcula Spark, porque Cassandra no agrupa ni ordena por una suma.
- **Consecuencias:** un cliente suma unas 2.200 filas por año en P1: particiones chicas y parejas. Si crece mucho, se agrega el mes a la clave de partición. La carga es un upsert: recargar no duplica. Notebook, sección 6; CQL en [`cql/serving.cql`](cql/serving.cql).

---

## Abiertas

## D12 · Streaming para P1 y P2

- **Estado:** propuesta
- **Opciones:** mantener la actualización nocturna o actualizar `org_daily_usage_by_service` cada pocos minutos si el negocio lo pide.

## D13 · Facturas con subtotal negativo

- **Estado:** propuesta
- **Opciones:** solo marcarlas, o corregir el signo y marcarlas. Se resuelve al implementar Silver de facturación (final).

## D14 · Moneda y ciclos de facturación

- **Estado:** propuesta, pendiente de respuesta del docente
- **Opciones:** montos en la moneda indicada o ya en USD. Si aparecen ciclos distintos, asignar cada factura al mes de cierre.
