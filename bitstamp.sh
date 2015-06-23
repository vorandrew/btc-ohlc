unlink /tmp/bitstampUSD.csv
wget -O /tmp/bitstampUSD.csv.gz http://api.bitcoincharts.com/v1/csv/bitstampUSD.csv.gz
gunzip /tmp/bitstampUSD.csv.gz
psql btc < bitstamp.sql
unlink /tmp/bitstampUSD.csv
mv /tmp/BTCUSD.csv ./