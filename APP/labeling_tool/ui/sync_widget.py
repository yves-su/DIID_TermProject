from PySide6.QtWidgets import (QWidget, QHBoxLayout, QPushButton, QLabel, 
                               QCheckBox, QGroupBox, QGridLayout)
from PySide6.QtCore import Signal, Qt

class SyncWidget(QWidget):
    """
    Widget for managing synchronization anchors (A and B).
    """
    
    # Signals
    set_anchor_a = Signal() # Request to set Anchor A using current Video/Graph times
    set_anchor_b = Signal() # Request to set Anchor B
    reset_sync = Signal()
    lock_toggled = Signal(bool) # True=Locked (Synced), False=Unlocked (Independent)
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._setup_ui()
        
    def _setup_ui(self):
        layout = QHBoxLayout(self)
        layout.setContentsMargins(0, 5, 0, 5)
        
        # Group Box
        group = QGroupBox("Synchronization Control")
        layout.addWidget(group)
        
        gl = QGridLayout(group)
        
        # 1. Sync Lock
        # When Locked: Video and Graph move together.
        # When Unlocked: Adjusting one does not affect the other (used for alignment).
        self._chk_lock = QCheckBox("Lock Sync (同步鎖定)")
        self._chk_lock.setChecked(True)
        self._chk_lock.toggled.connect(self.lock_toggled.emit)
        gl.addWidget(self._chk_lock, 0, 0, 1, 2)
        
        # 2. Status Label
        self._lbl_status = QLabel("Mode: Default (Offset=0)")
        self._lbl_status.setStyleSheet("color: gray;")
        gl.addWidget(self._lbl_status, 0, 2, 1, 2)
        
        # 3. Anchor A Controls
        btn_a = QPushButton("Set Start Anchor (A)")
        btn_a.setToolTip("Align Video Start Point with Data Start Point")
        btn_a.clicked.connect(self.set_anchor_a.emit)
        gl.addWidget(btn_a, 1, 0)
        
        self._lbl_a_val = QLabel("A: Not Set")
        gl.addWidget(self._lbl_a_val, 1, 1)
        
        # 4. Anchor B Controls
        btn_b = QPushButton("Set End Anchor (B)")
        btn_b.setToolTip("Align Video End Point with Data End Point (Fixes Drift)")
        btn_b.clicked.connect(self.set_anchor_b.emit)
        gl.addWidget(btn_b, 1, 2)
        
        self._lbl_b_val = QLabel("B: Not Set")
        gl.addWidget(self._lbl_b_val, 1, 3)
        
        # 5. Reset
        btn_reset = QPushButton("Reset")
        btn_reset.clicked.connect(self.reset_sync.emit)
        gl.addWidget(btn_reset, 1, 4)
        
    def update_status(self, offset_ms, scale_factor):
        self._lbl_status.setText(f"Offset: {offset_ms:.0f}ms | Scale: {scale_factor:.6f}")
        
    def update_anchor_label(self, anchor, t_vid, t_csv):
        text = f"V:{t_vid/1000:.1f}s / D:{t_csv/1000:.1f}s"
        if anchor == 'A':
            self._lbl_a_val.setText(f"A: {text}")
            self._lbl_a_val.setStyleSheet("color: green;")
        elif anchor == 'B':
            self._lbl_b_val.setText(f"B: {text}")
            self._lbl_b_val.setStyleSheet("color: blue;")
            
    def clear_anchors(self):
        self._lbl_a_val.setText("A: Not Set")
        self._lbl_a_val.setStyleSheet("color: black;")
        self._lbl_b_val.setText("B: Not Set")
        self._lbl_b_val.setStyleSheet("color: black;")
        self._lbl_status.setText("Mode: Default (Offset=0)")
        
    def is_locked(self):
        return self._chk_lock.isChecked()
