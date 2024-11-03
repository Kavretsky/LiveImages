//
//  Drawable.swift
//  LiveImages
//
//  Created by Nikolay Kavretsky on 03.11.2024.
//

import Foundation
import SwiftUI

protocol Drawable: Equatable, AnyObject {
    var id: String { get }
    var origin: CGPoint {get set}
    var draggingOrigin: CGPoint? { get set }
    var width: CGFloat {get set}
    var height: CGFloat {get set}
    var scaleValue: CGFloat {get set}
    var scaleChange: CGFloat {get set}
    var rotateAngle: Angle {get set}
    var color: Color {get set}
    var rotationChange: Angle {get set}
    func draw(using context: inout GraphicsContext, isSelected: Bool)
    func draw(using context: inout CGContext)
    func move(to point: CGPoint)
    
    static func ==(lhs: Self, rhs: Self) -> Bool
}

extension Drawable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    func move(to point: CGPoint) {
        origin.x = point.x - width / 2
        origin.y = point.y - height / 2
        draggingOrigin = nil
    }
    
    func modifiedRect() -> CGRect {
        if draggingOrigin != nil {
            CGRect(x: draggingOrigin!.x - (width * scaleValue * scaleChange ) / 2, y: draggingOrigin!.y - (height * scaleValue * scaleChange) / 2, width: width * scaleValue * scaleChange, height: scaleValue * scaleChange * height)
        } else {
            CGRect(x: origin.x - (width * scaleValue * scaleChange - width) / 2, y: origin.y - (height * scaleValue * scaleChange - height) / 2, width: width * scaleValue * scaleChange, height: scaleValue * scaleChange * height)
        }
        
    }
}
