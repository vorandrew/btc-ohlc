# install.packages("TTR",repos='http://cran.uk.r-project.org')
# install.packages("quantmod",repos='http://cran.uk.r-project.org')
# install.packages("ggplot2",repos='http://cran.uk.r-project.org')
# install.packages("lubridate",repos='http://cran.uk.r-project.org')

require(TTR)
require(quantmod)
require(ggplot2)
require(scales)
require(lubridate)

btcusd = read.csv("/git/btc-ohlc/BTCUSD.csv", col.names = c("Date","Open","High","Low","Close","Volume"))

vol = volatility(
    btcusd[,c("Open","High","Low","Close")],
    calc = "garman.klass",
    n = 2 * 24 * 365,
    N = 2 * 24 * 365
)

tail(vol)

df = data.frame(
        dt = parse_date_time( btcusd[,c("Date")], '%Y%m%d %H%M%S'),
        vol = vol
    )

ggplot(df, aes(dt, vol)) + scale_y_datetime() + geom_line() +
  xlab("Date") + ylab("Volatility")


parse_date_time( , '%Y%m%d %H%M%S')

