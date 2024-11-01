//
//  RGBColorPicker.swift
//  LiveImages
//
//  Created by Nikolay Kavretsky on 01.11.2024.
//


import SwiftUI

struct RGBColorPicker: View {
    @Binding var color: Color
    let components: Color.Resolved
    
    init(color: Binding<Color>, components: Color.Resolved) {
        _color = color
        self.components = components
        _redSliderOffset = .init(wrappedValue: CGFloat(components.red) * (sliderWidth - circleRadius))
        _greenSliderOffset = .init(wrappedValue: CGFloat(components.green) * (sliderWidth -  circleRadius))
        _blueSliderOffset = .init(wrappedValue: CGFloat(components.blue) * (sliderWidth -  circleRadius))
    }
    
    @State private var redSliderOffset: CGFloat
    @State private var redSliderOffsetChange: CGFloat = 0
    
    @State private var greenSliderOffset: CGFloat
    @State private var greenSliderOffsetChange: CGFloat = 0
    
    @State private var blueSliderOffset: CGFloat
    @State private var blueSliderOffsetChange: CGFloat = 0
    
    private let sliderWidth: CGFloat = 245
    private let circleRadius: CGFloat = 32
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            HStack {
                Text("Red".uppercased())
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int((components.red * 255).rounded(.toNearestOrEven)))")
                    .font(.headline)
            }
            colorSlider(gradient: redGradient, sliderOffset: $redSliderOffset, sliderOffsetChange: $redSliderOffsetChange, colorComponent: components.red) { redColor in
                Color(red: redColor, green: Double(components.green), blue: Double(components.blue))
            }
            
            HStack {
                Text("Green".uppercased())
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int((components.green * 255).rounded(.toNearestOrEven)))")
                    .font(.headline)
            }
                
            colorSlider(gradient: greenGradient, sliderOffset: $greenSliderOffset, sliderOffsetChange: $greenSliderOffsetChange, colorComponent: components.green) { greenColor in
                Color(red: Double(components.red), green: greenColor, blue: Double(components.blue))
            }
            
            HStack {
                Text("Blue".uppercased())
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int((components.blue * 255).rounded(.toNearestOrEven)))")
                    .font(.headline)
            }
            colorSlider(gradient: blueGradient, sliderOffset: $blueSliderOffset, sliderOffsetChange: $blueSliderOffsetChange, colorComponent: components.blue) { blueColor in
                Color(red: Double(components.red), green: Double(components.green), blue: blueColor)
            }
        }
        
        
        
    }
    
    private var redGradient: [Color] {
        [
            Color(red: 0, green: Double(components.green), blue: Double(components.blue)),
            Color(red: 1, green: Double(components.green), blue: Double(components.blue)),
        ]
    }
    
    private var blueGradient: [Color] {
        [
            Color(red: Double(components.red), green: Double(components.green), blue: 0),
            Color(red: Double(components.red), green: Double(components.green), blue: 1),
        ]
    }
    
    private var greenGradient: [Color] {
        [
            Color(red: Double(components.red), green: 0, blue: Double(components.blue)),
            Color(red: Double(components.red), green: 1, blue: Double(components.blue)),
        ]
    }
    
    func colorSlider(gradient: [Color], sliderOffset: Binding<CGFloat>, sliderOffsetChange: Binding<CGFloat>, colorComponent: Float, colorCreator: @escaping (CGFloat) -> Color) -> some View {
        
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: circleRadius)
                .foregroundStyle(.linearGradient(.init(colors: gradient), startPoint: .leading, endPoint: .trailing))
                .frame(height: circleRadius)
                .frame(width: sliderWidth)
            RoundedRectangle(cornerRadius: circleRadius)
                .fill(color)
                .stroke(.white, lineWidth: 2)
                .foregroundStyle(color)
                .shadow(radius: 1)
                .offset(x: CGFloat(colorComponent) * (sliderWidth - circleRadius))
                .frame(width: circleRadius - 2, height: circleRadius - 2)
            
        }
        .frame(height: 32)
        .gesture(
            DragGesture(minimumDistance: 0).simultaneously(with: LongPressGesture(minimumDuration: 0, maximumDistance: 0))
                .onChanged({ dragValue in
                    sliderOffsetChange.wrappedValue = dragValue.first?.translation.width ?? 0
                    color = colorCreator(max(0, min(sliderOffsetChange.wrappedValue + sliderOffset.wrappedValue, sliderWidth - circleRadius)) / (sliderWidth - circleRadius))
                })
                .onEnded({ value in
                    sliderOffset.wrappedValue = max(0, min(sliderOffset.wrappedValue + sliderOffsetChange.wrappedValue, sliderWidth - circleRadius))
                    sliderOffsetChange.wrappedValue = 0
                })
        )
        
        
    }
}
