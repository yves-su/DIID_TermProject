package com.example.smartbadmintonracket.filter;

import android.util.Log;
import java.util.LinkedList;
import java.util.Queue;

/**
 * 電壓濾波器（增強版）
 * 使用雙層濾波來大幅減少電壓跳動：
 * 1. 第一層：大視窗移動平均（100 個樣本，約 2 秒）
 * 2. 第二層：指數移動平均（EMA）進一步平滑
 * 提供非常穩定的電壓讀數
 */
public class VoltageFilter {
    private static final String TAG = "VoltageFilter";
    
    // 移動平均視窗大小（保留最近 N 個讀數）
    // 增加到 100 個樣本，在 50Hz 資料率下約 2 秒的資料
    private static final int WINDOW_SIZE = 100;
    
    // EMA 平滑係數（alpha），範圍 0.0 - 1.0
    // 較小的值（如 0.1）會產生更平滑但響應較慢的結果
    // 較大的值（如 0.3）響應較快但平滑效果較差
    private static final float EMA_ALPHA = 0.15f;  // 強平滑係數
    
    // 電壓讀數緩衝區（使用 Queue 實現移動平均）
    private Queue<Float> voltageBuffer;
    
    // 第一層濾波結果（移動平均）
    private float movingAverage = 0.0f;
    
    // 第二層濾波結果（指數移動平均）
    private float filteredVoltage = 0.0f;
    
    // EMA 是否已初始化（需要至少一個值來初始化）
    private boolean emaInitialized = false;
    
    // 累計總和（用於快速計算平均值）
    private float voltageSum = 0.0f;
    
    // 樣本計數
    private int sampleCount = 0;
    
    public VoltageFilter() {
        voltageBuffer = new LinkedList<>();
    }
    
    /**
     * 添加新的電壓讀數並返回濾波後的值
     * @param rawVoltage 原始電壓讀數
     * @return 濾波後的電壓值
     */
    public float addSample(float rawVoltage) {
        // 驗證輸入值是否在合理範圍內（2.5V - 4.5V）
        // 注意：如果電壓為0或異常低，可能是讀取失敗，記錄警告但允許更新（避免一直顯示舊值）
        if (rawVoltage < 0.1f || rawVoltage > 5.0f) {
            // 如果讀數異常，記錄警告
            if (rawVoltage == 0.0f) {
                Log.w(TAG, "電壓讀數為0，可能是讀取失敗，保留上次值: " + filteredVoltage + "V");
            } else {
                Log.w(TAG, "電壓讀數異常，跳過: " + rawVoltage + "V");
            }
            // 如果電壓為0，可能是讀取失敗，不更新濾波值
            // 如果電壓異常高，也不更新
            return filteredVoltage;
        }
        
        // ============================================================
        // 第一層濾波：移動平均（大視窗）
        // ============================================================
        // 將新讀數加入緩衝區
        voltageBuffer.offer(rawVoltage);
        voltageSum += rawVoltage;
        sampleCount++;
        
        // 如果緩衝區已滿，移除最舊的讀數
        if (voltageBuffer.size() > WINDOW_SIZE) {
            float removed = voltageBuffer.poll();
            voltageSum -= removed;
        }
        
        // 計算移動平均
        if (voltageBuffer.size() > 0) {
            movingAverage = voltageSum / voltageBuffer.size();
        } else {
            movingAverage = rawVoltage;
        }
        
        // ============================================================
        // 第二層濾波：指數移動平均（EMA）
        // ============================================================
        if (!emaInitialized) {
            // 初始化 EMA：使用第一個移動平均值
            filteredVoltage = movingAverage;
            emaInitialized = true;
        } else {
            // EMA 公式：EMA_new = alpha * value + (1 - alpha) * EMA_old
            filteredVoltage = EMA_ALPHA * movingAverage + (1.0f - EMA_ALPHA) * filteredVoltage;
        }
        
        // 記錄濾波效果（每 100 個樣本記錄一次，避免日誌過多）
        if (sampleCount % 100 == 0) {
            Log.d(TAG, String.format("電壓濾波: 原始=%.3fV, 移動平均=%.3fV, EMA=%.3fV, 緩衝區=%d",
                rawVoltage, movingAverage, filteredVoltage, voltageBuffer.size()));
        }
        
        return filteredVoltage;
    }
    
    /**
     * 取得當前濾波後的電壓值
     * @return 濾波後的電壓值
     */
    public float getFilteredVoltage() {
        return filteredVoltage;
    }
    
    /**
     * 重置濾波器（清除所有歷史資料）
     */
    public void reset() {
        voltageBuffer.clear();
        voltageSum = 0.0f;
        movingAverage = 0.0f;
        filteredVoltage = 0.0f;
        emaInitialized = false;
        sampleCount = 0;
        Log.d(TAG, "電壓濾波器已重置");
    }
    
    /**
     * 取得緩衝區大小（用於除錯）
     * @return 當前緩衝區中的樣本數
     */
    public int getBufferSize() {
        return voltageBuffer.size();
    }
    
    /**
     * 取得樣本計數（用於除錯）
     * @return 總共處理過的樣本數
     */
    public int getSampleCount() {
        return sampleCount;
    }
}

