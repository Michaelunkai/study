from selenium import webdriver
from bs4 import BeautifulSoup
import time
def test_speed():
    driver = webdriver.Firefox()  # or webdriver.Chrome()
    driver.get('https://fast.com')
    time.sleep(60)  # Wait for test to complete
    soup = BeautifulSoup(driver.page_source, 'html.parser')
    speed = soup.find('div', {'class': 'speed-results-container'}).text
    driver.quit()
    return speed
print("Internet speed: ", test_speed())