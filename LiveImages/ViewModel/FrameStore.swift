//
//  FrameStore.swift
//  LiveImages
//
//  Created by Nikolay Kavretsky on 28.10.2024.
//

import Foundation
import Observation
import SwiftUI
import UniformTypeIdentifiers

@Observable
final class FrameStore {
    private(set) var frames: [DrawingFrame] = [.init(name: "Frame 1")]
    private let undoManager = MyUndoManager()
    private(set) var showProgress = false
    private(set) var currentFrameIndex = 0
    
    var canvasSize: CGSize?
    
    var canvasAspectRation: Double {
        if let canvasSize {
            canvasSize.width / canvasSize.height
        } else {
            1
        }
    }
    
    //MARK: Frame intents
    func changeCurrentFrame(to index: Int) {
        guard index >= 0, index < frames.count, index != currentFrameIndex else { return }
        renderImage(for: currentFrameIndex)
        currentFrameIndex = index
    }
    
    func removeFrame() {
        clearCurrentFrame()
        if currentFrameIndex > 0 {
            currentFrameIndex -= 1
            frames.remove(at: currentFrameIndex + 1)
        }
    }
    
    func removeAllFrames() {
        showProgress = true
        currentFrameIndex = 0
        frames = [.init(name: "Frame 1")]
        undoManager.dropAll()
        showProgress = false
    }
    
    private func clearCurrentFrame() {
        undoManager.clearStack(for: frames[currentFrameIndex].id)
        frames[currentFrameIndex] = .init(name: "Frame \(frames.count)")
    }
    
    func addFrame() {
        if currentFrameIndex + 1 == frames.count  {
            frames.append(.init(name: "Frame \(frames.count + 1)"))
        }
        renderImage(for: currentFrameIndex)
        changeCurrentFrame(to: currentFrameIndex + 1)
    }
    
    func duplicateFrame() {
        showProgress = true
        var copy = DrawingFrame(name: frames[currentFrameIndex].name + "Duplicate")
        var head = frames[currentFrameIndex].pathHead
        var newPaths: [PathNode] = []
        while let path = head {
            let pathCopy = PathNode(erasePath: path.erasePath, next: nil, drawingPaths: path.drawingPaths)
            newPaths.append(pathCopy)
            head = path.next
        }
        var index = newPaths.count - 1
        while index >= 0 {
            copy.appendPath(newPaths[index])
            index -= 1
        }
        copy.image = frames[currentFrameIndex].image
        if currentFrameIndex + 1 == frames.count  {
            frames.append(copy)
        } else {
            frames.insert(copy, at: currentFrameIndex + 1)
        }
        
        changeCurrentFrame(to: currentFrameIndex + 1)
        showProgress = false
    }
    
    //MARK: Path intents
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
    
    //MARK: UndoManager
    func addPathWithUndo(_ path: DrawingPath, clearRedo: Bool = false) {
        addPath(path, to: currentFrameIndex)
        frames[currentFrameIndex].didChanged = true
        
        
        undoManager.registerUndo(frameID: frames[currentFrameIndex].id, removePrevious: clearRedo) { [weak self] in
            self?.removePathWithUndo(path)
        }
        if isFrameLineShowing {
            renderImage(for: currentFrameIndex)
        }
    }
    
    private func removePathWithUndo(_ path: DrawingPath) {
        removePath(path, from: currentFrameIndex)
        frames[currentFrameIndex].didChanged = true
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
    
    //MARK: Frame Animation
    private(set) var isPlaying: Bool = false
    private(set) var animationFrameIndex = 0
    private var timer: Timer = Timer()
    
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
    
    private var framePerSecond: Double = 1.0
    private func startTimer() {
        timer.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / Double(framePerSecond), repeats: true) { [weak self] _ in
            guard let self else { return }
            animationFrameIndex = (animationFrameIndex + 1) % frames.count
        }
    }
    
    func setFramePerSecond(_ framePerSecond: Double) {
        guard framePerSecond > 0 else { return }
        self.framePerSecond = framePerSecond
        startTimer()
    }
    
    
    //MARK: RenderImage
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
            frames[index].image = image
            
            frames[index].didChanged = false
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
    
    //MARK: FrameLine
    private(set) var isFrameLineShowing = false
    
    func toggleFrameLine() {
        if !isFrameLineShowing {
            renderImage(for: currentFrameIndex)
        }
        isFrameLineShowing.toggle()
    }
    
    func updateImage(for index: Int) {
        renderImage(for: index)
    }
    
    
    //MARK: GIF
    private(set) var gifURL: URL?
    private var createGifTask: Task<Void, Error>?
    
    private enum CreateGifError: Error {
        case noCacheDirectory
        case noImageDestination
    }
    
    private func gifGenerator() async throws -> URL {
        guard let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw CreateGifError.noCacheDirectory
        }
        if let gifURL {
            try FileManager.default.removeItem(at: gifURL)
        }
        
        let fileName = "madeyourself.gif"
        let fileURL = directory.appendingPathComponent(fileName)
        let loopProperty = [kCGImagePropertyGIFDictionary : [
            kCGImagePropertyGIFLoopCount : 0]] as CFDictionary
        guard let destination = CGImageDestinationCreateWithURL(fileURL as CFURL, UTType.gif.identifier as CFString, frames.count, nil) else {
            throw CreateGifError.noImageDestination
        }
        
        CGImageDestinationSetProperties(destination, loopProperty)
        let frameProperties = [
            kCGImagePropertyGIFDictionary : [
                kCGImagePropertyGIFDelayTime : 1.0 / framePerSecond
            ]
        ] as CFDictionary
        
        var index = 0
        while index < frames.count  {
            try Task.checkCancellation()
            guard let image = frames[index].image?.cgImage else {
                index += 1
                continue
            }
            CGImageDestinationAddImage(destination, image, frameProperties)
            index += 1
        }
        
        CGImageDestinationFinalize(destination)
        
        return fileURL
    }
    
    func createGIF() {
        if createGifTask != nil {
            createGifTask?.cancel()
        }
        renderImage(for: currentFrameIndex)
        createGifTask = Task(priority: .userInitiated) {
            async let url = gifGenerator()
            gifURL = try await url
        }
    }
    
}
