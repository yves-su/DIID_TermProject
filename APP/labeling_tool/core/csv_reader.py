import pandas as pd
import numpy as np
from datetime import datetime
import glob
import os

class CSVReader:
    """
    Handles loading, merging, and resampling of IMU CSV data.
    Target: 50Hz fixed grid (20ms)
    """
    
    # Expected columns from Android APP
    REQUIRED_COLUMNS = ['timestamp', 'accelX', 'accelY', 'accelZ', 'gyroX', 'gyroY', 'gyroZ']
    
    # Target Sampling Rate
    TARGET_FREQ_HZ = 50
    TARGET_dt_MS = 20  # 1000ms / 50Hz = 20ms
    
    def __init__(self):
        self._df_raw = None      # Combined raw dataframe
        self._df_resampled = None # Resampled 50Hz dataframe
        self._is_loaded = False
        
    def load_files(self, file_paths: list[str]) -> bool:
        """
        Load multiple CSV files, merge, sort, and process them.
        Returns True if successful.
        """
        try:
            df_list = []
            
            for fpath in file_paths:
                if not os.path.exists(fpath):
                    print(f"File not found: {fpath}")
                    continue
                
                # Read CSV
                # Format: timestamp,receivedAt,accelX,accelY,accelZ,gyroX,gyroY,gyroZ
                # timestamp example: 2025/12/05 22:20:06.510
                df = pd.read_csv(fpath)
                
                # Check columns
                if not all(col in df.columns for col in self.REQUIRED_COLUMNS):
                    print(f"Skipping {fpath}: Missing required columns")
                    continue
                    
                df_list.append(df)
                
            if not df_list:
                print("No valid CSV files loaded.")
                return False
                
            # Merge
            self._df_raw = pd.concat(df_list, ignore_index=True)
            
            # Processing
            self._process_raw_data()
            self._resample_data()
            
            self._is_loaded = True
            return True
            
        except Exception as e:
            print(f"Error loading CSVs: {e}")
            return False

    def _process_raw_data(self):
        """
        Parse timestamps and sort raw data.
        """
        # Parse 'timestamp' column to datetime objects
        # Format is 'yyyy/MM/dd HH:mm:ss.SSS'
        # pandas to_datetime is smart, but specifying format is safer/faster if consistent
        self._df_raw['datetime'] = pd.to_datetime(self._df_raw['timestamp'], format='%Y/%m/%d %H:%M:%S.%f')
        
        # Sort by time
        self._df_raw = self._df_raw.sort_values('datetime')
        
        # Drop duplicates (based on timestamp)
        self._df_raw = self._df_raw.drop_duplicates(subset=['datetime'])
        
        # Reset index
        self._df_raw = self._df_raw.reset_index(drop=True)
        
        # Convert timestamp to milliseconds (relative to start of the day or just keep as datetime)
        # For simplicity in labeling, we often use relative milliseconds from start
        # But here let's keep datetime as index for resampling advantage
        self._df_raw.set_index('datetime', inplace=True)

    def _resample_data(self):
        """
        Resample data to fixed 50Hz grid.
        Interpolate missing values.
        """
        if self._df_raw is None or self._df_raw.empty:
            return

        # 1. Create target time grid
        start_time = self._df_raw.index[0]
        end_time = self._df_raw.index[-1]
        
        # Stats Calculation
        self._raw_count = len(self._df_raw)
        total_seconds = (end_time - start_time).total_seconds()
        self._expected_count = int(total_seconds * self.TARGET_FREQ_HZ) + 1
        
        # Create DatetimeIndex with 20ms freq
        target_index = pd.date_range(start=start_time, end=end_time, freq=f'{self.TARGET_dt_MS}ms')
        
        # 2. Reindex raw data to this new grid
        combined_index = self._df_raw.index.union(target_index).sort_values()
        df_combined = self._df_raw.reindex(combined_index)
        
        # 3. Interpolate (Time-based linear interpolation)
        numeric_cols = ['accelX', 'accelY', 'accelZ', 'gyroX', 'gyroY', 'gyroZ']
        df_combined[numeric_cols] = df_combined[numeric_cols].interpolate(method='time')
        
        # 4. Select only the target grid points
        self._df_resampled = df_combined.reindex(target_index)
        
        # 5. Handle any remaining NaNs
        self._df_resampled[numeric_cols] = self._df_resampled[numeric_cols].ffill().bfill()
        
        # 6. Add convenience columns
        self._df_resampled['t_ms'] = (self._df_resampled.index - start_time).total_seconds() * 1000
        
        # Calculate Magnitude
        self._df_resampled['acc_mag'] = np.sqrt(
            self._df_resampled['accelX']**2 + 
            self._df_resampled['accelY']**2 + 
            self._df_resampled['accelZ']**2
        )
        self._df_resampled['gyro_mag'] = np.sqrt(
            self._df_resampled['gyroX']**2 + 
            self._df_resampled['gyroY']**2 + 
            self._df_resampled['gyroZ']**2
        )

    def get_stats(self) -> dict:
        """Returns statistics aboutloaded data"""
        if self._df_resampled is None:
            return {}
            
        duration_sec = self.get_duration_ms() / 1000.0
        # Loss Rate (Data Missing Rate)
        # Ideally we expected N samples, but we only had Raw samples.
        # But raw sampling rate might be different. 
        # Actually better to just show Raw count vs Expected (Target) count.
        
        # If sampling rate was unstable, raw_count < expected_count
        missing_ratio = 1.0 - (self._raw_count / self._expected_count) if self._expected_count > 0 else 0
        
        return {
            "duration_str": str(pd.Timedelta(seconds=duration_sec)).split('.')[0], # HH:MM:SS
            "total_samples": len(self._df_resampled),
            "expected_samples": self._expected_count,
            "raw_samples": self._raw_count,
            "missing_ratio": missing_ratio
        }

    def get_data(self) -> pd.DataFrame:
        """
        Returns the processed, 50Hz resampled dataframe.
        """
        return self._df_resampled

    def get_duration_ms(self) -> float:
        if self._df_resampled is not None:
            return self._df_resampled['t_ms'].iloc[-1]
        return 0.0

    def get_start_timestamp_str(self) -> str:
        if self._df_raw is not None and not self._df_raw.empty:
            # Use original raw start time
            return self._df_raw.index[0].strftime('%Y/%m/%d %H:%M:%S.%f')[:-3]
        return ""
        
    def get_start_timestamp_unix(self) -> float:
        """Returns start unix timestamp in milliseconds"""
        if self._df_raw is not None and not self._df_raw.empty:
            return self._df_raw.index[0].timestamp() * 1000
        return 0.0

    def get_start_datetime(self) -> datetime:
        """Returns start datetime object (Naive)"""
        if self._df_raw is not None and not self._df_raw.empty:
            return self._df_raw.index[0].to_pydatetime()
        return datetime.min

if __name__ == "__main__":
    # Test stub
    print("CSVReader Module")
