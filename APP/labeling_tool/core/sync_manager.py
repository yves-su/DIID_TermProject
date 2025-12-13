class SyncManager:
    """
    Manages synchronization between Video Time (t_vide) and CSV Time (t_csv).
    Formula: t_csv = (t_video * scale_factor) + offset_ms
    
    Start Anchor (A): (video_time_1, csv_time_1)
    End Anchor (B): (video_time_2, csv_time_2)
    """
    
    def __init__(self):
        self._offset_ms = 0.0
        self._scale_factor = 1.0
        
        # Anchors
        self._anchor_a = None # (t_vid, t_csv)
        self._anchor_b = None # (t_vid, t_csv)
        
    def set_params(self, offset_ms, scale_factor=1.0):
        self._offset_ms = offset_ms
        self._scale_factor = scale_factor
        
    def video_to_csv(self, t_video_ms):
        """Convert Video Time -> CSV Time (Relative ms)"""
        return (t_video_ms * self._scale_factor) + self._offset_ms
        
    def csv_to_video(self, t_csv_ms):
        """Convert CSV Time -> Video Time"""
        if self._scale_factor == 0:
            return 0
        return (t_csv_ms - self._offset_ms) / self._scale_factor
        
    def set_start_anchor(self, t_vid, t_csv):
        self._anchor_a = (t_vid, t_csv)
        self._recalculate()
        
    def set_end_anchor(self, t_vid, t_csv):
        self._anchor_b = (t_vid, t_csv)
        self._recalculate()
        
    def _recalculate(self):
        """
        Recalculate Offset and Scale based on anchors.
        If only A is set -> simple offset update.
        If A and B are set -> two-point scaling.
        """
        if self._anchor_a is not None and self._anchor_b is not None:
            # Two-point scaling
            t_v1, t_c1 = self._anchor_a
            t_v2, t_c2 = self._anchor_b
            
            if t_v2 == t_v1:
                return # Avoid division by zero
                
            self._scale_factor = (t_c2 - t_c1) / (t_v2 - t_v1)
            self._offset_ms = t_c1 - (t_v1 * self._scale_factor)
            
        elif self._anchor_a is not None:
            # Single anchor (Start) -> Just offset, keep scale=1.0
            t_v1, t_c1 = self._anchor_a
            self._scale_factor = 1.0
            self._offset_ms = t_c1 - t_v1
            
    def get_params(self):
        return {
            "offset_ms": self._offset_ms,
            "scale_factor": self._scale_factor
        }
