from tkinter import Tk, Label, Button
from selenium import webdriver
from bs4 import BeautifulSoup
import threading
import time

class SpeedTestApp:
    def __init__(self, master):
        self.master = master
        master.title("Speed Test App")

        self.label = Label(master, text="Click the button to test internet speed.")
        self.label.pack()

        self.test_button = Button(master, text="Run Speed Test", command=self.run_speed_test)
        self.test_button.pack()

    def run_speed_test(self):
        self.label.config(text="Running speed test...")
        threading.Thread(target=self.run_speed_test_thread).start()

    def run_speed_test_thread(self):
        driver = webdriver.Firefox()  # or webdriver.Chrome()
        driver.get('https://fast.com')
        time.sleep(60)  # Wait for test to complete
        soup = BeautifulSoup(driver.page_source, 'html.parser')
        speed = soup.find('div', {'class': 'speed-results-container'}).text
        driver.quit()

        self.label.config(text=f"Internet speed: {speed}")

if __name__ == "__main__":
    root = Tk()
    app = SpeedTestApp(root)
    root.mainloop()
