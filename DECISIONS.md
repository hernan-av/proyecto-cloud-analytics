# Decisiones

Registro de las decisiones del proyecto. Cada una tiene estado, contexto, decisión y consecuencias (formato de registros de decisiones de Michael Nygard). El detalle de cada una está en el [documento de diseño](docs/documento_diseno_v1.md). Si una decisión cambia, no se borra: se marca como reemplazada y se agrega la nueva.

---

## D01 · Patrón Lambda

- **Estado:** aceptada
- **Contexto:** los eventos de uso llegan todo el tiempo y FinOps necesita ver anomalías de costo en minutos. Maestros y facturación llegan por lotes.
- **Decisión:** camino batch para maestros, facturación y tickets; camino streaming para los eventos. Se unen en Silver.
- **Consecuencias:** hay dos caminos para construir y mantener, y el gasto del día puede no coincidir entre ambos (vale el del proceso nocturno). Descartados: batch, Kappa e híbrido. Diseño, sección 5.

## D02 · Streaming hasta Gold solo para anomalías de costo

- **Estado:** aceptada
- **Contexto:** las consultas P1 a P5 piden datos por día o por mes.
- **Decisión:** `cost_anomaly_mart` se actualiza cada pocos minutos. Las otras cuatro tablas de Gold se calculan en un proceso nocturno y quedan disponibles antes de las 6:00.
- **Consecuencias:** el streaming tiene un consumidor concreto (monitoreo de FinOps). Extenderlo a P1 y P2 queda abierto (D12). Diseño, secciones 1.4 y 8.

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

## D06 · Retención

- **Estado:** aceptada
- **Contexto:** las áreas necesitan información histórica y Landing es la única copia original.
- **Decisión:** nada se elimina por antigüedad. Landing y Bronze quedan 12 meses en acceso rápido y Silver 24; después pasan a almacenamiento de archivo. Gold conserva todo el historial. La cuarentena se revisa durante 90 días y después se archiva con su motivo.
- **Consecuencias:** el histórico siempre está disponible, aunque lo archivado es más lento de consultar. Excepción: los datos personales se eliminan o anonimizan al cumplirse el plazo legal o a pedido del titular. Diseño, sección 7.5.

## D07 · Nada se borra: se marca o va a cuarentena

- **Estado:** aceptada
- **Contexto:** la exploración encontró errores en casi todas las fuentes.
- **Decisión:** los registros con problemas se marcan y siguen; solo van a cuarentena los que no se pueden usar (por ejemplo, eventos sin `value` ni `unit`).
- **Consecuencias:** las áreas saben cuántos datos tenían problemas. Reglas en el diccionario, sección 5.

## D08 · Fechas fuera de orden entre tablas: marcar, no descartar

- **Estado:** aceptada
- **Contexto:** hay inconsistencias en casi todos los cruces con el alta del cliente y la creación de recursos (hasta 31 % de los casos).
- **Decisión:** se marcan en Silver y no se usan para descartar registros.
- **Consecuencias:** los análisis por fecha deben tener en cuenta la marca. Diccionario, sección 4.

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

---

## Abiertas

## D11 · Corte del día de los eventos

- **Estado:** propuesta
- **Contexto:** los eventos vienen en hora UTC.
- **Opciones:** cortar el día en UTC o convertir a hora de Argentina.

## D12 · Streaming para P1 y P2

- **Estado:** propuesta
- **Opciones:** mantener la actualización nocturna o actualizar `org_daily_usage_by_service` cada pocos minutos si el negocio lo pide.

## D13 · Facturas con subtotal negativo

- **Estado:** propuesta
- **Opciones:** solo marcarlas, o corregir el signo y marcarlas.

## D14 · Moneda y ciclos de facturación

- **Estado:** propuesta, pendiente de respuesta del docente
- **Opciones:** montos en la moneda indicada o ya en USD. Si aparecen ciclos distintos, asignar cada factura al mes de cierre.
