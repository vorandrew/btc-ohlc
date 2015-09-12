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

CREATE TABLE ohlc_bitstamp (
  date TIMESTAMP WITHOUT TIME ZONE,
  open DECIMAL(12,2),
  high DECIMAL(12,2),
  low DECIMAL(12,2),
  close DECIMAL(12,2),
  volume INTEGER
);

CREATE INDEX ON ohlc_bitstamp (date);

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
  date_trunc('hour', dt) + INTERVAL '1 minute' * floor( EXTRACT( MINUTE from dt) / 30 ) * 30,
  first_value(price) OVER w,
  MAX(price) OVER w,
  MIN(price) OVER w,
  last_value(price) OVER w,
  SUM(volume) OVER w
FROM
  (SELECT * FROM time_bitstamp ORDER BY dt) as t
WINDOW w AS (
  PARTITION BY
    date_trunc('hour', dt) + INTERVAL '1 minute' * floor( EXTRACT( MINUTE from dt) / 30 ) * 30
  ORDER BY
    date_trunc('hour', dt) + INTERVAL '1 minute' * floor( EXTRACT( MINUTE from dt) / 30 ) * 30
)
ORDER BY date_trunc('hour', dt) + INTERVAL '1 minute' * floor( EXTRACT( MINUTE from dt) / 30 ) * 30;

COPY (
    SELECT
        date "Date",
        open "Open",
        high "High",
        low "Low",
        close "Close",
        volume "Volume"
    FROM
        ohlc_bitstamp
) TO '/tmp/BTCUSD.csv' WITH CSV;