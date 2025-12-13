from PySide6.QtWidgets import (QWidget, QVBoxLayout, QHBoxLayout, QPushButton, 
                               QSlider, QLabel, QStyle, QComboBox, QFileDialog)
from PySide6.QtMultimedia import QMediaPlayer, QAudioOutput
from PySide6.QtMultimediaWidgets import QVideoWidget
from PySide6.QtCore import Qt, QUrl, Signal, Slot

class VideoPlayer(QWidget):
    """
    Video Player Widget with controls:
    - Play/Pause
    - Seek Slider
    - Time Label
    - Playback Speed
    """
    
    # Signal emitted when video position changes (ms)
    position_changed = Signal(int)
    
    def __init__(self, parent=None):
        super().__init__(parent)
        
        self._setup_ui()
        self._setup_player()
        
    def _setup_ui(self):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        
        # 1. Video Output Widget
        self._video_widget = QVideoWidget()
        layout.addWidget(self._video_widget, stretch=1)
        
        # 2. Controls Layout
        controls_layout = QHBoxLayout()
        
        # Play/Pause Button
        self._btn_play = QPushButton()
        self._btn_play.setIcon(self.style().standardIcon(QStyle.SP_MediaPlay))
        self._btn_play.clicked.connect(self._toggle_play)
        controls_layout.addWidget(self._btn_play)
        
        # Seek Slider
        self._slider = QSlider(Qt.Horizontal)
        self._slider.setRange(0, 0)
        self._slider.sliderMoved.connect(self._set_position)
        self._slider.sliderPressed.connect(self._on_slider_pressed)
        self._slider.sliderReleased.connect(self._on_slider_released)
        controls_layout.addWidget(self._slider)
        
        # Time Label
        self._lbl_time = QLabel("00:00 / 00:00")
        controls_layout.addWidget(self._lbl_time)
        
        # Speed Control
        self._combo_speed = QComboBox()
        self._combo_speed.addItems(["0.25x", "0.5x", "1.0x", "1.5x", "2.0x"])
        self._combo_speed.setCurrentIndex(2) # Default 1.0x
        self._combo_speed.currentIndexChanged.connect(self._update_speed)
        controls_layout.addWidget(self._combo_speed)
        
        layout.addLayout(controls_layout)
        
    def _setup_player(self):
        self._player = QMediaPlayer()
        self._audio = QAudioOutput()
        self._player.setAudioOutput(self._audio)
        self._player.setVideoOutput(self._video_widget)
        
        # Connect signals
        self._player.positionChanged.connect(self._on_position_changed)
        self._player.durationChanged.connect(self._on_duration_changed)
        self._player.mediaStatusChanged.connect(self._on_media_status_changed)
        
        self._is_seeking = False
        
    def load_video(self, file_path):
        self._player.setSource(QUrl.fromLocalFile(file_path))
        self._btn_play.setEnabled(True)
        # Reset speed
        self._combo_speed.setCurrentIndex(2)
        
    def _toggle_play(self):
        if self._player.playbackState() == QMediaPlayer.PlayingState:
            self._player.pause()
            self._btn_play.setIcon(self.style().standardIcon(QStyle.SP_MediaPlay))
        else:
            self._player.play()
            self._btn_play.setIcon(self.style().standardIcon(QStyle.SP_MediaPause))
            
    def _update_speed(self):
        text = self._combo_speed.currentText()
        speed = float(text.replace("x", ""))
        self._player.setPlaybackRate(speed)
        
    def _on_position_changed(self, position):
        if not self._is_seeking:
            self._slider.setValue(position)
        self._update_time_label(position, self._player.duration())
        
        # Emit signal for SyncManager
        self.position_changed.emit(position)
        
    def _on_duration_changed(self, duration):
        self._slider.setRange(0, duration)
        self._update_time_label(self._player.position(), duration)
        
    def _update_time_label(self, current, total):
        self._lbl_time.setText(f"{self._format_time(current)} / {self._format_time(total)}")
        
    def _format_time(self, ms):
        seconds = (ms // 1000) % 60
        minutes = (ms // 60000) % 60
        # hours = (ms // 3600000)
        return f"{minutes:02d}:{seconds:02d}"
        
    def _set_position(self, position):
        self._player.setPosition(position)
        
    def _on_slider_pressed(self):
        self._is_seeking = True
        # Optional: pause while seeking?
        
    def _on_slider_released(self):
        self._is_seeking = False
        self._player.setPosition(self._slider.value())
        
    def _on_media_status_changed(self, status):
        # Ensure icon state is correct if stopped externally
        if status == QMediaPlayer.LoadedMedia:
            self._btn_play.setEnabled(True)
        elif status == QMediaPlayer.EndOfMedia:
            self._btn_play.setIcon(self.style().standardIcon(QStyle.SP_MediaPlay))

    @Slot(int)
    def set_position(self, ms):
        """External control (e.g. from Graph)"""
        # If external control changes position, we might need to reflect play state?
        # Usually sync only happens when paused, but if not, no icon change needed.
        if abs(self._player.position() - ms) > 50: # Avoid feedback loop jitter
            self._player.setPosition(ms)

    def is_playing(self):
        return self._player.playbackState() == QMediaPlayer.PlayingState

    def pause(self):
        self._player.pause()
        self._btn_play.setIcon(self.style().standardIcon(QStyle.SP_MediaPlay))
