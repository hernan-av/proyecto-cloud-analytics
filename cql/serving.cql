-- Cloud Provider Analytics · Serving en Cassandra (AstraDB)
-- Keyspace: cloud_analytics (en AstraDB se crea desde el portal, no con CQL)
-- Modelo query-first: una tabla por consulta; cada consulta lee una sola partición (org_id).

-- Las tablas se nombran completas (keyspace.tabla), como recomienda Astra.

-- P1. Costos y requests diarios por organización y servicio en un rango de fechas
-- Partición: org_id · Clustering: usage_date DESC, service
CREATE TABLE IF NOT EXISTS cloud_analytics.org_daily_usage_by_service (
    org_id            text,
    usage_date        date,
    service           text,
    org_name          text,
    daily_cost_usd    double,
    requests          double,
    cpu_hours         double,
    storage_gb_hours  double,
    genai_tokens      bigint,
    carbon_kg         double,
    events            int,
    anomaly_events    int,
    anomaly_cost_usd  double,
    PRIMARY KEY ((org_id), usage_date, service)
) WITH CLUSTERING ORDER BY (usage_date DESC, service ASC);

-- P2. Top-N servicios por costo acumulado en los últimos 14 días para una organización
-- El ranking se calcula en Spark (Cassandra no agrega ni ordena por una suma).
-- Partición: org_id · Clustering: rank
CREATE TABLE IF NOT EXISTS cloud_analytics.org_top_services_14d (
    org_id        text,
    rank          int,
    service       text,
    cost_usd_14d  double,
    requests_14d  double,
    window_start  date,
    window_end    date,
    PRIMARY KEY ((org_id), rank)
) WITH CLUSTERING ORDER BY (rank ASC);

-- Consulta P1 (ejemplo)
SELECT usage_date, service, daily_cost_usd, requests, anomaly_events
FROM cloud_analytics.org_daily_usage_by_service
WHERE org_id = 'org_53lc58dr' AND usage_date >= '2025-08-01' AND usage_date <= '2025-08-03';

-- Consulta P2 (ejemplo, top 5)
SELECT rank, service, cost_usd_14d, requests_14d, window_start, window_end
FROM cloud_analytics.org_top_services_14d
WHERE org_id = 'org_53lc58dr' LIMIT 5;
