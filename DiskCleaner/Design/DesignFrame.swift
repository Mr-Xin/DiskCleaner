//
//  DesignFrame.swift
//  DiskCleaner
//
//  The in-window shell: a `MeshGradientBackground` underneath an HStack of
//  sidebar + content. The OS provides the actual window chrome (title bar
//  with traffic lights), so `DesignFrame` is only responsible for what lives
//  inside the window's content view.
//

import SwiftUI

struct DesignFrame<SidebarContent: View, MainContent: View>: View {

    @ViewBuilder let sidebar: () -> SidebarContent
    @ViewBuilder let main: () -> MainContent

    var body: some View {
        HStack(spacing: 0) {
            sidebar()
            main()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(MeshGradientBackground())
        .preferredColorScheme(.dark)
    }
}
