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
    
    private var slider: some View {
        ZStack(alignment: .leading) {
            sliderBackground
            RoundedRectangle(cornerRadius: circleRadius)
                .fill(.white)
                .frame(width: circleRadius - 2, height: circleRadius - 2)
                .shadow(radius: 4)
                .offset(x: max(circleRadius / 2,min((lineWidth - range.lowerBound) / (range.upperBound - range.lowerBound) * (sliderWidth - circleRadius / 2), sliderWidth)) - circleRadius / 2)
                .overlay(alignment: .center) {
                    RoundedRectangle(cornerRadius: lineWidth)
                        .fill(.accent)
                        .frame(width: lineWidth, height: lineWidth)
                        .offset(x: max(circleRadius / 2,min((lineWidth - range.lowerBound) / (range.upperBound - range.lowerBound) * (sliderWidth - circleRadius / 2), sliderWidth)) - circleRadius / 2)
                }
            
            
        }
        .frame(height: 32)
        .gesture(
            DragGesture(minimumDistance: 0).simultaneously(with: LongPressGesture(minimumDuration: 0, maximumDistance: 0))
                .onChanged({ dragValue in
                    lineWidth = max(range.lowerBound, min((dragValue.first?.location.x ?? 0) / (sliderWidth - circleRadius) * (range.upperBound - range.lowerBound) , range.upperBound))
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
