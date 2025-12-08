import logging
import random
import json
import time
from typing import List, Optional
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from pydantic import BaseModel

# 配置日誌
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("BadmintonServer")

app = FastAPI(title="Badminton Swing Recognition Server")

# --- 資料模型 (Data Models) ---

class IMUFrame(BaseModel):
    ts: float  # Absolute timestamp
    acc: List[float]  # [x, y, z]
    gyro: List[float] # [x, y, z]

class SwingRequest(BaseModel):
    client_id: str
    data: List[IMUFrame]

# --- 模擬 AI 模型 (Mock AI Model) ---
# 未來這裡會替換成真實的 PyTorch 模型載入與推論

# --- AI 模型封裝 (Model Wrappers) ---

class SwingClassifier:
    def __init__(self):
        # 這裡負責載入「動作分類模型」 (由同學 A 訓練)
        # self.model = torch.load("c:/models/classifier_v1.pth")
        self.classes = ["Smash", "Drive", "Toss", "Drop", "Other"]
        logger.info("Loaded Classifier Model (Mock)")

    def predict(self, frames: List[IMUFrame]):
        # 1. 將 frames 轉成 Tensor
        # 2. 推論
        # 3. 回傳類別與信心度
        
        # (Mock 行為)
        predicted_class = random.choices(
            self.classes, weights=[0.3, 0.2, 0.2, 0.2, 0.1], k=1
        )[0]
        confidence = random.uniform(0.7, 0.99)
        return predicted_class, confidence

class SpeedRegressor:
    def __init__(self):
        # 這裡負責載入「球速預測模型」 (由同學 B 訓練)
        # self.model = torch.load("c:/models/speed_regressor_v1.pth")
        logger.info("Loaded Speed Model (Mock)")

    def predict(self, frames: List[IMUFrame]):
        # 這個模型專注於：已知是殺球的情況下，預測球速
        # 輸入資料相同 (IMU Window)，但輸出的意義不同
        
        # (Mock 行為)
        max_acc = 0
        for f in frames:
            mag = (f.acc[0]**2 + f.acc[1]**2 + f.acc[2]**2) ** 0.5
            if mag > max_acc:
                max_acc = mag
        
        speed = max_acc * random.uniform(8, 12) 
        return round(speed, 1)

# 初始化：伺服器啟動時，一次載入兩個模型到記憶體
try:
    classifier = SwingClassifier()
    speed_model = SpeedRegressor()
except Exception as e:
    logger.error(f"Failed to load models: {e}")
    raise e

# --- WebSocket Endpoint ---

@app.websocket("/ws/predict")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    logger.info("Client connected")
    
    try:
        while True:
            # 1. 接收 JSON 資料
            data = await websocket.receive_text()
            payload = json.loads(data)
            
            # 簡單驗證資料結構
            # 注意: Pydantic 驗證可能會慢，生產環境可視情況優化
            client_id = payload.get("client_id", "unknown")
            raw_frames = payload.get("data", [])
            
            if not raw_frames:
                continue

            logger.info(f"Received {len(raw_frames)} frames from {client_id}")

            # 轉換為物件 (方便後續處理)
            frames = [
                IMUFrame(ts=f["ts"], acc=f["acc"], gyro=f["gyro"]) 
                for f in raw_frames
            ]

            # 2. 執行推論 (Inference)
            action_type, confidence = classifier.predict(frames)
            
            # 3. 商業邏輯 (Business Logic)
            # 修正 (2025-12-08): 
            # - 任何辨識出的動作 (Drive, Drop, Toss...) 都要顯示在 APP。
            # - 只有 "Smash" 動作額外計算並顯示「球速」。
            
            response = {
                "timestamp": frames[-1].ts,
                "type": action_type,
                "confidence": round(confidence, 2),
                "speed": None,    # 預設不顯示球速
                "display": False, # 預設不更新 (除非信心足夠)
                "message": ""
            }

            # 信心門檻 (可調整)
            if confidence > 0.6:
                response["display"] = True
                
                if action_type == "Smash":
                    # 只有殺球才執行球速模型
                    speed = speed_model.predict(frames)
                    response["speed"] = speed
                    response["message"] = f"Smash! {speed} km/h"
                    logger.info(f"SMASH: {speed} km/h")
                else:
                    # 其他球路顯示名稱，但沒有球速
                    response["message"] = f"{action_type}"
                    logger.info(f"Detected: {action_type}")
            else:
                response["display"] = False
                response["message"] = "Low confidence"

            # 4. 回傳結果
            await websocket.send_text(json.dumps(response))
            
    except WebSocketDisconnect:
        logger.info("Client disconnected")
    except Exception as e:
        logger.error(f"Error: {e}")
        await websocket.close()

@app.get("/")
def health_check():
    return {"status": "ok", "version": "v3.0"}

if __name__ == "__main__":
    import uvicorn
    # 啟動伺服器: host="0.0.0.0" 讓區網內的手機可以連線
    uvicorn.run(app, host="0.0.0.0", port=8000)
