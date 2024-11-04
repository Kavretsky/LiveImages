//
//  ChangeColorView.swift
//  LiveImages
//
//  Created by Nikolay Kavretsky on 30.10.2024.
//


import SwiftUI

struct ChangeColorView: View {
    @Binding var selectedColor: Color
    @Environment(\.self) var environment
    @Environment(\.displayScale) var displayScale
    var body: some View {
        VStack(spacing: 8) {
            if showPalette {
                paletteView
            }

            changeColorView
        }
    }
    
    @State private var showPalette = false
    
    private var changeColorView: some View {
        HStack(spacing: 17) {
            Image(.palette)
                .renderingMode(.template)
                .foregroundStyle(showPalette ? .accent : .buttonTint)
                .frame(width: 32, height: 32)
                .onTapGesture {
                    showPalette.toggle()
                }
            
            
            ForEach(firstColors, id: \.self) { color in
                Circle()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(color)
                    .padding(4)
                    .onTapGesture {
                        selectedColor = color
                    }
            }
        }
        .padding(16)
        .overlayBase()
    }
    @ViewBuilder
    private var paletteView: some View {
        VStack(spacing: 24) {
            SegmentControllerView(selected: $selectedSegment)
            if selectedSegment == .palette {
                Grid(alignment: .center, horizontalSpacing: 16, verticalSpacing: 16) {
                    ForEach(0..<5) { index in
                        GridRow {
                            ForEach(paletteColors[index], id: \.self) { color in
                                Circle()
                                    .frame(width: 28, height: 28)
                                    .foregroundStyle(color)
                                    .padding(4)
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                    }
                }
            } else {
                RGBColorPicker(color: $selectedColor, components: selectedColor.resolve(in: environment))
            }
        }
        .padding(16)
        .overlayBase()
    }
    
    @State private var selectedSegment: SegmentControllerSelection = .palette
    
    
    private let firstColors: [Color] = [.white, .coquelicot, .origianlBlack, .liveImagesBlue]
    
    private let paletteColors: [[Color]] = [
        [.lemonYellow, .bubblegumPink, .deepPeach, .brilliantLavender, .skyBlue],
        [.vibrantYellow, .blushPink, .royalOrange, .softPurple, .aqua],
        [.limeGreen, .hotPink, .safetyOrange, .violet, .vividSkyBlue],
        [.grassGreen, .deepPink, .lightCarminePink, .deepPurple, .frenchSkyBlue],
        [.forestGreen, .elegantRed, .coquelicot, .royalPurple, .liveImagesBlue]
    ]
}







