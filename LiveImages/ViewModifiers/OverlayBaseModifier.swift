//
//  OverlayBaseModifier.swift
//  LiveImages
//
//  Created by Nikolay Kavretsky on 30.10.2024.
//

import SwiftUI

struct OverlayBaseModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(.black.opacity(0.10), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.black.opacity(0.14))
                            .blur(radius: 10)
                    )
                
            )
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    
}

extension View {
    func overlayBase() -> some View {
        modifier(OverlayBaseModifier())
    }
}
