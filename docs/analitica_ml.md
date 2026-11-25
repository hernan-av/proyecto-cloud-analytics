# Analítica o Machine Learning

## Qué pregunta analítica tiene el caso

La necesidad analítica más clara del caso es la de FinOps: **detectar costos anómalos** (diseño, sección 1.3). Es lo que justifica el camino streaming y una de las tablas de referencia de la consigna (`cost_anomaly_mart`).

## Qué se implementó en esta entrega

Una capacidad analítica basada en reglas, no un modelo de ML (notebook, sección 4.3, y decisión D17):

- Se calcula el percentil 99 del costo de cada combinación de servicio y métrica con el histórico de Bronze.
- Un evento es anomalía si cuesta más de 2 veces ese percentil o si su costo es menor a −0,01 USD.
- Cada evento de Silver lleva `is_cost_anomaly`, y Gold informa por día cuántas anomalías hubo y cuánto suman.

**Resultado:** los picos forman un grupo bien separado del resto. Entre 1,5 y 3 veces el p99, la cantidad de eventos marcados casi no cambia (de 151 a 138). Son eventos que cuestan entre 10 y 20 veces lo normal de su grupo.

## Por qué no un modelo de ML ahora

La Planificación dice que no hay que forzar ML cuando una regla responde mejor al problema. En la muestra:

- No hay una etiqueta que diga qué evento es realmente una anomalía, así que no se puede entrenar un modelo supervisado ni medir su precisión.
- Las anomalías están muy separadas del comportamiento normal: un umbral por servicio y métrica las encuentra sin ambigüedad.
- El tema de ML con Spark recién empezó en la clase 15.

## Qué aportaría un modelo

La regla compara cada evento con el percentil 99 de su servicio y métrica **para todos los clientes juntos**. Un modelo de detección de anomalías no predice un resultado: aprende qué es lo normal y marca lo que se aparta, sin que nadie le diga de antemano qué es anómalo. Lo que agregaría es el **contexto de cada cliente**.

Ejemplo: un cliente que siempre gasta 2 USD por día en `compute` y un día gasta 25 no supera el umbral global de `compute / requests` (28,7 USD), así que la regla no lo marca. Para ese cliente, sin embargo, es 12 veces lo habitual.

Dos formas de hacerlo:
- **Pronóstico:** predecir cuánto debería gastar cada cliente por día según su historia; si el gasto real se aleja mucho del pronóstico, es anomalía.
- **Agrupamiento (clustering):** agrupar clientes o días con comportamiento parecido; lo que no encaja en ningún grupo es lo raro.

Con 80 clientes y 60 días se puede probar, pero no es seguro que encuentre más que la regla.

## Plan de cierre (entrega final)

1. **`cost_anomaly_mart` en streaming:** aplicar la misma regla a medida que llegan los eventos y cargar en Cassandra. Medir el atraso entre `ingest_ts` y la actualización de la fila (meta: 10 minutos o menos).
2. **Métricas de la regla:** cuántas anomalías por día, por servicio y por cliente, y qué parte del costo total representan.
3. **Comparación con un modelo, si aporta:** con lo que se vea de Spark ML, probar uno de los dos enfoques de arriba sobre el costo diario por cliente y servicio y compararlo con la regla. Se adopta solo si encuentra casos que la regla no detecta; si no, se documenta por qué alcanza con la regla.

**Pendiente con el docente:** confirmar si la detección por umbral se acepta como capacidad analítica equivalente o si para el final se espera un modelo (consulta enviada con la segunda entrega).
