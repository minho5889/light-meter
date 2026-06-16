//
//  RootView.swift
//  LightMeter
//
//  App entry router. Presents the Regular (light-user) experience or the
//  Advanced (full original app) based on the persisted `AppMode`. Default is
//  Regular. Switching modes never destroys the other's code — `ContentView`
//  (the original app) is used as-is for Advanced mode.
//

import SwiftUI

struct RootView: View {
    @AppStorage(AppModeStorage.key) private var modeRaw: String = AppMode.regular.rawValue

    private var mode: AppMode { AppMode(rawValue: modeRaw) ?? .regular }

    var body: some View {
        switch mode {
        case .regular:
            RegularRootView()
        case .advanced:
            ContentView() // the original, untouched app
        }
    }
}
