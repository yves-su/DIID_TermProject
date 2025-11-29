# 📚 GitHub 協同開發完整指南

> 本指南專為期末專題團隊協同開發設計，詳細說明各種開發情境下的 GitHub 操作流程

---

## 📋 目錄

- [📚 GitHub 協同開發完整指南](#-github-協同開發完整指南)
  - [📋 目錄](#-目錄)
  - [1. 快速開始 - 初次加入專案](#1-快速開始---初次加入專案)
    - [1.1 前置準備](#11-前置準備)
    - [1.2 克隆專案到本地](#12-克隆專案到本地)
    - [1.3 配置 Git 使用者資訊](#13-配置-git-使用者資訊)
    - [1.4 檢查專案狀態](#14-檢查專案狀態)
  - [2. 開發模式選擇](#2-開發模式選擇)
    - [2.1 模式一：獨立開發（不合併版本）](#21-模式一獨立開發不合併版本)
    - [2.2 模式二：協同開發（需要合併版本）](#22-模式二協同開發需要合併版本)
  - [3. 模式一：獨立開發流程](#3-模式一獨立開發流程)
    - [3.1 建立個人開發分支](#31-建立個人開發分支)
    - [3.2 在分支上進行開發](#32-在分支上進行開發)
    - [3.3 提交變更到個人分支](#33-提交變更到個人分支)
    - [3.4 同步主分支最新變更](#34-同步主分支最新變更)
    - [3.5 獨立分支的優缺點](#35-獨立分支的優缺點)
  - [4. 模式二：協同開發與合併流程](#4-模式二協同開發與合併流程)
    - [4.1 建立功能分支](#41-建立功能分支)
    - [4.2 在功能分支上開發](#42-在功能分支上開發)
    - [4.3 提交變更](#43-提交變更)
    - [4.4 推送分支到遠端](#44-推送分支到遠端)
    - [4.5 建立 Pull Request](#45-建立-pull-request)
    - [4.6 程式碼審查流程](#46-程式碼審查流程)
    - [4.7 合併 Pull Request](#47-合併-pull-request)
    - [4.8 清理已合併的分支](#48-清理已合併的分支)
  - [5. 接手他人已修改的程式](#5-接手他人已修改的程式)
    - [5.1 查看他人的變更](#51-查看他人的變更)
    - [5.2 拉取最新程式碼](#52-拉取最新程式碼)
    - [5.3 理解變更內容](#53-理解變更內容)
    - [5.4 在他人程式基礎上繼續開發](#54-在他人程式基礎上繼續開發)
    - [5.5 處理衝突情況](#55-處理衝突情況)
  - [6. 新增檔案的操作流程](#6-新增檔案的操作流程)
    - [6.1 新增一般程式檔案](#61-新增一般程式檔案)
    - [6.2 新增機器學習相關檔案](#62-新增機器學習相關檔案)
    - [6.3 新增大型檔案處理](#63-新增大型檔案處理)
    - [6.4 新增設定檔注意事項](#64-新增設定檔注意事項)
  - [7. 修改現有檔案的操作流程](#7-修改現有檔案的操作流程)
    - [7.1 修改前的準備](#71-修改前的準備)
    - [7.2 查看檔案歷史](#72-查看檔案歷史)
    - [7.3 進行修改](#73-進行修改)
    - [7.4 提交修改](#74-提交修改)
    - [7.5 修改多個檔案](#75-修改多個檔案)
  - [8. 機器學習相關開發流程](#8-機器學習相關開發流程)
    - [8.1 建立機器學習開發分支](#81-建立機器學習開發分支)
    - [8.2 新增訓練資料](#82-新增訓練資料)
    - [8.3 新增模型訓練腳本](#83-新增模型訓練腳本)
    - [8.4 新增模型檔案](#84-新增模型檔案)
    - [8.5 整合模型到主專案](#85-整合模型到主專案)
    - [8.6 模型版本管理](#86-模型版本管理)
  - [9. 處理衝突的詳細步驟](#9-處理衝突的詳細步驟)
    - [9.1 衝突發生的原因](#91-衝突發生的原因)
    - [9.2 衝突發生時的處理](#92-衝突發生時的處理)
    - [9.3 使用 Git 工具解決衝突](#93-使用-git-工具解決衝突)
    - [9.4 使用 VS Code 解決衝突](#94-使用-vs-code-解決衝突)
    - [9.5 衝突解決後的步驟](#95-衝突解決後的步驟)
  - [10. 常用 Git 指令速查](#10-常用-git-指令速查)
    - [10.1 狀態查詢指令](#101-狀態查詢指令)
    - [10.2 分支操作指令](#102-分支操作指令)
    - [10.3 提交操作指令](#103-提交操作指令)
    - [10.4 遠端操作指令](#104-遠端操作指令)
    - [10.5 歷史查詢指令](#105-歷史查詢指令)
  - [11. 常見問題與解決方案](#11-常見問題與解決方案)
    - [11.1 無法推送變更](#111-無法推送變更)
    - [11.2 忘記切換分支就開始開發](#112-忘記切換分支就開始開發)
    - [11.3 提交了錯誤的變更](#113-提交了錯誤的變更)
    - [11.4 想要撤銷本地變更](#114-想要撤銷本地變更)
    - [11.5 想要撤銷已推送的提交](#115-想要撤銷已推送的提交)
  - [12. 最佳實踐建議](#12-最佳實踐建議)
    - [12.1 提交訊息規範](#121-提交訊息規範)
    - [12.2 分支命名規範](#122-分支命名規範)
    - [12.3 開發頻率建議](#123-開發頻率建議)
    - [12.4 協同開發注意事項](#124-協同開發注意事項)
  - [📝 附錄：快速參考](#-附錄快速參考)
    - [日常開發流程（獨立分支）](#日常開發流程獨立分支)
    - [日常開發流程（協同開發）](#日常開發流程協同開發)
    - [緊急情況處理](#緊急情況處理)
  - [🎓 結語](#-結語)

---

## 1. 快速開始 - 初次加入專案

### 1.1 前置準備

在開始之前，請確保你已經完成以下準備：

1. **安裝 Git**
   - Windows: 下載並安裝 [Git for Windows](https://git-scm.com/download/win)
   - 安裝完成後，開啟命令提示字元或 PowerShell，輸入 `git --version` 確認安裝成功

2. **註冊 GitHub 帳號**
   - 如果還沒有 GitHub 帳號，請先到 [GitHub](https://github.com) 註冊

3. **取得專案存取權限**
   - 請專案發起人將你加入為 Collaborator（協作者）
   - 或請發起人提供專案的 GitHub 網址

4. **選擇開發工具**
   - **命令列**: Git Bash、PowerShell、命令提示字元
   - **圖形化工具**: GitHub Desktop、SourceTree、VS Code 內建 Git
   - **IDE 整合**: Android Studio、VS Code

### 1.2 克隆專案到本地

**步驟 1: 取得專案網址**
- 在 GitHub 專案頁面，點擊綠色的 "Code" 按鈕
- 複製 HTTPS 網址（例如：`https://github.com/username/DIID_TermProject.git`）

**步驟 2: 開啟終端機**
- Windows: 開啟 PowerShell 或 Git Bash
- 切換到你想要存放專案的目錄（例如：`cd D:\DevProjects`）

**步驟 3: 執行克隆指令**
```bash
git clone https://github.com/username/DIID_TermProject.git
```

**步驟 4: 進入專案目錄**
```bash
cd DIID_TermProject
```

**步驟 5: 確認克隆成功**
```bash
git status
```
應該會顯示 "On branch main" 或 "On branch master"，表示成功克隆

### 1.3 配置 Git 使用者資訊

**第一次使用 Git 時需要設定你的身份資訊：**

```bash
# 設定你的名字（使用中文或英文都可以）
git config --global user.name "你的名字"

# 設定你的 Email（使用 GitHub 註冊的 Email）
git config --global user.email "your.email@example.com"
```

**確認設定是否成功：**
```bash
git config --global user.name
git config --global user.email
```

**注意**: `--global` 表示這個設定會套用到你電腦上所有的 Git 專案。如果只想針對這個專案設定，可以去掉 `--global`。

### 1.4 檢查專案狀態

**查看目前所在的分支：**
```bash
git branch
```
前面有 `*` 號的就是你目前所在的分支

**查看專案的遠端倉庫設定：**
```bash
git remote -v
```
應該會顯示 `origin` 指向 GitHub 上的專案網址

**查看專案的提交歷史：**
```bash
git log --oneline
```
會顯示簡化版的提交歷史

---

## 2. 開發模式選擇

在開始開發之前，你需要決定使用哪種開發模式。這取決於你的工作方式和團隊協作需求。

### 2.1 模式一：獨立開發（不合併版本）

**適用情境：**
- 你負責的功能模組與其他人完全獨立
- 不需要與其他人的程式碼整合
- 想要保持自己的開發進度不受影響
- 期末只需要提交自己的部分

**特點：**
- 在個人分支上獨立開發
- 不需要建立 Pull Request
- 不會影響主分支（main/master）
- 可以隨時同步主分支的最新變更

### 2.2 模式二：協同開發（需要合併版本）

**適用情境：**
- 需要與其他人的程式碼整合
- 多人同時修改同一個檔案
- 需要程式碼審查
- 需要將功能合併到主分支供其他人使用

**特點：**
- 在功能分支上開發
- 需要建立 Pull Request
- 經過審查後合併到主分支
- 所有人都能使用合併後的功能

---

## 3. 模式一：獨立開發流程

### 3.1 建立個人開發分支

**步驟 1: 確保你在主分支上，且是最新版本**
```bash
# 切換到主分支
git checkout main
# 或
git checkout master

# 拉取最新的變更
git pull origin main
```

**步驟 2: 建立並切換到你的個人分支**
```bash
# 建立新分支並立即切換過去
git checkout -b your-name-dev
# 例如：git checkout -b john-dev
```

**步驟 3: 確認分支切換成功**
```bash
git branch
```
應該會看到 `* your-name-dev`，表示你現在在這個分支上

**步驟 4: 將分支推送到遠端（讓其他人知道你的分支）**
```bash
git push -u origin your-name-dev
```
`-u` 參數會設定上游分支，之後可以直接用 `git push` 而不需要指定分支名稱

### 3.2 在分支上進行開發

現在你可以在這個分支上自由開發了：

1. **修改現有檔案**
   - 使用你習慣的編輯器（VS Code、Android Studio 等）
   - 進行任何修改

2. **新增檔案**
   - 在專案目錄中新增任何需要的檔案
   - 例如：新增 Python 訓練腳本、新增 Java 類別等

3. **測試你的變更**
   - 確保程式可以正常編譯和執行
   - 測試功能是否正常運作

### 3.3 提交變更到個人分支

**步驟 1: 查看你做了哪些變更**
```bash
git status
```
會顯示：
- 已修改的檔案（紅色）
- 已新增但未追蹤的檔案（紅色）
- 已暫存的檔案（綠色）

**步驟 2: 將變更加入暫存區（Staging Area）**

**方式 A: 加入所有變更**
```bash
git add .
```

**方式 B: 選擇性加入特定檔案**
```bash
git add 檔案路徑
# 例如：
git add src/main/main.ino
git add APP/android/app/src/main/java/com/example/smartbadmintonracket/MainActivity.java
```

**步驟 3: 確認暫存的變更**
```bash
git status
```
現在應該看到暫存的檔案顯示為綠色

**步驟 4: 提交變更**
```bash
git commit -m "描述你的變更內容"
# 例如：
git commit -m "新增機器學習模型訓練腳本"
git commit -m "修正 BLE 連接穩定性問題"
git commit -m "新增電壓監控功能"
```

**步驟 5: 推送到遠端分支**
```bash
git push
```
如果是第一次推送這個分支，使用：
```bash
git push -u origin your-name-dev
```

### 3.4 同步主分支最新變更

即使你在獨立分支上開發，有時候還是需要同步主分支的最新變更（例如：其他人修復了重要的 bug，或新增了共用的工具函數）。

**步驟 1: 儲存你目前的變更（如果有未提交的變更）**
```bash
# 查看是否有未提交的變更
git status

# 如果有，先提交或暫存
git add .
git commit -m "進行中的變更"
```

**步驟 2: 切換到主分支**
```bash
git checkout main
```

**步驟 3: 拉取主分支的最新變更**
```bash
git pull origin main
```

**步驟 4: 切換回你的開發分支**
```bash
git checkout your-name-dev
```

**步驟 5: 將主分支的變更合併到你的分支**
```bash
git merge main
```

**如果出現衝突：**
- 參考 [第 9 章：處理衝突的詳細步驟](#9-處理衝突的詳細步驟)

**步驟 6: 推送合併後的變更**
```bash
git push
```

### 3.5 獨立分支的優缺點

**優點：**
- ✅ 開發過程不受其他人影響
- ✅ 可以隨時提交，不需要等待審查
- ✅ 適合獨立功能模組開發
- ✅ 不會意外破壞主分支

**缺點：**
- ❌ 其他人看不到你的進度（除非他們查看你的分支）
- ❌ 你的功能無法被其他人直接使用
- ❌ 如果長時間不更新，可能與主分支差異過大

---

## 4. 模式二：協同開發與合併流程

### 4.1 建立功能分支

**步驟 1: 確保主分支是最新的**
```bash
git checkout main
git pull origin main
```

**步驟 2: 建立功能分支**
```bash
# 分支命名建議：功能名稱-你的名字
git checkout -b feature/zero-point-calibration-john
# 或
git checkout -b ml-model-training-mary
# 或
git checkout -b fix/ble-connection-issue-tom
```

**分支命名規範：**
- `feature/` - 新功能
- `fix/` - 修復 bug
- `ml/` - 機器學習相關
- `docs/` - 文件相關

**步驟 3: 推送分支到遠端**
```bash
git push -u origin feature/zero-point-calibration-john
```

### 4.2 在功能分支上開發

開發流程與獨立分支相同：
1. 進行修改
2. 測試功能
3. 提交變更

**建議：**
- 經常提交小變更，而不是累積很多變更後一次提交
- 每次提交都寫清楚做了什麼
- 確保每次提交後程式都能正常編譯

### 4.3 提交變更

**步驟 1: 查看變更**
```bash
git status
```

**步驟 2: 加入變更到暫存區**
```bash
# 加入所有變更
git add .

# 或選擇性加入
git add 特定檔案路徑
```

**步驟 3: 提交變更**
```bash
git commit -m "清楚的變更描述"
```

**好的提交訊息範例：**
```
✅ "新增零點校正功能"
✅ "修正 BLE 連接時偶發性斷線問題"
✅ "新增 CNN 模型訓練腳本，支援 5 分類"
✅ "更新 Android App UI，改善圖表顯示效能"
```

**不好的提交訊息範例：**
```
❌ "更新"
❌ "修正 bug"
❌ "變更"
❌ "test"
```

### 4.4 推送分支到遠端

**推送變更到遠端分支：**
```bash
git push
```

如果是第一次推送這個分支：
```bash
git push -u origin feature/zero-point-calibration-john
```

**注意：** 推送後，其他人就可以在 GitHub 上看到你的分支和變更了。

### 4.5 建立 Pull Request

**步驟 1: 前往 GitHub 專案頁面**

**步驟 2: 點擊 "Pull requests" 標籤**

**步驟 3: 點擊綠色的 "New pull request" 按鈕**

**步驟 4: 選擇分支**
- **Base branch（目標分支）**: 選擇 `main` 或 `master`
- **Compare branch（來源分支）**: 選擇你的功能分支（例如：`feature/zero-point-calibration-john`）

**步驟 5: 填寫 Pull Request 資訊**
- **Title（標題）**: 簡潔描述這個 PR 要做什麼
  - 例如：「新增零點校正功能」
- **Description（描述）**: 詳細說明
  - 這個 PR 做了什麼
  - 為什麼需要這個變更
  - 如何測試
  - 相關的 issue 或討論

**Pull Request 描述範例：**
```markdown
## 變更內容
- 新增零點校正功能，允許使用者手動校正 IMU 感測器
- 校正資料會儲存在本地 SharedPreferences
- 所有後續資料會自動套用校正值

## 測試方式
1. 連接 SmartRacket 設備
2. 點擊「零點校正」按鈕
3. 將球拍靜止平置 10 秒
4. 確認校正值已儲存
5. 確認後續資料已套用校正

## 相關檔案
- `CalibrationManager.java`
- `CalibrationStorage.java`
- `MainActivity.java`
```

**步驟 6: 選擇審查者（Reviewers）**
- 點擊右側的 "Reviewers"
- 選擇專案發起人或相關的組員

**步驟 7: 點擊 "Create pull request"**

### 4.6 程式碼審查流程

**如果你是審查者：**

**步驟 1: 查看 Pull Request**
- 前往 GitHub 的 Pull Request 頁面
- 點擊 "Files changed" 查看所有變更

**步驟 2: 審查程式碼**
- 檢查程式碼邏輯是否正確
- 檢查是否有明顯的 bug
- 檢查程式碼風格是否一致
- 檢查是否有安全問題

**步驟 3: 留下評論**
- 點擊程式碼行號旁邊的 `+` 號
- 輸入你的評論
- 可以選擇：
  - **Comment**: 一般評論
  - **Approve**: 同意合併
  - **Request changes**: 需要修改

**步驟 4: 提交審查**
- 點擊 "Submit review"

**如果你是 PR 發起者：**

**步驟 1: 查看審查意見**
- 在 PR 頁面查看審查者的評論

**步驟 2: 回應評論**
- 點擊評論下方的 "Reply" 回應
- 說明你的想法或確認會修改

**步驟 3: 根據意見修改程式碼**
```bash
# 在你的功能分支上進行修改
git add .
git commit -m "根據審查意見修正：..."
git push
```

**步驟 4: 標記為已解決**
- 在 GitHub 上，如果問題已修正，可以標記評論為 "Resolved"

### 4.7 合併 Pull Request

**當審查通過後：**

**步驟 1: 確認所有審查意見都已處理**

**步驟 2: 確認沒有衝突**
- GitHub 會自動檢查是否有衝突
- 如果有衝突，需要先解決（參考第 9 章）

**步驟 3: 合併 PR**
- 在 PR 頁面，點擊綠色的 "Merge pull request" 按鈕
- 選擇合併方式：
  - **Create a merge commit**: 保留完整的提交歷史（推薦）
  - **Squash and merge**: 將所有提交合併成一個
  - **Rebase and merge**: 線性歷史（不推薦，除非團隊熟悉）

**步驟 4: 確認合併**
- 輸入確認訊息
- 點擊 "Confirm merge"

**步驟 5: 刪除已合併的分支（可選）**
- GitHub 會詢問是否要刪除來源分支
- 建議點擊 "Delete branch" 保持倉庫整潔

### 4.8 清理已合併的分支

**在本地刪除已合併的分支：**

**步驟 1: 切換到主分支**
```bash
git checkout main
```

**步驟 2: 拉取最新的變更（包含你剛才合併的 PR）**
```bash
git pull origin main
```

**步驟 3: 刪除本地分支**
```bash
git branch -d feature/zero-point-calibration-john
```

如果分支還沒合併，Git 會警告你。如果確定要強制刪除：
```bash
git branch -D feature/zero-point-calibration-john
```

**步驟 4: 刪除遠端分支（如果還沒自動刪除）**
```bash
git push origin --delete feature/zero-point-calibration-john
```

---

## 5. 接手他人已修改的程式

### 5.1 查看他人的變更

**方式一：在 GitHub 上查看**

**步驟 1: 前往專案頁面**

**步驟 2: 查看最近的提交**
- 點擊 "Commits" 查看所有提交記錄
- 點擊特定提交查看詳細變更

**步驟 3: 查看 Pull Request**
- 點擊 "Pull requests"
- 查看開啟中的或已合併的 PR
- 點擊 PR 查看變更內容和討論

**方式二：在本地查看**

**步驟 1: 拉取最新的變更**
```bash
git checkout main
git pull origin main
```

**步驟 2: 查看提交歷史**
```bash
# 簡化版歷史
git log --oneline

# 詳細歷史
git log

# 查看特定檔案的歷史
git log -- 檔案路徑
```

**步驟 3: 查看特定提交的變更**
```bash
# 查看最新提交的變更
git show

# 查看特定提交的變更
git show 提交的hash值
# 例如：git show abc1234
```

### 5.2 拉取最新程式碼

**步驟 1: 確認目前所在分支**
```bash
git branch
```

**步驟 2: 如果不在主分支，先切換過去**
```bash
git checkout main
```

**步驟 3: 拉取最新變更**
```bash
git pull origin main
```

**步驟 4: 確認拉取成功**
```bash
git log --oneline -5
```
應該會看到最新的提交記錄

### 5.3 理解變更內容

**查看特定檔案的變更：**

**步驟 1: 查看檔案的變更歷史**
```bash
git log -- 檔案路徑
# 例如：
git log -- APP/android/app/src/main/java/com/example/smartbadmintonracket/MainActivity.java
```

**步驟 2: 查看檔案在兩個版本之間的差異**
```bash
# 查看與前一個版本的差異
git diff HEAD~1 檔案路徑

# 查看與特定提交的差異
git diff 提交hash 檔案路徑
```

**步驟 3: 查看檔案的完整變更內容**
```bash
git show 提交hash:檔案路徑
```

**使用圖形化工具：**
- VS Code: 右鍵檔案 → "Open Timeline" 查看歷史
- GitHub Desktop: 點擊檔案查看變更
- Android Studio: VCS → Git → Show History

### 5.4 在他人程式基礎上繼續開發

**情境 A: 他人在主分支上提交了變更，你要繼續開發**

**步驟 1: 確保你的分支是最新的**
```bash
# 切換到你的開發分支
git checkout your-branch-name

# 拉取主分支的最新變更
git fetch origin main

# 將主分支的變更合併到你的分支
git merge origin/main
```

**情境 B: 他人在另一個分支上開發，你要基於他的分支繼續**

**步驟 1: 查看遠端分支**
```bash
git fetch origin
git branch -r
```

**步驟 2: 建立本地分支追蹤遠端分支**
```bash
git checkout -b local-branch-name origin/remote-branch-name
```

**步驟 3: 在這個分支上繼續開發**
```bash
# 進行你的修改
# ...
# 提交變更
git add .
git commit -m "基於他人的變更繼續開發：..."
git push
```

**情境 C: 你想要修改他人已經提交的程式**

**步驟 1: 拉取最新變更**
```bash
git checkout main
git pull origin main
```

**步驟 2: 建立新分支**
```bash
git checkout -b improve/feature-name
```

**步驟 3: 進行修改**
- 找到要修改的檔案
- 進行你的改進

**步驟 4: 提交變更**
```bash
git add .
git commit -m "改進：基於某人的實作，優化..."
git push -u origin improve/feature-name
```

**步驟 5: 建立 Pull Request**
- 參考 [4.5 建立 Pull Request](#45-建立-pull-request)

### 5.5 處理衝突情況

當你和他人都修改了同一個檔案的同一部分時，會發生衝突。詳細處理方式請參考 [第 9 章：處理衝突的詳細步驟](#9-處理衝突的詳細步驟)。

---

## 6. 新增檔案的操作流程

### 6.1 新增一般程式檔案

**步驟 1: 在專案中新增檔案**
- 使用你的編輯器或 IDE 新增檔案
- 例如：新增一個新的 Java 類別、Python 腳本等

**步驟 2: 確認檔案已建立**
```bash
git status
```
應該會看到新檔案顯示為紅色（未追蹤）

**步驟 3: 將檔案加入 Git 追蹤**
```bash
# 加入單一檔案
git add 檔案路徑

# 例如：
git add APP/android/app/src/main/java/com/example/smartbadmintonracket/NewClass.java
git add examples/train_model.py
```

**步驟 4: 確認檔案已加入暫存區**
```bash
git status
```
現在應該看到檔案顯示為綠色（已暫存）

**步驟 5: 提交檔案**
```bash
git commit -m "新增：檔案功能描述"
# 例如：
git commit -m "新增：機器學習資料預處理工具"
git commit -m "新增：BLE 連接狀態監控類別"
```

**步驟 6: 推送到遠端**
```bash
git push
```

### 6.2 新增機器學習相關檔案

機器學習相關檔案通常包括：
- 訓練腳本（Python）
- 資料處理腳本
- 模型檔案（.tflite, .h5, .pkl 等）
- 訓練資料集
- 配置文件

**步驟 1: 建立適當的目錄結構**

建議的目錄結構：
```
DIID_TermProject/
├── ml/
│   ├── training/
│   │   ├── train_model.py          # 訓練腳本
│   │   ├── preprocess_data.py      # 資料預處理
│   │   └── evaluate_model.py       # 模型評估
│   ├── models/
│   │   ├── badminton_model_v1.tflite
│   │   └── badminton_model_v2.tflite
│   ├── data/
│   │   ├── raw/                     # 原始資料
│   │   └── processed/               # 處理後的資料
│   └── config/
│       └── model_config.json
```

**步驟 2: 新增訓練腳本**
```bash
# 建立目錄（如果不存在）
mkdir -p ml/training

# 新增檔案（使用你的編輯器）
# 然後加入 Git
git add ml/training/train_model.py
git commit -m "新增：CNN 模型訓練腳本，支援 5 分類"
git push
```

**步驟 3: 新增模型檔案**

**注意：大型模型檔案（> 50MB）的處理**

GitHub 對單一檔案有 100MB 的限制。如果模型檔案很大：

**選項 A: 使用 Git LFS（Large File Storage）**
```bash
# 安裝 Git LFS（如果還沒安裝）
# Windows: 下載 https://git-lfs.github.com/

# 初始化 Git LFS
git lfs install

# 追蹤特定檔案類型
git lfs track "*.tflite"
git lfs track "*.h5"
git lfs track "*.pkl"

# 提交 .gitattributes 檔案
git add .gitattributes
git commit -m "設定 Git LFS 追蹤模型檔案"

# 加入模型檔案
git add ml/models/badminton_model.tflite
git commit -m "新增：訓練完成的 CNN 模型"
git push
```

**選項 B: 不上傳模型檔案，只上傳訓練腳本**
- 將模型檔案加入 `.gitignore`
- 在 README 中說明如何訓練模型
- 或使用雲端儲存（Google Drive、Dropbox）分享模型

**選項 C: 使用壓縮**
```bash
# 壓縮模型檔案
zip badminton_model.zip badminton_model.tflite

# 加入壓縮檔
git add badminton_model.zip
git commit -m "新增：CNN 模型（壓縮檔）"
git push
```

**步驟 4: 新增訓練資料**

**注意：資料集檔案通常很大**

建議做法：
1. **小資料集（< 10MB）**: 可以直接加入 Git
2. **中等資料集（10-50MB）**: 使用 Git LFS
3. **大型資料集（> 50MB）**: 
   - 加入 `.gitignore`
   - 使用雲端儲存分享
   - 或在 README 中說明資料來源

**如果使用 Git LFS：**
```bash
git lfs track "*.xlsx"
git lfs track "*.csv"
git add .gitattributes
git commit -m "設定 Git LFS 追蹤資料集檔案"

git add ml/data/training_data.xlsx
git commit -m "新增：訓練資料集（已標記的 IMU 資料）"
git push
```

### 6.3 新增大型檔案處理

**檢查檔案大小：**
```bash
# Windows PowerShell
Get-Item 檔案路徑 | Select-Object Length

# Git Bash
ls -lh 檔案路徑
```

**如果檔案超過 50MB，建議：**

1. **使用 Git LFS**（推薦）
2. **分割檔案**
3. **使用外部儲存**（Google Drive、OneDrive）
4. **只上傳範例資料**，完整資料另外分享

### 6.4 新增設定檔注意事項

**敏感資訊處理：**

設定檔可能包含敏感資訊（API Key、密碼等），**絕對不要**直接提交到 Git！

**步驟 1: 建立範例設定檔**
```bash
# 建立 config.example.json
{
  "api_key": "YOUR_API_KEY_HERE",
  "database_url": "YOUR_DATABASE_URL"
}
```

**步驟 2: 將範例檔加入 Git**
```bash
git add config.example.json
git commit -m "新增：設定檔範例"
```

**步驟 3: 將實際設定檔加入 .gitignore**
```bash
# 編輯 .gitignore，加入：
config.json
google-services.json  # 如果包含敏感資訊
*.secret
```

**步驟 4: 提交 .gitignore 變更**
```bash
git add .gitignore
git commit -m "更新：忽略敏感設定檔"
git push
```

**注意：** 如果已經不小心提交了敏感檔案：
1. 立即移除檔案中的敏感資訊
2. 參考 [11.5 想要撤銷已推送的提交](#115-想要撤銷已推送的提交)
3. 考慮重新產生所有 API Key 和密碼

---

## 7. 修改現有檔案的操作流程

### 7.1 修改前的準備

**步驟 1: 確認你在正確的分支上**
```bash
git branch
```

**步驟 2: 確保分支是最新的**
```bash
git pull
```

**步驟 3: 查看要修改的檔案**
```bash
# 查看檔案內容
cat 檔案路徑

# 或使用編輯器開啟
code 檔案路徑  # VS Code
```

### 7.2 查看檔案歷史

**了解檔案的變更歷史有助於理解程式碼：**

**步驟 1: 查看檔案的提交歷史**
```bash
git log -- 檔案路徑
# 例如：
git log -- APP/android/app/src/main/java/com/example/smartbadmintonracket/MainActivity.java
```

**步驟 2: 查看檔案的詳細變更**
```bash
# 查看特定提交對這個檔案的變更
git show 提交hash -- 檔案路徑
```

**步驟 3: 比較兩個版本之間的差異**
```bash
# 與前一個版本比較
git diff HEAD~1 檔案路徑

# 與特定提交比較
git diff 提交hash 檔案路徑

# 與另一個分支比較
git diff 分支名稱 檔案路徑
```

### 7.3 進行修改

**步驟 1: 使用編輯器修改檔案**
- 進行你需要的修改
- 確保程式碼可以正常編譯
- 測試功能是否正常

**步驟 2: 查看修改內容**
```bash
git status
```
會顯示已修改的檔案

**步驟 3: 查看具體修改了什麼**
```bash
# 查看所有修改
git diff

# 查看特定檔案的修改
git diff 檔案路徑
```

### 7.4 提交修改

**步驟 1: 將修改加入暫存區**
```bash
# 加入所有修改
git add .

# 或選擇性加入
git add 檔案路徑
```

**步驟 2: 確認暫存的變更**
```bash
git status
```

**步驟 3: 提交修改**
```bash
git commit -m "修改：清楚的描述做了什麼變更"
# 例如：
git commit -m "修改：優化 BLE 資料接收緩衝區大小"
git commit -m "修改：修正零點校正計算邏輯"
git commit -m "修改：改善圖表更新效能，減少記憶體使用"
```

**步驟 4: 推送到遠端**
```bash
git push
```

### 7.5 修改多個檔案

**情境：你需要修改多個相關檔案**

**方式 A: 一次提交所有相關變更**
```bash
# 修改多個檔案後
git add 檔案1 檔案2 檔案3
git commit -m "修改：實作新功能，涉及多個檔案"
git push
```

**方式 B: 分別提交不同類型的變更**
```bash
# 先提交功能相關的修改
git add MainActivity.java BLEManager.java
git commit -m "修改：新增零點校正功能"

# 再提交 UI 相關的修改
git add activity_main.xml
git commit -m "修改：更新零點校正按鈕樣式"

# 最後推送
git push
```

**建議：** 如果變更都是為了同一個功能，建議一起提交。如果變更目的不同，建議分開提交，這樣歷史記錄更清楚。

---

## 8. 機器學習相關開發流程

### 8.1 建立機器學習開發分支

**步驟 1: 從主分支建立 ML 分支**
```bash
git checkout main
git pull origin main
git checkout -b ml/model-training-v1
```

**步驟 2: 推送到遠端**
```bash
git push -u origin ml/model-training-v1
```

### 8.2 新增訓練資料

**步驟 1: 建立資料目錄**
```bash
mkdir -p ml/data/raw
mkdir -p ml/data/processed
```

**步驟 2: 準備資料檔案**
- 將 Excel 或 CSV 資料放到 `ml/data/raw/`
- 確保資料格式符合需求

**步驟 3: 決定是否加入 Git**

**小資料集（< 10MB）：**
```bash
git add ml/data/raw/training_data.xlsx
git commit -m "新增：IMU 訓練資料集（已標記）"
```

**大資料集（> 10MB）：**
- 使用 Git LFS（參考 6.2）
- 或加入 `.gitignore`，使用雲端分享

**步驟 4: 推送到遠端**
```bash
git push
```

### 8.3 新增模型訓練腳本

**步驟 1: 建立訓練腳本**
```bash
# 在 ml/training/ 目錄下建立
# train_badminton_model.py
```

**步驟 2: 開發訓練腳本**
- 實作資料載入
- 實作資料預處理
- 實作模型架構
- 實作訓練流程
- 實作模型儲存

**步驟 3: 測試腳本**
```bash
# 執行訓練腳本
python ml/training/train_badminton_model.py
```

**步驟 4: 加入 Git**
```bash
git add ml/training/train_badminton_model.py
git commit -m "新增：CNN 模型訓練腳本，支援 5 分類（Smash, Drive, Toss, Drop, Other）"
git push
```

### 8.4 新增模型檔案

**步驟 1: 執行訓練產生模型**
```bash
python ml/training/train_badminton_model.py
# 產生 ml/models/badminton_model_v1.tflite
```

**步驟 2: 檢查模型檔案大小**
```bash
ls -lh ml/models/badminton_model_v1.tflite
```

**步驟 3: 根據大小決定處理方式**

**小模型（< 10MB）：**
```bash
git add ml/models/badminton_model_v1.tflite
git commit -m "新增：訓練完成的 CNN 模型 v1.0"
git push
```

**大模型（> 10MB）：**
- 使用 Git LFS（參考 6.2）
- 或壓縮後上傳
- 或使用雲端分享

### 8.5 整合模型到主專案

**步驟 1: 將模型檔案複製到 Android 專案**
```bash
# 複製模型到 Android assets 目錄
cp ml/models/badminton_model_v1.tflite APP/android/app/src/main/assets/
```

**步驟 2: 修改 Android 程式碼以載入模型**
- 修改相關的 Java 檔案
- 實作模型載入和推理邏輯

**步驟 3: 測試整合**
- 編譯 Android App
- 測試模型是否能正常載入和執行

**步驟 4: 提交變更**
```bash
git add APP/android/app/src/main/assets/badminton_model_v1.tflite
git add APP/android/app/src/main/java/com/example/smartbadmintonracket/ModelInference.java
git commit -m "整合：將 CNN 模型整合到 Android App"
git push
```

**步驟 5: 建立 Pull Request**
- 參考 [4.5 建立 Pull Request](#45-建立-pull-request)
- 在描述中說明：
  - 模型架構
  - 訓練資料來源
  - 模型準確率
  - 如何使用模型

### 8.6 模型版本管理

**建議的版本管理方式：**

**方式 A: 使用版本號命名**
```
ml/models/
├── badminton_model_v1.0.tflite  # 初始版本
├── badminton_model_v1.1.tflite  # 小改進
├── badminton_model_v2.0.tflite  # 重大更新
└── badminton_model_latest.tflite  # 最新版本（符號連結）
```

**方式 B: 使用 Git Tag**
```bash
# 訓練完成後，建立 tag
git tag -a v1.0 -m "CNN 模型 v1.0：5 分類，準確率 85%"
git push origin v1.0

# 之後可以隨時回到這個版本
git checkout v1.0
```

**方式 C: 使用分支管理**
```
ml/
├── models/
│   ├── v1/
│   │   └── badminton_model.tflite
│   ├── v2/
│   │   └── badminton_model.tflite
│   └── latest -> v2/  # 符號連結指向最新版本
```

---

## 9. 處理衝突的詳細步驟

### 9.1 衝突發生的原因

衝突發生在以下情況：
1. 你和他人同時修改了同一個檔案的同一部分
2. 你嘗試合併分支時，兩個分支都修改了相同的地方
3. 你拉取遠端變更時，本地和遠端都修改了相同的地方

### 9.2 衝突發生時的處理

**當你執行 `git merge` 或 `git pull` 時，如果出現衝突：**

```
Auto-merging MainActivity.java
CONFLICT (content): Merge conflict in MainActivity.java
Automatic merge failed; fix conflicts and then commit the result.
```

**步驟 1: 不要驚慌！這是正常情況**

**步驟 2: 查看哪些檔案有衝突**
```bash
git status
```
會顯示：
```
Unmerged paths:
  (use "git add <file>..." to mark as resolved)
        both modified:   MainActivity.java
```

### 9.3 使用 Git 工具解決衝突

**步驟 1: 開啟有衝突的檔案**

你會看到衝突標記：
```java
<<<<<<< HEAD
// 你的變更
public void yourMethod() {
    // 你的程式碼
}
=======
// 他人的變更
public void theirMethod() {
    // 他人的程式碼
}
>>>>>>> branch-name
```

**衝突標記說明：**
- `<<<<<<< HEAD`: 你目前的變更（HEAD 指向你當前的版本）
- `=======`: 分隔線
- `>>>>>>> branch-name`: 要合併進來的變更（來自其他分支或遠端）

**步驟 2: 決定如何解決衝突**

**選項 A: 保留你的變更**
```java
// 刪除衝突標記，只保留你的程式碼
public void yourMethod() {
    // 你的程式碼
}
```

**選項 B: 保留他人的變更**
```java
// 刪除衝突標記，只保留他人的程式碼
public void theirMethod() {
    // 他人的程式碼
}
```

**選項 C: 合併兩者的變更**
```java
// 保留兩邊的程式碼，但要確保邏輯正確
public void yourMethod() {
    // 你的程式碼
}

public void theirMethod() {
    // 他人的程式碼
}
```

**選項 D: 完全重寫**
```java
// 根據兩邊的變更，寫出更好的版本
public void improvedMethod() {
    // 結合兩邊優點的程式碼
}
```

**步驟 3: 刪除所有衝突標記**
- 確保檔案中沒有留下 `<<<<<<<`、`=======`、`>>>>>>>` 這些標記

**步驟 4: 測試修改後的程式碼**
- 確保程式可以正常編譯
- 測試功能是否正常

**步驟 5: 標記衝突已解決**
```bash
# 將解決後的檔案加入暫存區
git add 檔案路徑
# 例如：
git add MainActivity.java
```

**步驟 6: 完成合併**
```bash
git commit -m "解決合併衝突：整合兩邊的變更"
```

**步驟 7: 推送到遠端**
```bash
git push
```

### 9.4 使用 VS Code 解決衝突

**VS Code 提供視覺化的衝突解決工具：**

**步驟 1: 開啟有衝突的檔案**
- VS Code 會自動偵測衝突
- 衝突區域會用不同顏色標示

**步驟 2: 使用 VS Code 的衝突解決工具**
- 在衝突區域上方，你會看到三個選項：
  - **Accept Current Change**: 保留你的變更
  - **Accept Incoming Change**: 保留他人的變更
  - **Accept Both Changes**: 保留兩邊的變更

**步驟 3: 點擊選擇的選項**
- VS Code 會自動移除衝突標記並套用你的選擇

**步驟 4: 手動調整（如果需要）**
- 如果選擇 "Accept Both Changes"，可能需要手動調整程式碼邏輯

**步驟 5: 儲存檔案**

**步驟 6: 標記為已解決**
```bash
git add 檔案路徑
git commit -m "解決合併衝突"
git push
```

### 9.5 衝突解決後的步驟

**步驟 1: 確認所有衝突都已解決**
```bash
git status
```
應該不會再顯示 "Unmerged paths"

**步驟 2: 測試程式**
- 編譯程式
- 執行測試
- 確保功能正常

**步驟 3: 提交合併**
```bash
git commit -m "解決合併衝突：描述如何解決的"
```

**步驟 4: 推送到遠端**
```bash
git push
```

**如果推送失敗：**
- 可能遠端有新的變更
- 先拉取：`git pull`
- 如果有新的衝突，重複解決流程
- 然後再推送：`git push`

---

## 10. 常用 Git 指令速查

### 10.1 狀態查詢指令

```bash
# 查看目前狀態
git status

# 查看簡化狀態
git status -s

# 查看目前所在分支
git branch

# 查看所有分支（包含遠端）
git branch -a

# 查看提交歷史（簡化版）
git log --oneline

# 查看提交歷史（詳細版）
git log

# 查看提交歷史（圖形化）
git log --graph --oneline --all
```

### 10.2 分支操作指令

```bash
# 建立新分支
git branch 分支名稱

# 建立並切換到新分支
git checkout -b 分支名稱

# 切換分支
git checkout 分支名稱

# 刪除本地分支
git branch -d 分支名稱

# 強制刪除本地分支
git branch -D 分支名稱

# 刪除遠端分支
git push origin --delete 分支名稱

# 查看遠端分支
git branch -r
```

### 10.3 提交操作指令

```bash
# 查看變更內容
git diff

# 查看特定檔案的變更
git diff 檔案路徑

# 加入所有變更到暫存區
git add .

# 加入特定檔案
git add 檔案路徑

# 加入特定目錄
git add 目錄路徑/

# 提交變更
git commit -m "提交訊息"

# 修改最後一次提交的訊息
git commit --amend -m "新的提交訊息"

# 將變更加入最後一次提交
git add .
git commit --amend --no-edit
```

### 10.4 遠端操作指令

```bash
# 查看遠端倉庫
git remote -v

# 拉取遠端變更
git pull

# 拉取特定分支
git pull origin 分支名稱

# 推送變更到遠端
git push

# 推送特定分支
git push origin 分支名稱

# 推送並設定上游分支
git push -u origin 分支名稱

# 取得遠端變更（不合併）
git fetch

# 取得所有遠端分支
git fetch --all
```

### 10.5 歷史查詢指令

```bash
# 查看提交歷史
git log

# 查看特定檔案的歷史
git log -- 檔案路徑

# 查看特定提交的變更
git show 提交hash

# 查看兩個提交之間的差異
git diff 提交hash1 提交hash2

# 查看與前一個版本的差異
git diff HEAD~1

# 查看特定檔案的變更歷史
git log -p -- 檔案路徑
```

---

## 11. 常見問題與解決方案

### 11.1 無法推送變更

**問題：** 執行 `git push` 時出現錯誤

**可能原因和解決方法：**

**原因 A: 遠端有新的變更，你沒有先拉取**
```bash
# 解決方法：先拉取再推送
git pull origin 分支名稱
# 如果有衝突，解決衝突後
git push
```

**原因 B: 沒有設定上游分支**
```bash
# 解決方法：設定上游分支
git push -u origin 分支名稱
```

**原因 C: 沒有權限**
- 確認你已被加入為 Collaborator
- 或確認你有寫入權限

**原因 D: 認證問題**
```bash
# 重新設定認證
git config --global credential.helper store
# 下次推送時輸入帳號密碼，之後會自動記住
```

### 11.2 忘記切換分支就開始開發

**問題：** 在主分支上直接開始開發，忘記建立新分支

**解決方法：**

**步驟 1: 不要提交！先查看變更**
```bash
git status
```

**步驟 2: 暫存目前的變更**
```bash
git stash
# 或
git stash save "描述變更內容"
```

**步驟 3: 建立新分支**
```bash
git checkout -b 新分支名稱
```

**步驟 4: 恢復變更**
```bash
git stash pop
```

**步驟 5: 繼續開發並提交**
```bash
git add .
git commit -m "你的變更"
git push -u origin 新分支名稱
```

### 11.3 提交了錯誤的變更

**情境 A: 提交訊息寫錯了（還沒推送）**
```bash
# 修改最後一次提交的訊息
git commit --amend -m "正確的提交訊息"
```

**情境 B: 漏了某些檔案（還沒推送）**
```bash
# 加入遺漏的檔案
git add 遺漏的檔案
# 加入最後一次提交
git commit --amend --no-edit
```

**情境 C: 想要撤銷最後一次提交（還沒推送）**
```bash
# 保留變更，只撤銷提交
git reset --soft HEAD~1

# 或完全撤銷變更
git reset --hard HEAD~1
```

**情境 D: 已經推送了錯誤的提交**
- 參考 [11.5 想要撤銷已推送的提交](#115-想要撤銷已推送的提交)

### 11.4 想要撤銷本地變更

**情境 A: 還沒加入暫存區（還沒 git add）**
```bash
# 撤銷單一檔案的變更
git checkout -- 檔案路徑

# 撤銷所有變更
git checkout -- .
```

**情境 B: 已加入暫存區但還沒提交**
```bash
# 從暫存區移除，但保留檔案變更
git reset HEAD 檔案路徑

# 然後撤銷檔案變更
git checkout -- 檔案路徑
```

**情境 C: 想要暫時儲存變更，稍後再處理**
```bash
# 暫存變更
git stash

# 查看暫存的變更
git stash list

# 恢復暫存的變更
git stash pop

# 或恢復但不刪除暫存
git stash apply
```

### 11.5 想要撤銷已推送的提交

**⚠️ 警告：撤銷已推送的提交會影響其他人，請謹慎使用！**

**情境 A: 最後一次提交是錯誤的，想要完全移除**

**方法 1: 使用 revert（推薦，安全）**
```bash
# 建立一個新的提交來撤銷之前的變更
git revert HEAD
git push
```

**方法 2: 使用 reset（危險，會改寫歷史）**
```bash
# 只在個人分支上使用，不要在主分支上使用！
git reset --hard HEAD~1
git push --force
```

**情境 B: 想要修改已推送的提交訊息**

**⚠️ 只有在個人分支上才這樣做！**
```bash
git commit --amend -m "新的提交訊息"
git push --force
```

**情境 C: 想要回到特定的提交**

```bash
# 查看提交歷史，找到目標提交的 hash
git log --oneline

# 回到那個提交（保留變更）
git reset --soft 提交hash

# 或完全回到那個提交（丟棄變更）
git reset --hard 提交hash

# 強制推送（危險！）
git push --force
```

**重要提醒：**
- `--force` 會強制覆蓋遠端歷史，可能影響其他人
- 如果已經有其他人基於你的提交繼續開發，不要使用 `--force`
- 在主分支上，永遠不要使用 `--force`
- 如果必須使用，先通知所有組員

---

## 12. 最佳實踐建議

### 12.1 提交訊息規範

**好的提交訊息格式：**

```
類型：簡短描述（50字以內）

詳細說明（可選）：
- 為什麼做這個變更
- 如何實作的
- 相關的 issue 或討論
```

**類型範例：**
- `新增：` - 新功能
- `修改：` - 修改現有功能
- `修正：` - 修復 bug
- `優化：` - 效能優化
- `重構：` - 程式碼重構
- `文件：` - 文件更新
- `測試：` - 測試相關
- `樣式：` - UI/樣式變更

**範例：**
```
新增：零點校正功能

- 實作手動觸發校正流程
- 校正資料儲存在 SharedPreferences
- 所有後續資料自動套用校正值
```

### 12.2 分支命名規範

**建議的命名格式：**

```
類型/功能描述-你的名字
```

**類型：**
- `feature/` - 新功能
- `fix/` - 修復 bug
- `ml/` - 機器學習相關
- `docs/` - 文件相關
- `refactor/` - 重構
- `test/` - 測試

**範例：**
```
feature/zero-point-calibration-john
fix/ble-connection-issue-mary
ml/model-training-v2-tom
docs/update-readme-alice
```

### 12.3 開發頻率建議

**建議的開發節奏：**

1. **每天開始工作前：**
   ```bash
   git checkout main
   git pull origin main
   git checkout your-branch
   git merge main  # 同步最新變更
   ```

2. **完成一個小功能後：**
   ```bash
   git add .
   git commit -m "清楚的描述"
   git push
   ```

3. **每天結束工作前：**
   ```bash
   # 確保所有變更都已提交和推送
   git status
   git push
   ```

4. **每週：**
   - 檢查是否有需要合併的 PR
   - 清理已合併的分支
   - 同步主分支的最新變更

### 12.4 協同開發注意事項

**溝通優先：**
- 開始重大變更前，先與組員討論
- 如果會影響其他人的程式碼，先通知
- 遇到問題時，及時尋求幫助

**小步提交：**
- 不要累積大量變更後才提交
- 每個提交應該是一個完整的小功能或修復
- 這樣出問題時容易回溯

**測試後再提交：**
- 確保程式可以正常編譯
- 測試基本功能是否正常
- 不要提交無法編譯的程式碼

**及時同步：**
- 經常拉取主分支的最新變更
- 避免與其他人的變更差異過大
- 發現衝突時及時解決

**善用 Pull Request：**
- 即使是小變更，也建議建立 PR
- PR 描述要清楚說明變更內容
- 積極參與程式碼審查

**保護主分支：**
- 不要直接在主分支上開發
- 重要變更必須經過 PR 和審查
- 主分支應該保持穩定可用的狀態

---

## 📝 附錄：快速參考

### 日常開發流程（獨立分支）

```bash
# 1. 開始工作
git checkout main
git pull origin main
git checkout your-branch
git merge main

# 2. 進行開發
# ... 修改檔案 ...

# 3. 提交變更
git add .
git commit -m "描述變更"
git push

# 4. 結束工作
git status  # 確認沒有未提交的變更
```

### 日常開發流程（協同開發）

```bash
# 1. 開始工作
git checkout main
git pull origin main
git checkout feature/your-feature
git merge main

# 2. 進行開發
# ... 修改檔案 ...

# 3. 提交變更
git add .
git commit -m "描述變更"
git push

# 4. 建立/更新 Pull Request
# 前往 GitHub 建立或更新 PR

# 5. 等待審查和合併
```

### 緊急情況處理

**忘記切換分支就開始開發：**
```bash
git stash
git checkout -b correct-branch
git stash pop
```

**提交了錯誤的變更（還沒推送）：**
```bash
git commit --amend -m "正確的訊息"
```

**想要撤銷本地變更：**
```bash
git checkout -- 檔案路徑
```

**遇到衝突：**
```bash
# 1. 查看衝突檔案
git status

# 2. 手動解決衝突

# 3. 標記已解決
git add 檔案路徑

# 4. 完成合併
git commit
```

---

## 🎓 結語

這份指南涵蓋了 GitHub 協同開發的各種情境。記住：

1. **不要害怕犯錯** - Git 可以撤銷大部分操作
2. **經常提交** - 小步提交比大改動安全
3. **及時同步** - 避免與其他人差異過大
4. **善用分支** - 保護主分支的穩定性
5. **積極溝通** - 遇到問題及時討論

祝開發順利！🏸

---

**最後更新：** 2024年
**維護者：** DIID Term Project Team

