//
//  FrameStore.swift
//  LiveImages
//
//  Created by Nikolay Kavretsky on 28.10.2024.
//

import Foundation
import Observation
import SwiftUI

@Observable
final class FrameStore {
    private(set) var frames: [DrawingFrame] = [.init(name: "Frame 1")]
    private let undoManager = MyUndoManager()
    private(set) var isPlaying: Bool = false
    private(set) var animationFrameIndex = 0
    private(set) var currentFrameIndex = 0
    private(set) var isFrameLineShowing = false
    private var timer: Timer = Timer()
    
    var canvasSize: CGSize?
    
    var canvasAspectRation: Double {
        if let canvasSize {
            canvasSize.width / canvasSize.height
        } else {
            1
        }
    }
    
    func changeFrame(to index: Int) {
        guard index >= 0, index < frames.count, index != currentFrameIndex else { return }
        renderImage(for: currentFrameIndex)
        currentFrameIndex = index
    }
    
    func toggleFrameLine() {
        if !isFrameLineShowing {
            renderImage(for: currentFrameIndex)
        }
        isFrameLineShowing.toggle()
    }
    
    func updateImage(for index: Int) {
        renderImage(for: index)
    }
    
    func removeFrame() {
        clearCurrent()
        if currentFrameIndex > 0 {
            currentFrameIndex -= 1
            frames.remove(at: currentFrameIndex + 1)
        }
    }
    
    func startPlay() {
        guard frames.count > 1 else { return }
        renderImage(for: currentFrameIndex)
        isPlaying = true
        timer.invalidate()
        animationFrameIndex = 0
        startTimer()
    }
    
    func stopPlay() {
        isPlaying = false
        timer.invalidate()
        animationFrameIndex = 0
    }
    
    private func clearCurrent() {
        undoManager.clearStack(for: frames[currentFrameIndex].id)
        frames[currentFrameIndex] = .init(name: "Frame \(frames.count)")
    }
    
    func addFrame() {
        if currentFrameIndex + 1 == frames.count  {
            frames.append(.init(name: "Frame \(frames.count + 1)"))
        }
        renderImage(for: currentFrameIndex)
        currentFrameIndex += 1
    }
    
    private func addPath(_ path: DrawingPath, to frameIndex: Int) {
        guard frameIndex < frames.count, frameIndex >= 0 else { return }
        
        
        
        guard frames[frameIndex].pathHead != nil else {
            let nextPath = PathNode(erasePath: path.type == .erase ? path : nil, drawingPaths: path.type == .erase ? [] : [path])
            frames[frameIndex].appendPath(nextPath)
            return
        }
        
        switch path.type {
        case .erase:
            if frames[frameIndex].pathHead?.erasePath == nil {
                frames[frameIndex].pathHead?.erasePath = path
            } else {
                let nextPath = PathNode(erasePath: path)
                frames[frameIndex].appendPath(nextPath)
            }
        case .fill:
            if frames[frameIndex].pathHead?.erasePath == nil {
                frames[frameIndex].pathHead?.drawingPaths.append(path)
            } else {
                let nextPath = PathNode(drawingPaths: [path])
                frames[frameIndex].appendPath(nextPath)
            }
        }
    }
    
    
    private func removePath(_ path: DrawingPath, from frameIndex: Int) {
        guard frameIndex < frames.count, frameIndex >= 0 else { return }
        guard frames[frameIndex].pathHead != nil else { return }
        
        if frames[frameIndex].pathHead?.erasePath == path {
            frames[frameIndex].pathHead?.erasePath = nil
        }
        if frames[frameIndex].pathHead?.drawingPaths.last == path {
            frames[frameIndex].pathHead?.drawingPaths.removeLast()
        }
        if frames[frameIndex].pathHead?.drawingPaths.count == 0 && frames[frameIndex].pathHead?.erasePath == nil {
            frames[frameIndex].removeFirst()
        }
    }
    
    func addPathWithUndo(_ path: DrawingPath, clearRedo: Bool = false) {
        addPath(path, to: currentFrameIndex)
        
        
        
        undoManager.registerUndo(frameID: frames[currentFrameIndex].id, removePrevious: clearRedo) { [weak self] in
            self?.removePathWithUndo(path)
        }
        if isFrameLineShowing {
            renderImage(for: currentFrameIndex)
        }
    }
    
