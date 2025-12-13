import pyqtgraph as pg
from PySide6.QtWidgets import QWidget, QVBoxLayout, QCheckBox, QHBoxLayout
from PySide6.QtCore import Signal, Slot
import numpy as np
from datetime import datetime

class TimeAxisItem(pg.AxisItem):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._start_timestamp_ms = 0

    def set_start_timestamp(self, ts_ms):
        self._start_timestamp_ms = ts_ms

    def tickStrings(self, values, scale, spacing):
        """Convert ms to HH:MM:SS.mmm format (Absolute Time)"""
        ret = []
        for x in values:
            # x is relative ms from start of file
            # Add absolute start time
            abs_time_ms = int(x + self._start_timestamp_ms)
            
            # Use datetime for easy formatting (handles days wrapping, though rare for single session)
            # But manual calculation is faster and sufficient for HH:MM:SS
            total_seconds = abs_time_ms // 1000
            ms = abs_time_ms % 1000
            
            # Convert to local time components (assuming timestamp is already local or needs conversion)
            # Here we assume the input timestamp was Unix Time (UTC) but we want to display it properly
            # Actually, standard is to work with datetime directly
            dt = datetime.fromtimestamp(total_seconds)
            
            # Format: HH:MM:SS.mmm
            ret.append(f"{dt.hour:02d}:{dt.minute:02d}:{dt.second:02d}.{ms:03d}")
        return ret

