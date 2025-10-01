#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
BLE IMU 3D 視覺化程式
接收Arduino BLE藍牙資料，即時顯示立體三軸指標
"""

import time
import math
import numpy as np
import pygame
from pygame.locals import *
from OpenGL.GL import *
from OpenGL.GLU import *
import struct
from bleak import BleakClient, BleakScanner
import asyncio
import nest_asyncio
import threading

# 允許嵌套事件循環（Spyder需要）
nest_asyncio.apply()

class BLEIMUVisualizer:
    def __init__(self):
        """初始化BLE IMU視覺化器"""
        self.running = True
        self.connected = False
        self.client = None
        
        # IMU資料
        self.accel = [0, 0, 0]  # 加速度
        self.gyro = [0, 0, 0]   # 角速度
        self.voltage = 0        # 電壓
        self.debug_mode = False # 除錯模式
        
        # 姿態角度（歐拉角）
        self.roll = 0   # 繞X軸旋轉
        self.pitch = 0  # 繞Y軸旋轉
        self.yaw = 0    # 繞Z軸旋轉
        
        # BLE設定
        self.device_name = "SmartRacket"
        self.service_uuid = "0769bb8e-b496-4fdd-b53b-87462ff423d0"
        self.characteristic_uuid = "8ee82f5b-76c7-4170-8f49-fff786257090"
        
        # 初始化Pygame和OpenGL
        self.init_display()
        
    def init_display(self):
        """初始化顯示視窗"""
        pygame.init()
        self.screen = pygame.display.set_mode((800, 600), DOUBLEBUF | OPENGL)
        pygame.display.set_caption("BLE IMU 3D 視覺化 - SmartRacket (按H查看幫助)")
        
        # 設定OpenGL視角
        glEnable(GL_DEPTH_TEST)
        glEnable(GL_LIGHTING)
        glEnable(GL_LIGHT0)
        glEnable(GL_COLOR_MATERIAL)
        
        # 設定光源
        glLightfv(GL_LIGHT0, GL_POSITION, [0, 0, 1, 0])
        glLightfv(GL_LIGHT0, GL_AMBIENT, [0.3, 0.3, 0.3, 1])
        glLightfv(GL_LIGHT0, GL_DIFFUSE, [0.8, 0.8, 0.8, 1])
        
        # 設定視角
        gluPerspective(45, 800/600, 0.1, 50.0)
        glTranslatef(0.0, 0.0, -5.0)
    
    def scan_and_connect_sync(self):
        """同步版本的BLE掃描和連接"""
        print("正在掃描BLE設備...")
        
        try:
            # 在新的事件循環中運行
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            
            devices = loop.run_until_complete(BleakScanner.discover(timeout=5.0))
            target_device = None
            
            for device in devices:
                if device.name and self.device_name in device.name:
                    target_device = device
                    print(f"找到設備: {device.name} ({device.address})")
                    break
            
            if not target_device:
                print(f"未找到設備: {self.device_name}")
                return False
            
            self.client = BleakClient(target_device.address)
            loop.run_until_complete(self.client.connect())
            print("BLE連接成功!")
            self.connected = True
            
            # 啟動通知
            loop.run_until_complete(self.client.start_notify(self.characteristic_uuid, self.notification_handler))
            print("BLE通知已啟動")
            
            return True
        except Exception as e:
            print(f"BLE掃描/連接失敗: {e}")
            print("將使用模擬資料模式")
            return False
    
    def notification_handler(self, sender, data):
        """BLE通知處理器"""
        try:
            if len(data) == 30:
                # 解析二進位資料 - 對應main.ino的資料格式
                timestamp = struct.unpack('<I', data[0:4])[0]  # 4 bytes timestamp
                accelX = struct.unpack('<f', data[4:8])[0]     # 4 bytes accelX
                accelY = struct.unpack('<f', data[8:12])[0]    # 4 bytes accelY
                accelZ = struct.unpack('<f', data[12:16])[0]   # 4 bytes accelZ
                gyroX = struct.unpack('<f', data[16:20])[0]    # 4 bytes gyroX
                gyroY = struct.unpack('<f', data[20:24])[0]    # 4 bytes gyroY
                gyroZ = struct.unpack('<f', data[24:28])[0]    # 4 bytes gyroZ
                voltageRaw = struct.unpack('<H', data[28:30])[0]  # 2 bytes voltage (uint16)
                
                self.accel = [accelX, accelY, accelZ]
                self.gyro = [gyroX, gyroY, gyroZ]
                self.voltage = voltageRaw / 100.0  # 轉換為實際電壓值
                
                # 計算姿態角度
                self.calculate_attitude()
                
                # 可選：顯示接收到的資料（除錯用）
                if hasattr(self, 'debug_mode') and self.debug_mode:
                    print(f"IMU資料: 時間={timestamp}, 加速度=[{accelX:.3f},{accelY:.3f},{accelZ:.3f}], 角速度=[{gyroX:.3f},{gyroY:.3f},{gyroZ:.3f}], 電壓={self.voltage:.2f}V")
            else:
                print(f"資料長度錯誤: {len(data)} bytes (期望30 bytes)")
        except Exception as e:
            print(f"資料解析錯誤: {e}")
    
    def calculate_attitude(self):
        """計算姿態角度"""
        # 使用加速度計計算俯仰角和滾轉角
        ax, ay, az = self.accel
        
        # 計算俯仰角 (pitch) 和滾轉角 (roll)
        self.pitch = math.atan2(-ax, math.sqrt(ay*ay + az*az)) * 180 / math.pi
        self.roll = math.atan2(ay, az) * 180 / math.pi
        
        # 使用陀螺儀積分計算偏航角 (yaw)
        # 注意：這只是簡化版本，實際應用需要更複雜的融合算法
        self.yaw += self.gyro[2] * 0.02  # 20ms更新間隔 (50Hz)
        
        # 限制角度範圍
        self.roll = self.roll % 360
        self.pitch = self.pitch % 360
        self.yaw = self.yaw % 360
    
    def draw_axes(self):
        """繪製三軸指標"""
        glPushMatrix()
        
        # 旋轉到當前姿態
        glRotatef(self.roll, 1, 0, 0)   # 繞X軸旋轉
        glRotatef(self.pitch, 0, 1, 0)  # 繞Y軸旋轉
        glRotatef(self.yaw, 0, 0, 1)    # 繞Z軸旋轉
        
        # 繪製X軸（紅色）
        glColor3f(1, 0, 0)
        glBegin(GL_LINES)
        glVertex3f(0, 0, 0)
        glVertex3f(2, 0, 0)
        glEnd()
        
        # 繪製Y軸（綠色）
        glColor3f(0, 1, 0)
        glBegin(GL_LINES)
        glVertex3f(0, 0, 0)
        glVertex3f(0, 2, 0)
        glEnd()
        
        # 繪製Z軸（藍色）
        glColor3f(0, 0, 1)
        glBegin(GL_LINES)
        glVertex3f(0, 0, 0)
        glVertex3f(0, 0, 2)
        glEnd()
        
        # 繪製軸端箭頭
        self.draw_arrow(2, 0, 0, 1, 0, 0)  # X軸箭頭
        self.draw_arrow(0, 2, 0, 0, 1, 0)  # Y軸箭頭
        self.draw_arrow(0, 0, 2, 0, 0, 1)  # Z軸箭頭
        
        glPopMatrix()
    
    def draw_arrow(self, x, y, z, r, g, b):
        """繪製箭頭"""
        glColor3f(r, g, b)
        glBegin(GL_TRIANGLES)
        # 簡化的箭頭形狀
        glVertex3f(x, y, z)
        glVertex3f(x-0.1, y-0.1, z-0.1)
        glVertex3f(x-0.1, y+0.1, z-0.1)
        glEnd()
    
    def draw_reference_grid(self):
        """繪製參考網格"""
        glColor3f(0.3, 0.3, 0.3)
        glBegin(GL_LINES)
        
        # 繪製網格線
        for i in range(-5, 6):
            # X方向網格線
            glVertex3f(i, -5, 0)
            glVertex3f(i, 5, 0)
            # Y方向網格線
            glVertex3f(-5, i, 0)
            glVertex3f(5, i, 0)
        
        glEnd()
    
    def render(self):
        """渲染場景"""
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        
        # 繪製三軸指標
        self.draw_axes()
        
        # 繪製參考網格
        self.draw_reference_grid()
        
        pygame.display.flip()
    
    def handle_events(self):
        """處理事件"""
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self.running = False
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    self.running = False
                elif event.key == pygame.K_r:
                    # 重置姿態
                    self.roll = self.pitch = self.yaw = 0
                    print("姿態已重置")
                elif event.key == pygame.K_d:
                    # 切換除錯模式
                    self.debug_mode = not self.debug_mode
                    print(f"除錯模式: {'開啟' if self.debug_mode else '關閉'}")
                elif event.key == pygame.K_v:
                    # 顯示電壓資訊
                    print(f"當前電壓: {self.voltage:.2f}V")
                elif event.key == pygame.K_h:
                    # 顯示幫助
                    self.show_help()
    
    def show_help(self):
        """顯示幫助資訊"""
        print("\n" + "="*50)
        print("BLE IMU 3D 視覺化程式 - 鍵盤控制")
        print("="*50)
        print("ESC - 退出程式")
        print("R   - 重置姿態角度")
        print("D   - 切換除錯模式")
        print("V   - 顯示電壓資訊")
        print("H   - 顯示此幫助")
        print("="*50)
        print("三軸顏色說明:")
        print("紅色 - X軸 (前後)")
        print("綠色 - Y軸 (左右)")
        print("藍色 - Z軸 (上下)")
        print("="*50)
    
    def run(self):
        """主執行迴圈"""
        # 連接BLE設備
        if not self.scan_and_connect_sync():
            print("無法連接BLE設備，使用模擬資料")
            self.simulate_data = True
        else:
            self.simulate_data = False
        
        print("BLE IMU 3D 視覺化程式啟動")
        print("按 H 查看鍵盤控制說明")
        self.show_help()
        
        clock = pygame.time.Clock()
        
        while self.running:
            # 處理事件
            self.handle_events()
            
            # 模擬資料（如果沒有BLE連接）
            if self.simulate_data:
                self.simulate_imu_data()
            
            # 渲染場景
            self.render()
            
            # 控制幀率
            clock.tick(60)
        
        # 清理資源
        if self.client and self.connected:
            try:
                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)
                loop.run_until_complete(self.client.disconnect())
            except:
                pass
        pygame.quit()
    
    def simulate_imu_data(self):
        """模擬IMU資料（用於測試）"""
        t = time.time()
        self.roll = 30 * math.sin(t)
        self.pitch = 20 * math.cos(t * 0.7)
        self.yaw = 15 * math.sin(t * 0.5)

def main():
    """主函數"""
    visualizer = BLEIMUVisualizer()
    visualizer.run()

def run_visualizer():
    """Spyder專用執行函數"""
    main()

if __name__ == "__main__":
    main()