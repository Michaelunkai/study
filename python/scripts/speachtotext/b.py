import sys
from PyQt5.QtWidgets import QApplication, QWidget, QVBoxLayout, QLabel, QPushButton
import speech_recognition as sr
from PyQt5.QtCore import QCoreApplication

class SpeechToTextApp(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Speech to Text")
        self.setStyleSheet("background-color: burgundy;")  # Set background color

        self.transcribed_text = ""
        self.is_listening = False

        self.output_label = QLabel("", self)
        self.output_label.setStyleSheet("font-size: 24px; font-weight: bold; color: lightyellow;")  # Adjust text color to light yellow and bold font
        self.layout = QVBoxLayout()
        self.layout.addWidget(self.output_label)

        self.btn_microphone = QPushButton("🎤", self)
        self.btn_microphone.setStyleSheet("font-weight: bold; color: lightyellow;")
        self.btn_microphone.clicked.connect(self.toggle_listening)
        self.layout.addWidget(self.btn_microphone)

        self.copy_button = QPushButton("Copy", self)
        self.copy_button.setStyleSheet("font-weight: bold; color: lightyellow;")
        self.copy_button.clicked.connect(self.copy_text)
        self.layout.addWidget(self.copy_button)

        self.setLayout(self.layout)

        self.recognizer = sr.Recognizer()
        self.microphone = sr.Microphone()

        self.adjust_size_to_buttons()

    def adjust_size_to_buttons(self):
        # Calculate the height of all buttons and labels
        total_height = self.output_label.sizeHint().height() + self.btn_microphone.sizeHint().height() + self.copy_button.sizeHint().height()
        # Get the maximum width of the buttons
        max_width = max(self.output_label.sizeHint().width(), self.btn_microphone.sizeHint().width(), self.copy_button.sizeHint().width())
        # Set the window size
        self.setFixedSize(max_width + 20, total_height + 40)  # Add some padding

    def adjust_size_to_text(self):
        # Adjust the size of the window to fit the text
        self.output_label.adjustSize()
        total_height = self.output_label.height() + self.btn_microphone.height() + self.copy_button.height()
        max_width = max(self.output_label.width(), self.btn_microphone.width(), self.copy_button.width())
        self.setFixedSize(max_width + 20, total_height + 40)  # Add some padding

    def toggle_listening(self):
        if not self.recognizer or not self.microphone:
            return

        if not self.is_listening:
            self.start_listening()
            self.btn_microphone.setText("Stop Listening")
        else:
            self.stop_listening()
            self.btn_microphone.setText("🎤")

    def start_listening(self):
        self.is_listening = True
        self.listen_for_speech()

    def stop_listening(self):
        self.is_listening = False

    def listen_for_speech(self):
        with self.microphone as source:
            self.recognizer.adjust_for_ambient_noise(source)
            audio = self.recognizer.listen(source)

        try:
            text = self.recognizer.recognize_google(audio)
            self.transcribed_text = text
            self.output_label.setText(self.transcribed_text)
            self.adjust_size_to_text()
        except sr.UnknownValueError:
            pass
        except sr.RequestError as e:
            self.output_label.setText(f"Error: {e}")
            self.adjust_size_to_text()

    def copy_text(self):
        QApplication.clipboard().setText(self.transcribed_text)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = SpeechToTextApp()
    window.show()
    sys.exit(app.exec_())
