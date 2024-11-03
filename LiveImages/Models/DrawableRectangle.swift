//
//  DrawableRectangle.swift
//  LiveImages
//
//  Created by Nikolay Kavretsky on 03.11.2024.
//


import Foundation
import SwiftUI
import Observation

@Observable
class DrawableRectangle: Drawable {
    var draggingOrigin: CGPoint?
    
    var id: String = UUID().uuidString
    
    var origin: CGPoint
    
    var width: CGFloat = 80
    var height: CGFloat = 80
    
    var scaleValue: CGFloat = 1
    
    var scaleChange: CGFloat = 1
    
    var rotateAngle: Angle = .zero
    
    var rotationChange: Angle = .zero
    
    var color: Color
    
    func draw(using context: inout GraphicsContext, isSelected: Bool) {
        let newRect = modifiedRect()
        let path = Path(roundedRect: modifiedRect(), cornerRadius: 0)
        
        context.drawLayer { layerContext in
            layerContext.translateBy(x: newRect.origin.x + newRect.width / 2, y: newRect.origin.y + newRect.height / 2)
            layerContext.rotate(by: rotationChange + rotateAngle)
            layerContext.translateBy(x: -(newRect.origin.x + newRect.width / 2), y: -(newRect.origin.y + newRect.height / 2))
            
            layerContext.fill(path, with: .color(color))
            if isSelected {
                let strokePath = path.strokedPath(.init(lineWidth: 2))
                layerContext.stroke(strokePath, with: .color(.accent))
            }
        }
    }
    
    func draw(using context: inout CGContext) {
        let rect = modifiedRect()
        context.saveGState()
        context.translateBy(x: rect.origin.x + rect.width / 2, y: rect.origin.y + rect.height / 2)
        context.rotate(by: rotateAngle.radians)
        context.translateBy(x: -(rect.origin.x + rect.width / 2), y: -(rect.origin.y + rect.height / 2))
        let path = CGPath(rect: rect, transform: nil)
                
        context.addPath(path)
        context.setFillColor(UIColor(color).cgColor)
        context.fillPath()
        
        context.restoreGState()
    }
    
    init(origin: CGPoint, width: CGFloat = 80, height: CGFloat = 80, color: Color) {
        self.origin = origin
        self.width = width
        self.height = height
        self.color = color
    }
}
