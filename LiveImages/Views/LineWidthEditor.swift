//
//  LineWidthEditor.swift
//  LiveImages
//
//  Created by Nikolay Kavretsky on 01.11.2024.
//

import SwiftUI

struct LineWidthEditor: View {
    private let range: ClosedRange<CGFloat> = 1...30
    @Binding var lineWidth: CGFloat
    
    init(lineWidth: Binding<CGFloat>) {
        _lineWidth = lineWidth
        _sliderOffset = .init(wrappedValue: (lineWidth.wrappedValue - range.lowerBound) / (range.upperBound - range.lowerBound) * (sliderWidth - circleRadius))
    }
    
    private let circleRadius: CGFloat = 32
    private let sliderWidth: CGFloat = 245
    
    var body: some View {
        
        VStack {
            HStack {
                Text("Line width".uppercased())
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(lineWidth))")
                    .font(.headline)
            }
            slider
        }
    }
    
    @State private var sliderOffsetChange:CGFloat = 0
    @State private var sliderOffset: CGFloat
    
    private var slider: some View {
        ZStack(alignment: .leading) {
            sliderBackground
            RoundedRectangle(cornerRadius: circleRadius)
                .fill(.white)
                .frame(width: circleRadius - 2, height: circleRadius - 2)
                .shadow(radius: 4)
                .offset(x: ((lineWidth - range.lowerBound) / (range.upperBound - range.lowerBound) * (sliderWidth - circleRadius)))
                .overlay(alignment: .center) {
                    RoundedRectangle(cornerRadius: lineWidth)
                        .fill(.accent)
                        .frame(width: lineWidth, height: lineWidth)
                        .offset(x: ((lineWidth - range.lowerBound) / (range.upperBound - range.lowerBound) * (sliderWidth - circleRadius)))
                }
            
            
        }
        .frame(height: 32)
        .gesture(
            DragGesture(minimumDistance: 0).simultaneously(with: LongPressGesture(minimumDuration: 0, maximumDistance: 0))
                .onChanged({ dragValue in
                    sliderOffsetChange = dragValue.first?.translation.width ?? 0
                    lineWidth = max(range.lowerBound, min((sliderOffset + sliderOffsetChange) / (sliderWidth - circleRadius) * (range.upperBound - range.lowerBound + 1) , range.upperBound))
                })
                .onEnded({ value in
                    sliderOffset = max(range.lowerBound, min(sliderOffset + sliderOffsetChange, sliderWidth - circleRadius))
                    sliderOffsetChange = 0
                })
        )
    }
    
    private var sliderBackground: some View {
        RoundedRectangle(cornerRadius: circleRadius)
            .foregroundStyle(.white)
            .frame(height: circleRadius)
            .frame(width: sliderWidth)
    }
    
}
