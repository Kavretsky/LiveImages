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

    }
    
    private let sliderWidth: CGFloat = 245
    private let circleRadius: CGFloat = 32
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            
            VStack(spacing: 13) {
                HStack {
                    Text("Red".uppercased())
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int((components.red * 255).rounded(.toNearestOrEven)))")
                        .font(.headline)
                }
                colorSlider(gradient: redGradient, colorComponent: components.red) { redColor in
                    Color(red: redColor, green: Double(components.green), blue: Double(components.blue))
                }
            }
            VStack(spacing: 13) {
                HStack {
                    Text("Green".uppercased())
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int((components.green * 255).rounded(.toNearestOrEven)))")
                        .font(.headline)
                }
                
                colorSlider(gradient: greenGradient, colorComponent: components.green) { greenColor in
                    Color(red: Double(components.red), green: greenColor, blue: Double(components.blue))
                }
            }
            VStack(spacing: 13) {
                HStack {
                    Text("Blue".uppercased())
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int((components.blue * 255).rounded(.toNearestOrEven)))")
                        .font(.headline)
                }
                colorSlider(gradient: blueGradient, colorComponent: components.blue) { blueColor in
                    Color(red: Double(components.red), green: Double(components.green), blue: blueColor)
                }
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
    
    func colorSlider(gradient: [Color], colorComponent: Float, colorCreator: @escaping (CGFloat) -> Color) -> some View {
        
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
                    color = colorCreator(max(0, min((dragValue.first?.location.x ?? 0) - 16, sliderWidth - circleRadius)) / (sliderWidth - circleRadius))
                })
        )
        
    }
}
