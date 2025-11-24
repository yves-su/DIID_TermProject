# 🌐 伺服器 API 規劃與設計指南

> **📌 當前實現狀態**：  
> ✅ **Android App 目前使用 Google Firebase Firestore** 直接上傳 IMU 資料至雲端資料庫  
> ✅ 資料上傳功能已實現並正常運作（批次上傳、錄製模式控制）  
> ❌ **AI 球路辨識功能尚未實現**  
> 
> **📋 本文檔內容**：  
> 本文檔主要描述**未來規劃的 HTTP API 伺服器**，用於實現即時 AI 球路辨識功能。  
> 當前 Firebase Firestore 用於**資料儲存**，未來 HTTP API 將用於**即時辨識**，兩者可並存使用。

## 📋 目錄

1. [當前實現狀況](#當前實現狀況)
2. [API 架構概述](#api-架構概述)
3. [技術選型建議](#技術選型建議)
4. [API 端點設計](#api-端點設計)
5. [資料格式規範](#資料格式規範)
6. [實作範例](#實作範例)
7. [部署建議](#部署建議)
8. [Android App 整合](#android-app-整合)

---

## 當前實現狀況

### ✅ 當前實現：Google Firebase Firestore（已實現）

**Android App 目前使用 Google Firebase Firestore 進行資料上傳**：

#### 實現細節
- **服務**：Google Firebase Firestore（NoSQL 雲端資料庫）
- **上傳方式**：批次上傳（每 5 秒或累積 100 筆資料）
- **錄製模式**：可切換錄製模式，僅在錄製模式下上傳
- **資料集合**：`imu_data` collection

#### 上傳資料欄位
```json
{
  "device_id": "SmartRacket_001",
  "session_id": "uuid-generated-session-id",
  "timestamp": 1234567890,
  "accelX": 0.123,
  "accelY": -0.456,
  "accelZ": 0.789,
  "gyroX": 1.234,
  "gyroY": -2.345,
  "gyroZ": 3.456,
  "voltage": 4.14,
  "received_at": 1234567890123,
  "calibrated": true,
  "uploaded_at": "Firestore ServerTimestamp"
}
```

#### 實現位置
- **主要類別**：`APP/android/app/src/main/java/com/example/smartbadmintonracket/firebase/FirebaseManager.java`
- **初始化**：在 `MainActivity.onCreate()` 中初始化
- **資料流程**：`BLEManager` → `IMUDataParser` → `CalibrationManager` → `FirebaseManager`

#### Firebase 設定
- **設定檔**：`APP/android/app/google-services.json`
- **依賴**：Firebase BOM 32.7.0 + Firebase Firestore
- **詳細設定步驟**：參考 `APP/android/Firebase_設定步驟.md`

### 未來規劃（HTTP API 伺服器）

本文檔描述的是未來規劃的 HTTP API 伺服器，用於：
- 即時 AI 球路辨識
- 計算殺球球速
- 返回辨識結果給 Android App

---

## API 架構概述

### 系統架構（未來規劃）

```
Android App → HTTP/HTTPS → 伺服器 API → AI 模型 → 辨識結果 → Android App
```

**與當前實現的關係**：
- ✅ **當前實現**：Android App → **Google Firebase Firestore**（資料上傳與儲存）
- ⏭️ **未來規劃**：Android App → HTTP API（即時 AI 辨識） + Firebase Firestore（資料儲存，繼續使用）

**說明**：Firebase Firestore 和 HTTP API 可以同時使用，Firebase 負責資料儲存，HTTP API 負責即時辨識。

### 核心功能（未來規劃）

1. **接收 IMU 資料**：接收 Android App 傳送的 40 筆資料窗口
2. **AI 模型推理**：使用訓練好的模型進行球路辨識
3. **計算球速**：針對殺球動作計算球速
4. **返回結果**：將辨識結果和球速返回給 Android App

---

## 技術選型建議

### 方案 1：Python Flask（推薦，適合初學者）

**優點**：
- 簡單易學
- 適合快速開發
- 容易整合 AI 模型（TensorFlow/PyTorch）
- 部署簡單

**缺點**：
- 性能較低（但對單一 App 使用足夠）

**適用場景**：開發階段、小規模使用

### 方案 2：Python FastAPI（推薦，現代化）

**優點**：
- 性能較好
- 自動生成 API 文件
- 類型檢查
- 現代化設計

**缺點**：
- 學習曲線稍陡

**適用場景**：正式環境、需要較好性能

### 方案 3：Node.js Express

**優點**：
- JavaScript/TypeScript 生態系統
- 適合全端開發

**缺點**：
- 整合 AI 模型較複雜

**適用場景**：如果您熟悉 JavaScript

### 方案 4：Google Cloud Functions / AWS Lambda（無伺服器）

**優點**：
- 無需管理伺服器
- 自動擴展
- 按使用量付費

**缺點**：
- 需要雲端服務帳號
- 設定較複雜

**適用場景**：正式環境、需要自動擴展

---

## API 端點設計

### 端點 1：健康檢查

**用途**：檢查伺服器是否正常運作

```
GET /api/v1/health
```

**回應**：
```json
{
  "status": "ok",
  "timestamp": 1234567890,
  "version": "1.0.0"
}
```

### 端點 2：球路辨識（主要端點）

**用途**：接收 IMU 資料，返回辨識結果

```
POST /api/v1/recognize
Content-Type: application/json
```

**請求格式**：
```json
{
  "device_id": "SmartRacket_001",
  "session_id": "session_20241123_001",
  "data_frame": [
    {
      "timestamp": 1234567890,
      "accelX": 0.123,
      "accelY": -0.456,
      "accelZ": 0.789,
      "gyroX": 12.34,
      "gyroY": -56.78,
      "gyroZ": 90.12
    },
    ... (共 40 筆資料)
  ]
}
```

**回應格式（成功）**：
```json
{
  "status": "success",
  "prediction": "smash",
  "confidence": 0.85,
  "speed": 120.5,
  "timestamp": 1234567890
}
```

**回應格式（錯誤）**：
```json
{
  "status": "error",
  "error_code": "INVALID_DATA",
  "message": "資料格式錯誤：需要 40 筆資料點"
}
```

### 端點 3：批次辨識（可選）

**用途**：一次處理多個資料窗口

```
POST /api/v1/recognize/batch
```

**請求格式**：
```json
{
  "device_id": "SmartRacket_001",
  "data_frames": [
    [...40筆資料...],
    [...40筆資料...],
    ...
  ]
}
```

**回應格式**：
```json
{
  "status": "success",
  "results": [
    {
      "prediction": "smash",
      "confidence": 0.85,
      "speed": 120.5
    },
    ...
  ]
}
```

---

## 資料格式規範

### 輸入資料驗證

伺服器應該驗證：

1. **資料數量**：必須恰好 40 筆
2. **資料格式**：每筆資料必須包含所有必要欄位
3. **數值範圍**（已更新，與 Android App 一致）：
   - 加速度：-20g ~ +20g（已放寬範圍）
   - 角速度：-2500 dps ~ +2500 dps（已放寬範圍）
4. **時間戳記**：必須是有效的數字

**注意**：Android App 目前使用的驗證範圍已放寬，伺服器端也應使用相同範圍以保持一致。

### 辨識結果格式

**球路類型**（`prediction`）：
- `smash` - 殺球
- `drive` - 抽球
- `toss` - 挑球
- `drop` - 吊球
- `other` - 其他

**信心度**（`confidence`）：
- 範圍：0.0 ~ 1.0
- 表示模型對辨識結果的信心

**球速**（`speed`）：
- 單位：km/h
- 僅在 `prediction == "smash"` 時有值
- 其他球路為 `null`

---

## 實作範例

### Python Flask 實作範例

#### 1. 專案結構

```
server/
├── app.py                 # 主應用程式
├── model/
│   ├── load_model.py     # 載入 AI 模型
│   └── predict.py        # 預測邏輯
├── utils/
│   ├── validate.py        # 資料驗證
│   └── calculate_speed.py # 球速計算
├── requirements.txt       # Python 依賴
└── README.md
```

#### 2. `requirements.txt`

```txt
flask==3.0.0
flask-cors==4.0.0
numpy==1.24.3
tensorflow==2.15.0
gunicorn==21.2.0
```

#### 3. `app.py`（主應用程式）

```python
from flask import Flask, request, jsonify
from flask_cors import CORS
from model.predict import predict_stroke
from utils.validate import validate_data_frame
from utils.calculate_speed import calculate_smash_speed

app = Flask(__name__)
CORS(app)  # 允許跨域請求（用於開發）

@app.route('/api/v1/health', methods=['GET'])
def health_check():
    """健康檢查端點"""
    return jsonify({
        'status': 'ok',
        'timestamp': int(time.time()),
        'version': '1.0.0'
    })

@app.route('/api/v1/recognize', methods=['POST'])
def recognize():
    """球路辨識端點"""
    try:
        # 取得請求資料
        data = request.get_json()
        
        # 驗證必要欄位
        if 'device_id' not in data or 'data_frame' not in data:
            return jsonify({
                'status': 'error',
                'error_code': 'MISSING_FIELDS',
                'message': '缺少必要欄位：device_id 或 data_frame'
            }), 400
        
        # 驗證資料格式
        data_frame = data['data_frame']
        validation_result = validate_data_frame(data_frame)
        if not validation_result['valid']:
            return jsonify({
                'status': 'error',
                'error_code': 'INVALID_DATA',
                'message': validation_result['message']
            }), 400
        
        # 進行辨識
        prediction_result = predict_stroke(data_frame)
        
        # 計算球速（僅殺球時）
        speed = None
        if prediction_result['prediction'] == 'smash':
            speed = calculate_smash_speed(data_frame)
        
        # 返回結果
        return jsonify({
            'status': 'success',
            'prediction': prediction_result['prediction'],
            'confidence': float(prediction_result['confidence']),
            'speed': float(speed) if speed else None,
            'timestamp': int(time.time())
        })
        
    except Exception as e:
        return jsonify({
            'status': 'error',
            'error_code': 'INTERNAL_ERROR',
            'message': str(e)
        }), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
```

#### 4. `utils/validate.py`（資料驗證）

```python
def validate_data_frame(data_frame):
    """驗證資料窗口格式"""
    # 檢查資料數量
    if len(data_frame) != 40:
        return {
            'valid': False,
            'message': f'資料數量錯誤：需要 40 筆，實際 {len(data_frame)} 筆'
        }
    
    # 檢查每筆資料格式
    required_fields = ['timestamp', 'accelX', 'accelY', 'accelZ', 
                      'gyroX', 'gyroY', 'gyroZ']
    
    for i, data_point in enumerate(data_frame):
        for field in required_fields:
            if field not in data_point:
                return {
                    'valid': False,
                    'message': f'第 {i+1} 筆資料缺少欄位：{field}'
                }
        
        # 檢查數值範圍（已更新，與 Android App 一致）
        if abs(data_point['accelX']) > 20 or \
           abs(data_point['accelY']) > 20 or \
           abs(data_point['accelZ']) > 20:
            return {
                'valid': False,
                'message': f'第 {i+1} 筆資料加速度超出範圍（±20g）'
            }
        
        if abs(data_point['gyroX']) > 2500 or \
           abs(data_point['gyroY']) > 2500 or \
           abs(data_point['gyroZ']) > 2500:
            return {
                'valid': False,
                'message': f'第 {i+1} 筆資料角速度超出範圍（±2500 dps）'
            }
    
    return {'valid': True}
```

#### 5. `model/predict.py`（AI 模型預測）

```python
import numpy as np
import tensorflow as tf

# 載入模型（在應用程式啟動時載入一次）
model = None

def load_model(model_path='model/badminton_model.tflite'):
    """載入 TensorFlow Lite 模型"""
    global model
    interpreter = tf.lite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()
    model = interpreter
    return model

def predict_stroke(data_frame):
    """預測球路類型"""
    global model
    
    if model is None:
        load_model()
    
    # 轉換為模型輸入格式 [1, 40, 6, 1]
    input_data = []
    for data_point in data_frame:
        input_data.append([
            data_point['accelX'],
            data_point['accelY'],
            data_point['accelZ'],
            data_point['gyroX'],
            data_point['gyroY'],
            data_point['gyroZ']
        ])
    
    input_array = np.array(input_data, dtype=np.float32)
    input_array = input_array.reshape(1, 40, 6, 1)
    
    # 進行預測
    input_details = model.get_input_details()
    output_details = model.get_output_details()
    
    model.set_tensor(input_details[0]['index'], input_array)
    model.invoke()
    
    output = model.get_tensor(output_details[0]['index'])
    
    # 解析結果
    class_names = ['drive', 'other', 'smash', 'toss', 'drop']
    predicted_index = np.argmax(output[0])
    confidence = float(output[0][predicted_index])
    prediction = class_names[predicted_index]
    
    return {
        'prediction': prediction,
        'confidence': confidence
    }
```

#### 6. `utils/calculate_speed.py`（球速計算）

```python
import numpy as np

def calculate_smash_speed(data_frame):
    """計算殺球球速"""
    # 找出加速度峰值
    max_accel = 0
    for data_point in data_frame:
        accel_magnitude = np.sqrt(
            data_point['accelX']**2 +
            data_point['accelY']**2 +
            data_point['accelZ']**2
        )
        if accel_magnitude > max_accel:
            max_accel = accel_magnitude
    
    # 簡化公式：speed = sqrt(accel_peak) * k
    # k 為經驗係數，需要根據實際測試調整
    k = 18.0  # 可調整
    speed = np.sqrt(max_accel) * k
    
    return speed
```

---

## 部署建議

### 本地開發

```bash
# 安裝依賴
pip install -r requirements.txt

# 執行伺服器
python app.py
```

伺服器將在 `http://localhost:5000` 運行

### 生產環境部署

#### 選項 1：使用 Gunicorn（推薦）

```bash
# 安裝 Gunicorn
pip install gunicorn

# 執行
gunicorn -w 4 -b 0.0.0.0:5000 app:app
```

#### 選項 2：使用 Docker

建立 `Dockerfile`：
```dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "app:app"]
```

#### 選項 3：部署到雲端服務

- **Google Cloud Run**：無伺服器容器服務
- **AWS Lambda**：無伺服器函數
- **Heroku**：簡單的 PaaS 平台
- **DigitalOcean**：VPS 服務

---

## Android App 整合

### 當前實現（Firebase Firestore）

**目前 Android App 使用 Firebase Firestore 直接上傳資料**：

```java
// FirebaseManager.java - 當前實現
public class FirebaseManager {
    public void addData(IMUData data) {
        if (!isRecordingMode) return;
        
        // 準備上傳資料
        Map<String, Object> docData = new HashMap<>();
        docData.put("device_id", "SmartRacket_001");
        docData.put("session_id", getCurrentSessionId());
        docData.put("timestamp", data.timestamp);
        docData.put("accelX", data.accelX);
        docData.put("accelY", data.accelY);
        docData.put("accelZ", data.accelZ);
        docData.put("gyroX", data.gyroX);
        docData.put("gyroY", data.gyroY);
        docData.put("gyroZ", data.gyroZ);
        docData.put("voltage", data.voltage);
        docData.put("received_at", data.receivedAt);
        docData.put("calibrated", true);
        docData.put("uploaded_at", FieldValue.serverTimestamp());
        
        // 上傳至 Firestore
        db.collection("imu_data").add(docData);
    }
}
```

**實現位置**：`APP/android/app/src/main/java/com/example/smartbadmintonracket/firebase/FirebaseManager.java`

### 未來規劃（HTTP API 整合）

**當 HTTP API 伺服器開發完成後，可以新增 `RecognitionManager.java`**：

```java
public class RecognitionManager {
    private static final String API_URL = "https://your-server.com/api/v1/recognize";
    private OkHttpClient client;
    
    public RecognitionManager() {
        client = new OkHttpClient.Builder()
            .connectTimeout(10, TimeUnit.SECONDS)
            .readTimeout(10, TimeUnit.SECONDS)
            .build();
    }
    
    public void requestRecognition(List<IMUData> dataFrame, 
                                   RecognitionCallback callback) {
        // 準備請求資料
        JSONObject request = new JSONObject();
        try {
            request.put("device_id", "SmartRacket_001");
            request.put("session_id", getCurrentSessionId());
            
            JSONArray dataArray = new JSONArray();
            for (IMUData data : dataFrame) {
                JSONObject dataPoint = new JSONObject();
                dataPoint.put("timestamp", data.timestamp);
                dataPoint.put("accelX", data.accelX);
                dataPoint.put("accelY", data.accelY);
                dataPoint.put("accelZ", data.accelZ);
                dataPoint.put("gyroX", data.gyroX);
                dataPoint.put("gyroY", data.gyroY);
                dataPoint.put("gyroZ", data.gyroZ);
                dataArray.put(dataPoint);
            }
            request.put("data_frame", dataArray);
        } catch (JSONException e) {
            callback.onError("資料格式錯誤");
            return;
        }
        
        // 發送請求
        RequestBody body = RequestBody.create(
            request.toString(),
            MediaType.parse("application/json")
        );
        Request httpRequest = new Request.Builder()
            .url(API_URL)
            .post(body)
            .build();
        
        client.newCall(httpRequest).enqueue(new Callback() {
            @Override
            public void onResponse(Call call, Response response) throws IOException {
                if (response.isSuccessful()) {
                    String responseBody = response.body().string();
                    RecognitionResult result = parseResponse(responseBody);
                    callback.onSuccess(result);
                } else {
                    callback.onError("伺服器錯誤: " + response.code());
                }
            }
            
            @Override
            public void onFailure(Call call, IOException e) {
                callback.onError("網路錯誤: " + e.getMessage());
            }
        });
    }
    
    private RecognitionResult parseResponse(String json) throws JSONException {
        JSONObject response = new JSONObject(json);
        RecognitionResult result = new RecognitionResult();
        result.prediction = response.getString("prediction");
        result.confidence = response.getDouble("confidence");
        if (!response.isNull("speed")) {
            result.speed = response.getDouble("speed");
        }
        return result;
    }
    
    public interface RecognitionCallback {
        void onSuccess(RecognitionResult result);
        void onError(String error);
    }
}
```

**注意**：此功能目前尚未實現，屬於未來規劃。

---

## 測試建議

### 1. 使用 Postman 測試

1. 建立新的 POST 請求
2. URL: `http://localhost:5000/api/v1/recognize`
3. Headers: `Content-Type: application/json`
4. Body: 使用上面提供的 JSON 格式
5. 發送請求並檢查回應

### 2. 使用 curl 測試

```bash
curl -X POST http://localhost:5000/api/v1/recognize \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": "SmartRacket_001",
    "data_frame": [...]
  }'
```

---

## 安全性建議

1. **使用 HTTPS**：生產環境必須使用 HTTPS
2. **API 金鑰**：可以加入 API Key 驗證
3. **速率限制**：防止濫用（例如：每分鐘最多 60 次請求）
4. **輸入驗證**：嚴格驗證所有輸入資料
5. **錯誤處理**：不要洩露敏感資訊

---

## 當前實現與未來規劃對照

### 已實現（Android App）

- ✅ **Firebase Firestore 資料上傳**：批次上傳 IMU 資料
- ✅ **錄製模式控制**：可切換錄製模式
- ✅ **資料校正**：所有上傳資料已應用零點校正
- ✅ **資料驗證**：驗證範圍已放寬（加速度 ±20g，角速度 ±2500 dps）

### 待實現（未來規劃）

- ⏭️ **HTTP API 伺服器**：用於即時 AI 辨識
- ⏭️ **AI 模型整合**：TensorFlow/PyTorch 模型推理
- ⏭️ **球路辨識**：5 種球路類型（smash, drive, toss, drop, other）
- ⏭️ **球速計算**：殺球球速計算
- ⏭️ **Android App 整合**：RecognitionManager 實現

## 下一步

1. ✅ 選擇技術棧（建議：Python Flask 或 FastAPI）
2. ⏭️ 建立專案結構
3. ⏭️ 實作 API 端點
4. ⏭️ 整合 AI 模型
5. ⏭️ 測試與部署
6. ⏭️ 整合到 Android App（新增 RecognitionManager）

---

**文件版本**: v1.1  
**最後更新**: 2025年11月  
**更新內容**：
- ✅ 添加當前實現狀況說明（Firebase Firestore）
- ✅ 更新資料驗證範圍（與 Android App 一致）
- ✅ 說明 HTTP API 為未來規劃
- ✅ 更新 Android App 整合章節，區分當前實現和未來規劃

