//
//  DrawableCircle.swift
//  LiveImages
//
//  Created by Nikolay Kavretsky on 03.11.2024.
//


import Foundation
import SwiftUI
import Observation

@Observable
class DrawableCircle: Drawable {
    var draggingOrigin: CGPoint?
    
    let id = UUID().uuidString
    
    var scaleValue: CGFloat = 1
    var scaleChange: CGFloat = 1
    var rotationChange: Angle = .zero
    var rotateAngle: Angle = .zero
    
    func rotate(to angle: Angle) {
        
    }
    
    
    var origin: CGPoint
    
    var color: Color
    
    var width: CGFloat
    
    var height: CGFloat
    
    
    func draw(using context: inout GraphicsContext, isSelected: Bool) {
        let path = Path(ellipseIn: self.modifiedRect())
        context.drawLayer { layerContext in
            layerContext.fill(path, with: .color(color))
            if isSelected {
                let strokePath = path.strokedPath(.init(lineWidth: 2))
                layerContext.stroke(strokePath, with: .color(.accent))
            }
        }
    }
    
    func draw(using context: inout CGContext) {
        
        let path = CGPath(ellipseIn: self.modifiedRect(), transform: nil)
                context.saveGState()
        context.addPath(path)
        context.setFillColor(UIColor(color).cgColor)
        context.fillPath()
        
        context.restoreGState()
    }
    
    
    static func == (lhs: DrawableCircle, rhs: DrawableCircle) -> Bool {
        lhs.id == rhs.id
    }
    
    init(scaleValue: CGFloat = 1, rotateAngle: Angle = .zero, origin: CGPoint, color: Color, width: CGFloat = 40, height: CGFloat = 40) {
        self.scaleValue = scaleValue
        self.rotateAngle = rotateAngle
        self.origin = origin
        self.color = color
        self.width = width
        self.height = height
    }
    
}
