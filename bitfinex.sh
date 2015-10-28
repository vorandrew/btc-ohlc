unlink /tmp/bitfinexUSD.csv
wget -O /tmp/bitfinexUSD.csv.gz http://api.bitcoincharts.com/v1/csv/bitfinexUSD.csv.gz
gunzip /tmp/bitfinexUSD.csv.gz
time psql btc < bitfinex.sql
unlink /tmp/bitfinexUSD.csv
mv /tmp/BTCUSD.csv ./