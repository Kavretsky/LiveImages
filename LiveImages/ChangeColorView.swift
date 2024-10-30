//
//  ChangeColorView.swift
//  LiveImages
//
//  Created by Nikolay Kavretsky on 30.10.2024.
//


import SwiftUI

struct ChangeColorView: View {
    @Binding var selectedColor: Color
    
    
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
        
        HStack(spacing: 16) {
            Image(.pallete)
                .renderingMode(.template)
                .foregroundStyle(showPalette ? .accent : .white)
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
    
    private var paletteView: some View {
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
        .padding(16)
        .overlayBase()
    }
    
    private let firstColors: [Color] = [.white, .coquelicot, .origianlBlack, .liveImagesBlue]
    
    private let paletteColors: [[Color]] = [
        [.lemonYellow, .bubblegumPink, .deepPeach, .brilliantLavender, .skyBlue],
        [.vibrantYellow, .blushPink, .royalOrange, .softPurple, .aqua],
        [.limeGreen, .hotPink, .safetyOrange, .violet, .vividSkyBlue],
        [.grassGreen, .deepPink, .lightCarminePink, .deepPurple, .frenchSkyBlue],
        [.forestGreen, .elegantRed, .coquelicot, .royalPurple, .liveImagesBlue]
        ]
}