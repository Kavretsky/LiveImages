//
//  LiveImagesApp.swift
//  LiveImages
//
//  Created by Nikolay Kavretsky on 28.10.2024.
//

import SwiftUI

@main
struct LiveImagesApp: App {
    @StateObject private var frameStore = FrameStore()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(frameStore)
        }
    }
}
