#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
BLE IMU 3D 視覺化程式 - 簡化版
解決Windows GUI事件循環衝突問題
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
import threading
import queue

class BLEIMUVisualizerSimple:
    def __init__(self):
        """初始化BLE IMU視覺化器"""
        self.running = True
        self.connected = False
        self.client = None
        self.data_queue = queue.Queue()
        
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
        
        # 設定OpenGL
        glEnable(GL_DEPTH_TEST)
        glEnable(GL_LIGHTING)
        glEnable(GL_LIGHT0)
        glEnable(GL_COLOR_MATERIAL)
        
        # 設定光源
        glLightfv(GL_LIGHT0, GL_POSITION, [0, 0, 1, 0])
        glLightfv(GL_LIGHT0, GL_AMBIENT, [0.5, 0.5, 0.5, 1])
        glLightfv(GL_LIGHT0, GL_DIFFUSE, [1.0, 1.0, 1.0, 1])
        
        # 設定視角
        glMatrixMode(GL_PROJECTION)
        glLoadIdentity()
        gluPerspective(45, 800/600, 0.1, 50.0)
        glMatrixMode(GL_MODELVIEW)
        glLoadIdentity()
        glTranslatef(0.0, 0.0, -5.0)
        
        # 設定背景色
        glClearColor(0.1, 0.1, 0.2, 1.0)  # 深藍色背景
    
    def notification_handler(self, sender, data):
        """BLE通知處理器 - 在背景線程中運行"""
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
                voltageRaw = struct.unpack('<H', data[28:30])[0]
                
                # 顯示原始資料
                print(f"原始資料: 時間={timestamp}, 加速度=[{accelX:.4f},{accelY:.4f},{accelZ:.4f}], 角速度=[{gyroX:.2f},{gyroY:.2f},{gyroZ:.2f}], 電壓={voltageRaw/100.0:.2f}V")
                
                # 將資料放入佇列
                imu_data = {
                    'accel': [accelX, accelY, accelZ],
                    'gyro': [gyroX, gyroY, gyroZ],
                    'voltage': voltageRaw / 100.0,
                    'timestamp': timestamp
                }
                self.data_queue.put(imu_data)
                
        except Exception as e:
            print(f"BLE資料解析錯誤: {e}")
    
    def process_ble_data(self):
        """處理BLE資料佇列"""
        try:
            data_count = 0
            while not self.data_queue.empty():
                data = self.data_queue.get_nowait()
                self.accel = data['accel']
                self.gyro = data['gyro']
                self.voltage = data['voltage']
                
                # 計算姿態角度
                self.calculate_attitude()
                
                data_count += 1
                
                # 除錯輸出
                if self.debug_mode:
                    print(f"IMU: 時間={data['timestamp']}, 加速度={self.accel}, 角速度={self.gyro}, 電壓={self.voltage:.2f}V")
            
            # 每100幀顯示一次資料接收狀態
            if hasattr(self, 'frame_count'):
                self.frame_count += 1
            else:
                self.frame_count = 0
                
            if self.frame_count % 100 == 0:
                if data_count > 0:
                    print(f"收到 {data_count} 個BLE資料包")
                else:
                    print("沒有收到新的BLE資料")
                
        except queue.Empty:
            pass
        except Exception as e:
            print(f"資料處理錯誤: {e}")
    
    def calculate_attitude(self):
        """計算姿態角度"""
        ax, ay, az = self.accel
        
        # 除錯輸出原始加速度
        print(f"計算角度: 加速度=[{ax:.4f},{ay:.4f},{az:.4f}]")
        
        # 計算俯仰角和滾轉角
        self.pitch = math.atan2(-ax, math.sqrt(ay*ay + az*az)) * 180 / math.pi
        self.roll = math.atan2(ay, az) * 180 / math.pi
        
        # 使用陀螺儀積分計算偏航角
        self.yaw += self.gyro[2] * 0.02  # 20ms更新間隔
        
        # 限制角度範圍
        self.roll = self.roll % 360
        self.pitch = self.pitch % 360
        self.yaw = self.yaw % 360
        
        # 除錯輸出角度
        print(f"計算結果: Roll={self.roll:.1f}°, Pitch={self.pitch:.1f}°, Yaw={self.yaw:.1f}°")
    
    def draw_axes(self):
        """繪製三軸指標"""
        glPushMatrix()
        
        # 旋轉到當前姿態
        glRotatef(self.roll, 1, 0, 0)
        glRotatef(self.pitch, 0, 1, 0)
        glRotatef(self.yaw, 0, 0, 1)
        
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
        self.draw_arrow(2, 0, 0, 1, 0, 0)
        self.draw_arrow(0, 2, 0, 0, 1, 0)
        self.draw_arrow(0, 0, 2, 0, 0, 1)
        
        glPopMatrix()
    
    def draw_static_axes(self):
        """繪製靜止的三軸指標（等待BLE連接時）"""
        glPushMatrix()
        
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
        self.draw_arrow(2, 0, 0, 1, 0, 0)
        self.draw_arrow(0, 2, 0, 0, 1, 0)
        self.draw_arrow(0, 0, 2, 0, 0, 1)
        
        glPopMatrix()
    
    def draw_arrow(self, x, y, z, r, g, b):
        """繪製箭頭"""
        glColor3f(r, g, b)
        glBegin(GL_TRIANGLES)
        glVertex3f(x, y, z)
        glVertex3f(x-0.1, y-0.1, z-0.1)
        glVertex3f(x-0.1, y+0.1, z-0.1)
        glEnd()
    
    def draw_reference_grid(self):
        """繪製參考網格"""
        glColor3f(0.3, 0.3, 0.3)
        glBegin(GL_LINES)
        
        for i in range(-5, 6):
            glVertex3f(i, -5, 0)
            glVertex3f(i, 5, 0)
            glVertex3f(-5, i, 0)
            glVertex3f(5, i, 0)
        
        glEnd()
    
    def render(self):
        """渲染場景"""
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        
        # 設定模型視圖矩陣
        glMatrixMode(GL_MODELVIEW)
        glLoadIdentity()
        glTranslatef(0.0, 0.0, -5.0)
        
        # 繪製場景
        self.draw_reference_grid()
        
        if self.connected:
            # 有BLE連接時，繪製真實資料
            self.draw_axes()
        else:
            # 沒有BLE連接時，繪製靜止的軸
            self.draw_static_axes()
        
        pygame.display.flip()
        
        # 除錯：每100幀顯示一次渲染狀態
        if hasattr(self, 'render_count'):
            self.render_count += 1
        else:
            self.render_count = 0
            
        if self.render_count % 100 == 0:
            if self.connected:
                print(f"渲染真實資料... 角度: Roll={self.roll:.1f}°, Pitch={self.pitch:.1f}°, Yaw={self.yaw:.1f}°")
            else:
                print("等待BLE連接...")
    
    def handle_events(self):
        """處理事件"""
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self.running = False
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    self.running = False
                elif event.key == pygame.K_r:
                    self.roll = self.pitch = self.yaw = 0
                    print("姿態已重置")
                elif event.key == pygame.K_d:
                    self.debug_mode = not self.debug_mode
                    print(f"除錯模式: {'開啟' if self.debug_mode else '關閉'}")
                elif event.key == pygame.K_v:
                    print(f"當前電壓: {self.voltage:.2f}V")
                elif event.key == pygame.K_h:
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
    
    def connect_ble_async(self):
        """在背景線程中連接BLE"""
        def connect():
            try:
                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)
                
                devices = loop.run_until_complete(BleakScanner.discover(timeout=10.0))
                target_device = None
                
                for device in devices:
                    if device.name and self.device_name in device.name:
                        target_device = device
                        print(f"找到設備: {device.name} ({device.address})")
                        break
                
                if not target_device:
                    print(f"未找到設備: {self.device_name}")
                    return
                
                self.client = BleakClient(target_device.address)
                loop.run_until_complete(self.client.connect())
                print("BLE連接成功!")
                self.connected = True
                
                loop.run_until_complete(self.client.start_notify(self.characteristic_uuid, self.notification_handler))
                print("BLE通知已啟動")
                print("開始接收真實IMU資料...")
                
                # 保持連接並監控狀態
                while self.connected and self.running:
                    try:
                        # 檢查連接狀態
                        if not self.client.is_connected:
                            print("BLE連接已斷開!")
                            self.connected = False
                            break
                        time.sleep(0.1)
                    except Exception as e:
                        print(f"BLE連接監控錯誤: {e}")
                        self.connected = False
                        break
                
            except Exception as e:
                print(f"BLE連接失敗: {e}")
                print("程式將顯示靜止畫面")
        
        # 在背景線程中運行
        thread = threading.Thread(target=connect)
        thread.daemon = True
        thread.start()
        return thread
    
    def run(self):
        """主執行迴圈"""
        print("正在嘗試連接BLE設備...")
        self.connect_ble_async()
        
        print("BLE IMU 3D 視覺化程式啟動")
        print("等待BLE連接...")
        print("按 H 查看鍵盤控制說明")
        self.show_help()
        
        # 自動開啟除錯模式
        self.debug_mode = True
        print("除錯模式已自動開啟")
        
        clock = pygame.time.Clock()
        
        while self.running:
            # 處理事件
            self.handle_events()
            
            # 處理BLE資料
            if self.connected:
                self.process_ble_data()
            else:
                # 沒有BLE連接時，顯示靜止畫面
                pass
            
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
    

def main():
    """主函數"""
    visualizer = BLEIMUVisualizerSimple()
    visualizer.run()

if __name__ == "__main__":
    main()
