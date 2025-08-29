//
//  VoiceJournalApp.swift
//  VoiceJournal
//
//  Created by Wu Yanjie on 8/29/25.
//

import SwiftUI

@main
struct VoiceJournalApp: App {
    @StateObject private var voiceRecorderManager = VoiceRecorderManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(voiceRecorderManager) // 注入环境
                .onAppear {
                    // 应用启动时请求权限
                    voiceRecorderManager.requestPermissions()
                }
        }
    }
}
