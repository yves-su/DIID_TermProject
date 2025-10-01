#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
BLE IMU 資料接收程式
同時監聽自定義IMU服務和UART服務
"""

import asyncio
import struct
from bleak import BleakClient, BleakScanner
import nest_asyncio

# 允許嵌套事件循環（Spyder需要）
nest_asyncio.apply()

class BLEIMUReceiver:
    def __init__(self):
        self.device_name = "SmartRacket"
        
        # 自定義IMU服務
        self.imu_service_uuid = "0769bb8e-b496-4fdd-b53b-87462ff423d0"
        self.imu_characteristic_uuid = "8ee82f5b-76c7-4170-8f49-fff786257090"
        
        self.connected = False
        self.data_count = 0
        
    def imu_notification_handler(self, sender, data):
        """自定義IMU服務通知處理器"""
        try:
            if len(data) == 30:
                # 解析二進位資料
                timestamp = struct.unpack('<I', data[0:4])[0]
                accelX = struct.unpack('<f', data[4:8])[0]
                accelY = struct.unpack('<f', data[8:12])[0]
                accelZ = struct.unpack('<f', data[12:16])[0]
                gyroX = struct.unpack('<f', data[16:20])[0]
                gyroY = struct.unpack('<f', data[20:24])[0]
                gyroZ = struct.unpack('<f', data[24:28])[0]
                voltage = struct.unpack('<H', data[28:30])[0] / 100.0
                
                self.data_count += 1
                
                # 計算姿態角度
                import math
                pitch = math.atan2(-accelX, math.sqrt(accelY*accelY + accelZ*accelZ)) * 180 / math.pi
                roll = math.atan2(accelY, accelZ) * 180 / math.pi
                
                # 使用 \r 讓游標回到行首，不換行
                print(f"\r資料包 #{self.data_count:4d} | 時間:{timestamp} | 加速度:[{accelX:6.3f},{accelY:6.3f},{accelZ:6.3f}] | 角速度:[{gyroX:6.2f},{gyroY:6.2f},{gyroZ:6.2f}] | 電壓:{voltage:4.2f}V | 角度:Roll={roll:6.1f}°,Pitch={pitch:6.1f}°", end='', flush=True)
            else:
                print(f"\r資料長度錯誤: {len(data)} bytes", end='', flush=True)
        except Exception as e:
            print(f"\r資料解析錯誤: {e}", end='', flush=True)
    
    
    async def scan_and_connect(self):
        """掃描並連接BLE設備"""
        print("正在掃描BLE設備...")
        
        try:
            devices = await BleakScanner.discover(timeout=10.0)
            target_device = None
            
            print(f"找到 {len(devices)} 個BLE設備:")
            for device in devices:
                print(f"  - {device.name or 'Unknown'} ({device.address})")
                if device.name and self.device_name in device.name:
                    target_device = device
                    print(f"  [OK] 找到目標設備: {device.name}")
            
            if not target_device:
                print(f"未找到設備: {self.device_name}")
                return False
            
            print(f"正在連接到 {target_device.name}...")
            self.client = BleakClient(target_device.address)
            await self.client.connect()
            print("BLE連接成功!")
            self.connected = True
            return True
            
        except Exception as e:
            print(f"BLE掃描/連接失敗: {e}")
            return False
    
    async def run(self):
        """主執行迴圈"""
        if not await self.scan_and_connect():
            return
        
        try:
            # 啟動IMU服務的通知
            print("啟動IMU服務通知...")
            await self.client.start_notify(self.imu_characteristic_uuid, self.imu_notification_handler)
            
            print("開始接收IMU資料...")
            print("按 Ctrl+C 停止")
            print("=" * 60)
            
            # 保持連接
            while True:
                await asyncio.sleep(1)
                
        except KeyboardInterrupt:
            print("\n停止接收...")
        except Exception as e:
            print(f"執行錯誤: {e}")
        finally:
            if self.client and self.connected:
                await self.client.disconnect()
                print("BLE連接已斷開")

def run_ble_receiver():
    """Spyder專用執行函數"""
    async def main():
        receiver = BLEIMUReceiver()
        await receiver.run()
    
    # 在Spyder中運行
    asyncio.run(main())

if __name__ == "__main__":
    run_ble_receiver()
