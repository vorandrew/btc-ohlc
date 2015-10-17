DROP TABLE IF EXISTS raw_bitfinex;
DROP TABLE IF EXISTS time_bitfinex;
DROP TABLE IF EXISTS ohlc_bitfinex;

CREATE TABLE raw_bitfinex (
  epoch  INTEGER,
  price  DECIMAL(12, 2),
  volume DECIMAL(24, 3)
);

CREATE TABLE time_bitfinex (
  dt     TIMESTAMP WITHOUT TIME ZONE,
  price  DECIMAL(12, 2),
  volume DECIMAL(24, 3)
);

CREATE INDEX ON time_bitfinex (dt);

CREATE TABLE ohlc_bitfinex (
  date   TIMESTAMP WITHOUT TIME ZONE,
  open   DECIMAL(12, 2),
  high   DECIMAL(12, 2),
  low    DECIMAL(12, 2),
  close  DECIMAL(12, 2),
  volume INTEGER
);

CREATE INDEX ON ohlc_bitfinex (date);

TRUNCATE raw_bitfinex;

COPY raw_bitfinex FROM '/tmp/bitfinexUSD.csv' DELIMITER ',' CSV;

TRUNCATE time_bitfinex;

INSERT INTO time_bitfinex
  SELECT
    to_timestamp(epoch) "dt",
    price,
    volume
  FROM
    raw_bitfinex;

TRUNCATE ohlc_bitfinex;

INSERT INTO ohlc_bitfinex
  WITH lines AS (SELECT
                   date_trunc('hour', dt) + INTERVAL '1 minute' * floor(EXTRACT(MINUTE FROM dt) / 30) * 30 AS "date",
                   first_value(price)
                   OVER w                                                                                  AS "open",
                   MAX(price)
                   OVER w                                                                                  AS "high",
                   MIN(price)
                   OVER w                                                                                  AS "low",
                   last_value(price)
                   OVER w                                                                                  AS "close",
                   SUM(volume)
                   OVER w                                                                                  AS "volume"
                 FROM
                   time_bitfinex
                 WINDOW
                     w AS (
                     PARTITION BY date_trunc('hour', dt) +
                                  INTERVAL '1 minute' * floor(EXTRACT(MINUTE FROM dt) / 30) * 30
                     ORDER BY dt
                     ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING )
  )
  SELECT DISTINCT *
  FROM lines
  ORDER BY date;

COPY (
SELECT
  date   "Date",
  open   "Open",
  high   "High",
  low    "Low",
  close  "Close",
  volume "Volume"
FROM
  ohlc_bitfinex
) TO '/tmp/BTCUSD.csv' WITH CSV;