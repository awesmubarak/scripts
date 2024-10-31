"""Quantopian `get_pricing` Replacement Script

This script provides a drop-in replacement for the `get_pricing` function that was
previously used on the now-defunct Quantopian platform. It's useful if you're
following the course on one of the archives [1].

The best approach is to set up a virtual environment and install this module for
easy integration. I reccomend setting up a virtual environment and using this as a
module (Poetry makes this easy). For an example see my quant_notebooks [2]

Author: Awes Mubarak <contact@awesmubarak.com>
License: Unlicense [3] OR MIT [4], 2024

[1]: https://gist.github.com/ih2502mk/50d8f7feb614c8676383431b056f4291
[2]: https://github.com/awesmubarak/quant_notebooks
[3]: https://unlicense.org
[4]: https://opensource.org/licenses/MIT
"""

import yfinance as yf
import pandas as pd


def get_pricing(ticker, start_date, end_date, frequency="1d"):
    """
    Mimics Quantopian's get_pricing function using yfinance.

    Parameters:
    ticker (str): Ticker symbol of the stock (e.g., 'AAPL').
    start_date (str): Start date in 'YYYY-MM-DD' format.
    end_date (str): End date in 'YYYY-MM-DD' format.
    frequency (str): Data frequency ('1d' for daily, '1m' for minute). Other intervals can be added as needed.

    Returns:
    pd.DataFrame: DataFrame with columns ['open_price', 'high', 'low', 'close_price', 'volume', 'price'].
    """
    # Ensure the correct interval is used for minute data
    if frequency == "1m":
        interval = "1m"
    else:
        interval = frequency

    # Fetch data using yfinance
    try:
        data = yf.download(
            ticker, start=start_date, end=end_date, interval=interval, progress=False
        )
    except Exception as e:
        raise ValueError(f"Error fetching data for {ticker}: {e}")

    if data.empty:
        raise ValueError(f"No data found for {ticker} from {start_date} to {end_date}.")

    # Rename columns to match the Quantopian format
    data = data.rename(
        columns={
            "Open": "open_price",
            "High": "high",
            "Low": "low",
            "Close": "close_price",
            "Volume": "volume",
        }
    )

    # Create the `price` column as a copy of the `close_price`
    data["price"] = data["close_price"]

    # Format the DataFrame to match Quantopian's MultiIndex style (date + ticker)
    data.index.name = "timestamp"
    formatted_data = data.reset_index().set_index(["timestamp"])

    # Add multi-index support if requested (optional)
    formatted_data["symbol"] = ticker
    formatted_data.set_index("symbol", append=True, inplace=True)
    formatted_data = formatted_data
    return formatted_data
