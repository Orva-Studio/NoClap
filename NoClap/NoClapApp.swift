//
//  NoClapApp.swift
//  NoClap
//
//  Created by Richard Oliver Bray on 29/11/2025.
//

import SwiftUI

@main
struct NoClapApp: App {
    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
        }
        .defaultSize(width: 500, height: 700)
        .windowResizability(.contentSize)
        
        MenuBarExtra("No Clap", systemImage: "hand.raised.fill") {
            MenuBarView()
        }
    }
}

struct MenuBarView: View {
    @Environment(\.openWindow) var openWindow
    
    var body: some View {
        VStack(spacing: 8) {
            // Add version number
            // Check for updates
            Button("No Clap is Enabled") {
            }
            Divider()
            Button("Settings...") {
                openWindow(id: "main")
            }
            Button("About") {
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(8)
    }
}
