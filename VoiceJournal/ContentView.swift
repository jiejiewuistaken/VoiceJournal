//
//  ContentView.swift
//  VoiceJournal
//
//  Created by Wu Yanjie on 8/29/25.
//

import SwiftUI
import AVFoundation // 1. 导入音频框架

struct ContentView: View {
    @EnvironmentObject var voiceRecorderManager: VoiceRecorderManager
    // 2. 用于控制录音状态的变量
    @State private var isRecording = false
    // 3. 用于显示识别后的文字
    @State private var transcribedText = "长按按钮开始录音..."
    
    var body: some View {
        VStack {
            Spacer()
            
            // 4. 显示录音状态和转换的文字
            // 4. 显示录音状态和转换的文字
            Text(voiceRecorderManager.isRecording ? "录音中..." : "松开结束")
                .foregroundColor(.gray)
            Text(voiceRecorderManager.recognizedText) // 直接使用Manager中的文字
                .padding()
            
            Spacer()
            
            // 5. 核心：录音按钮
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(isRecording ? .red : .blue) // 录音时变红色
                .gesture(
                    // 6. 长按手势识别器
                    LongPressGesture(minimumDuration: 0.1)
                        .onEnded { _ in
                            // 7. 长按结束时（手指松开）停止录音
                            self.isRecording = false
                            self.stopRecording()
                        }
                        .simultaneously(
                            with: DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    // 8. 手指按下时开始录音（如果还没开始的话）
                                    if !self.isRecording {
                                        self.isRecording = true
                                        self.startRecording()
                                    }
                                }
                        )
                )
        }
        .padding()
    }
    private func startRecording() {
        print("开始录音")
        do {
            try voiceRecorderManager.startRecording()
        } catch {
            print("录音启动失败: \(error.localizedDescription)")
        }
    }

    private func stopRecording() {
        print("停止录音")
        voiceRecorderManager.stopRecording()
        // 你可以在这里保存 recognizedText 到你的数据模型
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
