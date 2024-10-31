"""
This script is designed to retrieve the current price of a specific product
from the Bulk website. It uses a headless browser to render the contents, then
compares it to a limit. It's intended to run on AWS Lambda.

Author: Awes Mubarak <contact@awesmubarak.com>
License: Unlicense [1] or MIT [2], 2024

[1]: https://unlicense.org
[2]: https://mit-license.org
"""

import os
import time

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.firefox.service import Service as FirefoxService


def setup_driver():
    """Set up the Selenium WebDriver for local or Lambda environments."""
    options = Options()
    options.headless = True  # Enable headless mode for Lambda compatibility

    # Check if running in an AWS Lambda environment
    if "LAMBDA_TASK_ROOT" in os.environ:
        # Paths specific to Lambda Layer
        options.binary_location = "/opt/firefox/firefox"
        driver_service = FirefoxService(executable_path="/opt/geckodriver")
    else:
        # Local paths (on my computer)
        options.binary_location = (
            "/Applications/Firefox Developer Edition.app/Contents/MacOS/firefox"
        )
        driver_service = FirefoxService(executable_path="/usr/local/bin/geckodriver")

    # Create and return the WebDriver instance
    return webdriver.Firefox(service=driver_service, options=options)


def get_product_price():
    """Retrieve the price from the Bulk product page."""
    driver = setup_driver()
    try:
        # Navigate to the product page
        driver.get("https://www.bulk.com/uk/products/sports-multi-am-pm/bpps-smul")

        # Wait for the page to load
        time.sleep(10)

        # Locate the price element using its CSS selector
        price_element = driver.find_element(
            By.CSS_SELECTOR,
            "span.dropin-price.dropin-price--default.dropin-price--small.dropin-price--bold",
        )

        # Extract and return the price text
        price_text = price_element.text
        print(f"Current Price: {price_text}")
        return price_text

    finally:
        # Quit the driver to free up resources
        driver.quit()


def lambda_handler(event=None, context=None):
    """AWS Lambda handler function."""
    price = get_product_price()

    # Return a JSON response with the price
    return {"statusCode": 200, "body": f"The current price is: {price}"}


# Local testing
if __name__ == "__main__":
    print(lambda_handler())
