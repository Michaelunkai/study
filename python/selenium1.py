from selenium.webdriver.support.ui import Select
from selenium import webdriver
from selenium.webdriver.chrome.service import Service

# Absolute path to the Chrome WebDriver executable
chrome_driver_path = "/path/to/chromedriver"

# Specify the service argument with the path to the Chrome WebDriver
service = Service(chrome_driver_path)

# Initialize the Chrome WebDriver with the specified service
driver = webdriver.Chrome(service=service)
# 2.2. Navigate to a Website
driver.get("https://www.example.com")

# 2.3. Verify Page Title
assert "Example Domain" in driver.title

# Step 3: Interacting with Web Elements

# 3.1. Locating Elements
search_box = driver.find_element_by_name("q")
search_button = driver.find_element_by_name("btnK")
dropdown = driver.find_element_by_id("dropdownMenu")

# 3.2. Typing into Textboxes
search_box.send_keys("Selenium Tutorial")

# 3.3. Clicking Buttons
search_button.click()

# 3.4. Handling Dropdowns
select = Select(dropdown)
select.select_by_visible_text("Option 1")

# Optional: Close the WebDriver
# driver.quit()
