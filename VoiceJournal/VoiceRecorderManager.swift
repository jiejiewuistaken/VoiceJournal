//
//  VoiceRecorderManager.swift
//  VoiceJournal
//
//  Created by Wu Yanjie on 8/29/25.
//

import Foundation
import AVFoundation
import Speech

class VoiceRecorderManager: NSObject, ObservableObject {
    // 音频引擎，用于处理音频输入
    private var audioEngine: AVAudioEngine?
    // 语音识别请求，用于处理音频缓冲区的识别
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    // 语音识别任务，用于管理识别过程
    private var recognitionTask: SFSpeechRecognitionTask?
    // 语音识别器，特别指定为中文识别
    private let speechRecognizer: SFSpeechRecognizer?
    
    // 发布识别到的文本，以便SwiftUI视图可以监听并更新
    @Published var recognizedText = ""
    // 发布录音状态，以便SwiftUI视图可以监听并更新UI
    @Published var isRecording = false
    
    override init() {
        // 初始化语音识别器，设置为中文识别
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        super.init()
    }
    
    func requestPermissions() {
        // 请求语音识别权限
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("语音识别权限已授权")
                    // 用户授权后，再请求麦克风权限
                    self.requestMicrophonePermission()
                case .denied:
                    print("用户拒绝了语音识别权限")
                case .restricted:
                    print("语音识别权限受限")
                case .notDetermined:
                    print("语音识别权限未确定")
                @unknown default:
                    fatalError("未知的授权状态")
                }
            }
        }
    }

    private func requestMicrophonePermission() {
        // 获取共享的音频会话实例
        let audioSession = AVAudioSession.sharedInstance()
        // 请求麦克风权限
        audioSession.requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    print("麦克风权限已获取")
                } else {
                    print("麦克风权限被拒绝")
                }
            }
        }
    }
    
    func startRecording() throws {
        // 确保有可用的语音识别器
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw VoiceRecorderError.recognizerNotAvailable
        }
        
        // 停止之前的录音（如果有）
        stopRecording()
        
        // 配置音频会话
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // 创建识别请求
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw VoiceRecorderError.recognitionRequestFailed
        }
        
        // 设置识别请求的属性：实时返回部分结果
        recognitionRequest.shouldReportPartialResults = true
        
        // 配置音频引擎
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            throw VoiceRecorderError.audioEngineFailed
        }
        
        // 获取音频引擎的输入节点
        let inputNode = audioEngine.inputNode
        
        // 安装Tap以接收音频数据
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            recognitionRequest.append(buffer)
        }
        
        // 准备和启动音频引擎
        audioEngine.prepare()
        try audioEngine.start()
        
        // 更新录音状态
        isRecording = true
        
        // 创建识别任务
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                // 获取最佳转换结果并更新发布的文本
                let bestString = result.bestTranscription.formattedString
                self.recognizedText = bestString
            }
            
            // 检查是否有错误或是否最终结果
            if error != nil || result?.isFinal == true {
                self.stopRecording()
            }
        }
    }

    // 停止录音
    func stopRecording() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isRecording = false
    }
}


enum VoiceRecorderError: Error {
    case recognizerNotAvailable
    case recognitionRequestFailed
    case audioEngineFailed
}
