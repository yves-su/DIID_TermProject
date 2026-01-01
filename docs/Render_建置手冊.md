# Render 伺服器部署指南

本手冊將協助您將 FastAPI 伺服器 (`server/` 目錄下的程式) 部署至 [Render.com](https://render.com) 雲端平台。

## 1. 事前準備

確保您的 GitHub Repository 中包含以下關鍵檔案（且位於正確路徑）：
*   `server/main.py`: 主程式
*   `server/requirements.txt`: 套件清單 (需包含 `fastapi`, `uvicorn`, `websockets`, `tensorflow`, `numpy` 等)
*   `server/Procfile`: 告訴 Render 如何啟動程式 (內容: `web: uvicorn main:app --host 0.0.0.0 --port $PORT`)
*   `server/badminton_model_v2.h5`: 您的 AI 模型檔 (必須上傳到 GitHub，Render 才能讀取)

## 2. 建立 Web Service

1.  登入 [Render Dashboard](https://dashboard.render.com/)。
2.  點擊右上角的 **"New +"** 按鈕，選擇 **"Web Service"**。
3.  在列表中找到您的 GitHub 專案 `DIID_TermProject`，點擊 **"Connect"**。

## 3. 設定參數 (Configuration)

請依照以下建議填寫部署設定：

*   **Name**: 自訂名稱 (例如 `badminton-server`)
*   **Language**: `Python 3`
*   **Branch**: `main` (或您開發中的分支)
*   **Region**: `Singapore` (新加坡，離台灣較近，延遲較低)
*   **Root Directory**: `server`
    *   **重要！** 因為您的程式在專案的 `server` 資料夾內，這裡一定要填 `server`，否則 Render 會找不到檔案。
*   **Build Command**: `pip install -r requirements.txt` (預設值)
*   **Start Command**: `uvicorn main:app --host 0.0.0.0 --port $PORT`
    *   *註：如果您有上傳正確的 `Procfile`，Render 通常會自動偵測；若無偵測到，請手動填入此行。*
*   **Instance Type**: `Free` (免費版) 或 `Starter`
    *   *注意：Free 版本在閒置一段時間後會休眠 (Spin down)，下次連線需要等待約 50 秒啟動。若要即時反應，建議升級為付費版。*

## 4. 環境變數 & 進階設定 (Optional)

通常本專案不需要額外設定環境變數，除非您之後有加入資料庫連線字串或 API Key。

*   點擊 **"Create Web Service"** 按鈕開始部署。

## 5. 等待部署完成

*   Render 會開始 Clone 程式碼、安裝 TensorFlow 等套件 (因為 TensorFlow 較大，Build 可能需要 3~5 分鐘)。
*   當您在 Log 中看到 `Application startup complete` 字樣，且上方狀態變為綠色的 **Live**，表示部署成功。

## 6. 取得連線網址

1.  在 Render 服務頁面左上角，可以找到您的伺服器網址，例如：
    `https://badminton-server.onrender.com`
2.  **設定手機 App**：
    *   打開 App 到設定頁面。
    *   在 Server URL 欄位填入：`badminton-server.onrender.com` (不需要加 `https://` 或 `ws://`，App 若有防呆會自動補)。
    *   點擊測試連線，若顯示 "Detection succeeded"，即代表手機與雲端 AI 已成功對接。

## 常見問題排除

*   **部署失敗 (Build Failed)**
    *   檢查 Log 錯誤訊息。
    *   常見原因是 `requirements.txt` 缺少套件，或 Python 版本不相容 (Render 預設 Python 3.7+，通常沒問題)。
    *   檢查 `H5` 模型檔是否真的有 push 上去 GitHub (如果 .gitignore 把它擋住了，Render 會讀不到模型而報錯)。

*   **連線逾時**
    *   如果是免費版 (Free Tier)，記得第一次連線要等它「叫醒」伺服器。
