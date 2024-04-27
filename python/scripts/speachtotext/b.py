import sys
from PyQt5.QtWidgets import QApplication, QWidget, QVBoxLayout, QLabel, QPushButton
import speech_recognition as sr
from PyQt5.QtCore import QCoreApplication

class SpeechToTextApp(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Speech to Text")
        self.setGeometry(100, 100, 400, 300)
        
        self.transcribed_text = ""
        self.is_listening = False

        self.output_label = QLabel("", self)
        self.output_label.setStyleSheet("font-size: 24px; font-weight: bold;")
        self.layout = QVBoxLayout()
        self.layout.addWidget(self.output_label)

        self.btn_microphone = QPushButton("🎤", self)
        self.btn_microphone.clicked.connect(self.toggle_listening)
        self.layout.addWidget(self.btn_microphone)

        self.copy_button = QPushButton("Copy", self)
        self.copy_button.clicked.connect(self.copy_text)
        self.layout.addWidget(self.copy_button)

        self.setLayout(self.layout)

        self.recognizer = sr.Recognizer()
        self.microphone = sr.Microphone()

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
        except sr.UnknownValueError:
            pass
        except sr.RequestError as e:
            self.output_label.setText(f"Error: {e}")

    def copy_text(self):
        QApplication.clipboard().setText(self.transcribed_text)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = SpeechToTextApp()
    window.show()
    sys.exit(app.exec_())