    private func removePathWithUndo(_ path: DrawingPath) {
        removePath(path, from: currentFrameIndex)
        undoManager.registerRedu(frameID: frames[currentFrameIndex].id) { [weak self] in
            self?.addPathWithUndo(path)
        }
    }
    
    var canRedo: Bool {
        undoManager.canRedo(for: frames[currentFrameIndex].id)
    }
    
    var canUndo: Bool {
        undoManager.canUndo(for: frames[currentFrameIndex].id)
    }
    
    func undo() {
        undoManager.undo(for: frames[currentFrameIndex].id)
    }
    
    func redo() {
        undoManager.redo(for: frames[currentFrameIndex].id)
    }
    
    private var framePerSecond: Int = 1
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / Double(framePerSecond), repeats: true) { [weak self] _ in
            guard let self else { return }
            animationFrameIndex = (animationFrameIndex + 1) % frames.count
        }
    }
    
    
    private func drawPath(_ drawingPath: PathNode, in context: inout CGContext) {
        context.setLineJoin(.round)
        context.setLineCap(.round)
        context.setMiterLimit(0)
        if let toErase = drawingPath.erasePath {
            
            let image = createInverseMask(from: toErase, size: canvasSize!, lineWidth: toErase.lineWidth)
            context.setStrokeColor(UIColor(toErase.color).cgColor)
            context.setLineWidth(toErase.lineWidth)
            context.clip(to: CGRect(origin: .zero, size: canvasSize!), mask: image.cgImage!)
        }
        context.saveGState()
        if let next = drawingPath.next {
            var newContext = context
            drawPath(next, in: &newContext)
        }
        context.restoreGState()
        for path in drawingPath.drawingPaths {
            drawPath(path, in: &context)
        }

    }
    
    private func drawPath(_ path: DrawingPath, in context: inout CGContext) {
        if path.points.count != 1 {
            let currentDrawingPath = CGMutablePath()
            currentDrawingPath.addLines(between: path.points)
            context.setStrokeColor(UIColor(path.color).cgColor)
            context.setLineWidth(path.lineWidth)
            context.addPath(currentDrawingPath)
            context.strokePath()
        } else {
            let ellipseRect = CGRect(
                x: path.points[0].x - path.lineWidth / 2,
                y: path.points[0].y - path.lineWidth / 2,
                width: path.lineWidth,
                height: path.lineWidth
            )
            context.setFillColor(UIColor(path.color).cgColor)
            context.fillEllipse(in: ellipseRect)
        }
    }
    
    private func renderImage(for index: Int) {
        guard index >= 0, index < frames.count else { return }
        guard frames[index].image == nil || frames[index].didChanged else { return }
        frames[index].image = nil
        Task.detached { [weak self] in
            guard let self, let canvasSize else { return }
            let renderer = UIGraphicsImageRenderer(size: canvasSize)
            let image = renderer.image { ctx in
                var context = ctx.cgContext
                context.setLineCap(.round)
                
                if let head = self.frames[index].pathHead {
                    self.drawPath(head, in: &context)
                }
            }
            frames[index].image = Image(uiImage: image)
            frames[index].didChanged = false
        }
        
    }
    
    private func createInverseMask(from path: DrawingPath, size: CGSize, lineWidth: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            cgContext.translateBy(x: 0, y: size.height)
            cgContext.scaleBy(x: 1, y: -1)

            cgContext.setFillColor(UIColor.black.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))
        
            cgContext.setBlendMode(.clear)
            cgContext.setLineCap(.round)
            cgContext.setLineJoin(.round)
            cgContext.setMiterLimit(0)
            cgContext.setLineWidth(path.lineWidth)
            cgContext.setStrokeColor(UIColor.white.cgColor)
            
            let erasePath = CGMutablePath()
            erasePath.addLines(between: path.points)
            
            cgContext.addPath(erasePath)
            cgContext.strokePath()
        }
    }
    
}
