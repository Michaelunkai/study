import sys
from PyQt5.QtCore import Qt, QUrl
from PyQt5.QtWidgets import QApplication, QMainWindow, QDesktopWidget
from PyQt5.QtWebEngineWidgets import QWebEngineView

class GoogleApp(QMainWindow):
    def __init__(self):
        super().__init__()

        self.initUI()

    def initUI(self):
        self.webview = QWebEngineView()
        self.webview.load(QUrl("https://www.google.com"))

        self.setCentralWidget(self.webview)

        self.setWindowTitle("Google App")
        self.setGeometry(100, 100, 800, 600)
        self.center()

        self.show()

    def center(self):
        qr = self.frameGeometry()
        cp = QDesktopWidget().availableGeometry().center()
        qr.moveCenter(cp)
        self.move(qr.topLeft())

if __name__ == '__main__':
    app = QApplication(sys.argv)
    google_app = GoogleApp()
    sys.exit(app.exec_())
