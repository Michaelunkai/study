import toga

class NoteTakingApp(toga.App):
    def startup(self):
        # Create a main window for the application
        main_window = toga.MainWindow(title=self.name)

        # Add a notebook widget to the main window
        notebook = toga.Notebook(main_window)
        main_window.content = notebook

        # Add some tabs to the notebook
        tab1 = toga.Tab(label='Notes')
        tab2 = toga.Tab(label='Categories')
        notebook.tabs = [tab1, tab2]

        # Run the application
        main_window.show()

def main():
    app = NoteTakingApp('Note Taking App', 'com.mycompany.notetaking')
    app.main_loop()

if __name__ == '__main__':
    main()