class GraphWidget(QWidget):
    """
    Widget to display 6-axis IMU data + Magnitude.
    Uses pyqtgraph for high performance.
    """
    
    # Cursor position changed signal (time in ms)
    cursor_changed = Signal(float)
    
    def __init__(self, parent=None):
        super().__init__(parent)
        
        # Configuration
        # Configuration (Global pyqtgraph settings)
        pg.setConfigOption('background', 'k')
        pg.setConfigOption('foreground', 'w')
        
        # Layout
        self._layout = QVBoxLayout(self)
        self._layout.setContentsMargins(0,0,0,0)
        
        # Checkbox for Magnitude
        self._controls_layout = QHBoxLayout()
        self._cb_magnitude = QCheckBox("Show Magnitude (合力)")
        self._cb_magnitude.setChecked(True)
        self._cb_magnitude.stateChanged.connect(self._update_plots)
        self._controls_layout.addWidget(self._cb_magnitude)
        self._controls_layout.addStretch()
        self._layout.addLayout(self._controls_layout)
        
        # Plots
        # We use a GraphicsLayoutWidget to manage multiple plots aligned vertically
        self._glw = pg.GraphicsLayoutWidget()
        self._layout.addWidget(self._glw)
        
        # Accel Plot (Top)
        self._plot_acc = self._glw.addPlot(row=0, col=0, title="Acceleration (g)")
        self._plot_acc.setLabel('left', 'Accel', units='g')
        self._plot_acc.showGrid(x=True, y=True, alpha=0.3)
        self._plot_acc.addLegend(offset=(10, 10))
        self._plot_acc.setYRange(-16, 16, padding=0.1) # Fixed range for 16g sensor
        self._plot_acc.hideAxis('bottom') # axis hidden for top plot
        
        # Gyro Plot (Bottom)
        time_axis = TimeAxisItem(orientation='bottom')
        self._plot_gyro = self._glw.addPlot(row=1, col=0, title="Gyroscope (dps)", axisItems={'bottom': time_axis})
        self._plot_gyro.setLabel('left', 'Gyro', units='dps')
        # self._plot_gyro.setLabel('bottom', 'Time', units='ms')
        self._plot_gyro.showGrid(x=True, y=True, alpha=0.3)
        self._plot_gyro.addLegend(offset=(10, 10))
        self._plot_gyro.setYRange(-2500, 2500, padding=0.1) # Fixed range for 2000dps sensor
        
        # Link X-axis (Zooming one zooms both)
        self._plot_gyro.setXLink(self._plot_acc)
        
        # Disable Y-axis zooming via mouse wheel on the plot area
        # (This prevents the "out of edge" issue when zooming time)
        self._plot_acc.setMouseEnabled(x=True, y=False)
        self._plot_gyro.setMouseEnabled(x=True, y=False)
        
        # Infinite Lines (Cursors) - Yellow
        self._cursor_acc = pg.InfiniteLine(angle=90, movable=True, pen=pg.mkPen('y', width=2))
        self._cursor_gyro = pg.InfiniteLine(angle=90, movable=True, pen=pg.mkPen('y', width=2))
        
        self._plot_acc.addItem(self._cursor_acc)
        self._plot_gyro.addItem(self._cursor_gyro)
        
        # Connect cursor signals
        self._cursor_acc.sigPositionChanged.connect(self._on_cursor_dragged)
        self._cursor_gyro.sigPositionChanged.connect(self._on_cursor_dragged)
        
        # Data references
        self._t = None # Relative time in ms
        self._start_timestamp = 0 # Absolute unix timestamp in ms
        self._acc = None # [ax, ay, az, amag]
        self._gyro = None # [gx, gy, gz, gmag]
        
        # Curves references
        self._curves_acc = {}
        self._curves_gyro = {}
        
    def set_data(self, df, start_timestamp_ms=0):
        """
        Set DataFrame from CSVReader.
        Expected columns: t_ms, accelX/Y/Z, gyroX/Y/Z, acc_mag, gyro_mag
        """
        if df is None or df.empty:
            return
            
        self._t = df['t_ms'].values
        self._start_timestamp = start_timestamp_ms 
        
        # Update Axis with offset
        self._plot_gyro.getAxis('bottom').set_start_timestamp(start_timestamp_ms)
        
        self._acc = {
            'x': df['accelX'].values,
            'y': df['accelY'].values,
            'z': df['accelZ'].values,
            'm': df['acc_mag'].values
        }
        
        self._gyro = {
            'x': df['gyroX'].values,
            'y': df['gyroY'].values,
            'z': df['gyroZ'].values,
            'm': df['gyro_mag'].values
        }
        
        self.plot_all()
        
    def plot_all(self):
        """Re-draw all curves."""
        self._plot_acc.clear()
        self._plot_gyro.clear()
        
        # Re-add cursors
        self._plot_acc.addItem(self._cursor_acc)
        self._plot_gyro.addItem(self._cursor_gyro)
        
        if self._t is None:
            return
            
        # Draw Accel
        # X: Red, Y: Green, Z: Blue
        self._plot_acc.plot(self._t, self._acc['x'], pen='r', name='X')
        self._plot_acc.plot(self._t, self._acc['y'], pen='g', name='Y')
        self._plot_acc.plot(self._t, self._acc['z'], pen='b', name='Z')
        
        # Draw Gyro
        self._plot_gyro.plot(self._t, self._gyro['x'], pen='r', name='X')
        self._plot_gyro.plot(self._t, self._gyro['y'], pen='g', name='Y')
        self._plot_gyro.plot(self._t, self._gyro['z'], pen='b', name='Z')
        
        # Draw Magnitude if checked
        if self._cb_magnitude.isChecked():
            # White thick line for magnitude
            self._plot_acc.plot(self._t, self._acc['m'], pen=pg.mkPen('w', width=2), name='Mag')
            self._plot_gyro.plot(self._t, self._gyro['m'], pen=pg.mkPen('w', width=2), name='Mag')
            
        # Set Auto Range
        self._plot_acc.autoRange()
        self._plot_gyro.autoRange()

    def _update_plots(self):
        """Refresh plots (e.g. when checkbox changes)."""
        self.plot_all()

    def _on_cursor_dragged(self, line):
        """Sync cursors and emit signal."""
        pos = line.value()
        
        # Block signals to prevent feedback
        self._cursor_acc.blockSignals(True)
        self._cursor_gyro.blockSignals(True)
        
        self._cursor_acc.setValue(pos)
        self._cursor_gyro.setValue(pos)
        
        self._cursor_acc.blockSignals(False)
        self._cursor_gyro.blockSignals(False)
        
        # Emit signal
        self.cursor_changed.emit(pos)

    @Slot(float)
    def set_cursor_position(self, t_ms):
        """Set cursor position from external source (e.g. Video)."""
        # Block signals to prevent feedback
        self._cursor_acc.blockSignals(True)
        self._cursor_gyro.blockSignals(True)
        
        self._cursor_acc.setValue(t_ms)
        self._cursor_gyro.setValue(t_ms)
        
        self._cursor_acc.blockSignals(False)
        self._cursor_gyro.blockSignals(False)

