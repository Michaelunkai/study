import time
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import undetected_chromedriver as uc
from fake_useragent import UserAgent

# Setup Chrome options
options = webdriver.ChromeOptions()
options.add_argument(f"user-agent={UserAgent().random}")
options.add_argument("user-data-dir=./")

# Start Chrome
driver = uc.Chrome(options=options)

# Open ChatGPT
driver.get('https://chat.openai.com/chat')
print("Page loaded: ", driver.title)

def send_message(message):
    try:
        chat_input = WebDriverWait(driver, 20).until(
            EC.presence_of_element_located((By.TAG_NAME, "textarea"))
        )
        chat_input.send_keys(message)
        time.sleep(2)
        chat_input.send_keys(Keys.ENTER)
        print("Message sent.")
    except Exception as e:
        print(f"An error occurred while sending the message: {e}")

def monitor_chat():
    last_text = ""
    while True:
        try:
            # Check for new messages
            messages = driver.find_elements(By.XPATH, "//div[contains(@class, 'markdown prose')]")
            if messages:
                last_message = messages[-1].text
                if last_message != last_text:
                    last_text = last_message
                else:
                    send_message("next")
                    time.sleep(10)  # Wait to ensure message is sent before checking again
            else:
                send_message("next")
        except Exception as e:
            print(f"An error occurred while monitoring the chat: {e}")
        time.sleep(5)

if __name__ == "__main__":
    input("Press Enter after you are logged in and inside the chat...")
    monitor_chat()
