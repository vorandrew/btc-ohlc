DROP TABLE IF EXISTS raw_bitstamp;
DROP TABLE IF EXISTS time_bitstamp;
DROP TABLE IF EXISTS ohlc_bitstamp;

CREATE TABLE raw_bitstamp (
  epoch INTEGER,
  price DECIMAL(12,2),
  volume DECIMAL(24,3)
);

CREATE TABLE time_bitstamp (
  dt TIMESTAMP WITHOUT TIME ZONE,
  price DECIMAL(12,2),
  volume DECIMAL(24,3)
);

CREATE INDEX ON time_bitstamp (dt);

CREATE TABLE IF NOT EXISTS ohlc_bitstamp (
  dt TIMESTAMP WITHOUT TIME ZONE,
  open DECIMAL(12,2),
  high DECIMAL(12,2),
  low DECIMAL(12,2),
  close DECIMAL(12,2),
  volume DECIMAL(24,3)
);

TRUNCATE raw_bitstamp;

COPY raw_bitstamp FROM '/tmp/bitstampUSD.csv' DELIMITER ',' CSV;

TRUNCATE time_bitstamp;

INSERT INTO time_bitstamp
SELECT
  date_trunc('minute', to_timestamp(epoch)) "dt",
  price,
  volume
FROM
  raw_bitstamp;

TRUNCATE ohlc_bitstamp;

INSERT INTO ohlc_bitstamp
SELECT
  DISTINCT
  date_trunc('hour', dt) + INTERVAL '1 minute' * floor( EXTRACT( MINUTE from dt) / 30 ) * 30 as "dt",
  first_value(price) OVER w "open",
  MAX(price) OVER w "high",
  MIN(price) OVER w "low",
  last_value(price) OVER w "close",
  SUM(volume) OVER w "volume"
FROM
  time_bitstamp
WINDOW w AS (
  PARTITION BY date_trunc('hour', dt) + INTERVAL '1 minute' * floor( EXTRACT( MINUTE from dt) / 30 ) * 30 ORDER BY dt
);

COPY (SELECT * FROM ohlc_bitstamp) TO '/tmp/BITSTAMP_BTCUSD.csv' WITH CSV;