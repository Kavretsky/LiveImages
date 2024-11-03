//
//  ShapePicker.swift
//  LiveImages
//
//  Created by Nikolay Kavretsky on 02.11.2024.
//

import SwiftUI

struct ShapePicker: View {
    @Binding var selectedShape: DrawableShape?
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(DrawableShape.allCases, id: \.self) { shape in
                shape.image
                    .renderingMode(.template)
                    .frame(width: 32 , height: 32)
                    .onTapGesture {
                        self.selectedShape = shape
                    }
            }
        }
        .padding(16)
        .overlayBase()
    }
}
