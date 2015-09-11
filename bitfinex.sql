DROP TABLE IF EXISTS raw_bitfinex;
DROP TABLE IF EXISTS time_bitfinex;
DROP TABLE IF EXISTS ohlc_bitfinex;

CREATE TABLE raw_bitfinex (
  epoch INTEGER,
  price DECIMAL(12,2),
  volume DECIMAL(24,3)
);

CREATE TABLE time_bitfinex (
  dt TIMESTAMP WITHOUT TIME ZONE,
  price DECIMAL(12,2),
  volume DECIMAL(24,3)
);

CREATE INDEX ON time_bitfinex (dt);

CREATE TABLE ohlc_bitfinex (
  date TIMESTAMP WITHOUT TIME ZONE,
  open DECIMAL(12,2),
  high DECIMAL(12,2),
  low DECIMAL(12,2),
  close DECIMAL(12,2),
  volume INTEGER
);

CREATE INDEX ON ohlc_bitfinex (date);

TRUNCATE raw_bitfinex;

COPY raw_bitfinex FROM '/tmp/bitfinexUSD.csv' DELIMITER ',' CSV;

TRUNCATE time_bitfinex;

INSERT INTO time_bitfinex
SELECT
  date_trunc('minute', to_timestamp(epoch)) "dt",
  price,
  volume
FROM
  raw_bitfinex
ORDER BY dt;

TRUNCATE ohlc_bitfinex;

INSERT INTO ohlc_bitfinex
SELECT
  DISTINCT
  date_trunc('hour', dt) + INTERVAL '1 minute' * floor( EXTRACT( MINUTE from dt) / 30 ) * 30,
  first_value(price) OVER w,
  MAX(price) OVER w,
  MIN(price) OVER w,
  last_value(price) OVER w,
  SUM(volume) OVER w
FROM
  time_bitfinex
WINDOW w AS (
  PARTITION BY
    date_trunc('hour', dt) + INTERVAL '1 minute' * floor( EXTRACT( MINUTE from dt) / 30 ) * 30
  ORDER BY
    date_trunc('hour', dt) + INTERVAL '1 minute' * floor( EXTRACT( MINUTE from dt) / 30 ) * 30
);

COPY (
    SELECT
        date "Date",
        open "Open",
        high "High",
        low "Low",
        close "Close",
        volume "Volume"
    FROM
        ohlc_bitfinex
) TO '/tmp/BTCUSD.csv' WITH CSV;