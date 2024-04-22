from selenium import webdriver
from selenium.webdriver.common.keys import Keys
import os
import time

def scrape_aliexpress(search_query):
    url = f"https://www.aliexpress.com/wholesale?SearchText={search_query}&SortType=price_asc"

    # Set the path to GeckoDriver
    geckodriver_path = "/mnt/c/Users/micha/Downloads/geckodriver"

    # Set the PATH environment variable to include GeckoDriver directory
    os.environ["PATH"] += os.pathsep + os.path.dirname(geckodriver_path)

    # Configure Firefox options
    firefox_options = webdriver.FirefoxOptions()
    firefox_options.headless = True  # Run Firefox in headless mode (no browser window)

    # Initialize WebDriver with Firefox
    driver = webdriver.Firefox(options=firefox_options)

    driver.get(url)
    time.sleep(5)  # Wait for the page to load dynamically (adjust as needed)

    # Find the parent element that contains all the product items
    products_container = driver.find_element_by_id('root')

    # Find individual product items within the parent element
    products = products_container.find_elements_by_class_name('item')

    for product in products:
        try:
            title = product.find_element_by_class_name('product-title').text.strip()
        except:
            title = "N/A"

        try:
            price = product.find_element_by_class_name('price').text.strip()
        except:
            price = "N/A"

        print(f"Title: {title}, Price: {price}")

    driver.quit()

search_query = input("Enter product to search: ")
scrape_aliexpress(search_query)
