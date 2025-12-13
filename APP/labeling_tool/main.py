import sys
import os

# Ensure High DPI support
os.environ["QT_AUTO_SCREEN_SCALE_FACTOR"] = "1"

from PySide6.QtWidgets import QApplication, QMainWindow, QLabel, QVBoxLayout, QWidget, QFileDialog, QMenuBar, QMenu
from PySide6.QtGui import QAction
from PySide6.QtCore import Qt
from ui.graph_widget import GraphWidget
from core.csv_reader import CSVReader

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("SmartRacket Labeling Tool (Phase 1)")
        self.resize(1200, 800)
        
        # Components
        self.csv_reader = CSVReader()
        
        # Central Widget
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        self.layout = QVBoxLayout(central_widget)
        
        # Graph Widget
        self.graph_widget = GraphWidget()
        self.layout.addWidget(self.graph_widget)
        
        # Setup Menu
        self._setup_menu()
        
    def _setup_menu(self):
        menubar = self.menuBar()
        file_menu = menubar.addMenu("File")
        
        # Load CSV Action
        load_csv_action = QAction("Load CSV files...", self)
        load_csv_action.triggered.connect(self._load_csv_files)
        file_menu.addAction(load_csv_action)
        
    def _load_csv_files(self):
        file_paths, _ = QFileDialog.getOpenFileNames(
            self, "Open CSV Files", "", "CSV Files (*.csv)"
        )
        
        if file_paths:
            print(f"Loading {len(file_paths)} files...")
            success = self.csv_reader.load_files(file_paths)
            if success:
                print("Load successful. Plotting...")
                df = self.csv_reader.get_data()
                # Get start timestamp in ms (Unix timestamp)
                start_ts = self.csv_reader.get_start_timestamp_unix() 
                self.graph_widget.set_data(df, start_ts)
            else:
                print("Load failed.")

def main():
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec())

if __name__ == "__main__":
    main()
