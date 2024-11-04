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
        frames.append(.init(name: "Frame \(frames.count + 1)"))
        renderImage(for: currentFrameIndex)
        changeCurrentFrame(to: frames.endIndex - 1)
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
        guard let pathHead = frames[frameIndex].pathHead else {
            let nextPath = PathNode(erasePath: path.type == .erase ? path : nil, drawingPaths: path.type == .erase ? [] : [path])
            frames[frameIndex].appendPath(nextPath)
            return
        }
        
        switch path.type {
        case .erase:
            if pathHead.erasePath == nil && pathHead.shapes.isEmpty {
                pathHead.erasePath = path
            } else {
                let nextPath = PathNode(erasePath: path)
                frames[frameIndex].appendPath(nextPath)
            }
        case .fill:
            if pathHead.erasePath == nil && pathHead.shapes.isEmpty {
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
        if frames[frameIndex].pathHead?.drawingPaths.count == 0 && frames[frameIndex].pathHead?.erasePath == nil && frames[frameIndex].pathHead?.shapes.count == 0 {
            frames[frameIndex].removeFirstNode()
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
        undoManager.registerRedo(frameID: frames[currentFrameIndex].id) { [weak self] in
            self?.addPathWithUndo(path)
        }
        if isFrameLineShowing {
            renderImage(for: currentFrameIndex)
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
            DispatchQueue.main.async {
                self.animationFrameIndex = (self.animationFrameIndex + 1) % self.frames.count
            }
        }
    }
    
    func setFramePerSecond(_ framePerSecond: Double) {
        guard framePerSecond > 0 else { return }
        self.framePerSecond = framePerSecond
        startTimer()
    }
    
    
    //MARK: RenderImage
    private func renderImage(for index: Int) {
        guard index >= 0, index < frames.endIndex else { return }
        guard frames[index].image == nil || frames[index].didChanged else { return }
        if let pathNode = frames[index].pathHead, canvasSize != nil {
            Task {
                frames[index].image = await createImage(for: pathNode, size: canvasSize!)
                frames[index].didChanged = false
            }
        }
    }
    
    private func createImage(for node: PathNode, size: CGSize) async -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            var context = ctx.cgContext
            context.setLineCap(.round)
            context.saveGState()
            context.translateBy(x: 0, y: size.height)
            context.scaleBy(x: 1, y: -1)
            
            if let image = UIImage(resource: .canvasBackground).cgImage {
                context.draw(image, in: .init(origin: .zero, size: size), byTiling: false)
            }
            context.restoreGState()
            self.drawPath(node, in: &context)
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
        if !drawingPath.shapes.isEmpty {
            for shape in drawingPath.shapes {
                shape.draw(using: &context)
            }
        }
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
        
        let globalColorMap = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFHasGlobalColorMap : "No" as CFString]] as CFDictionary
        
        CGImageDestinationSetProperties(destination, loopProperty)
        CGImageDestinationSetProperties(destination, globalColorMap)
        let frameProperties = [
            kCGImagePropertyGIFDictionary : [
                kCGImagePropertyGIFDelayTime : 1.0 / framePerSecond
            ]
        ] as CFDictionary
        
        var index = 0
        
        while index < frames.count  {
            try Task.checkCancellation()
            if let image = frames[index].image?.cgImage {
                CGImageDestinationAddImage(destination, image, frameProperties)
            }
            index += 1
        }
        
        CGImageDestinationFinalize(destination)
        
        return fileURL
    }
    
    func createGIF() async {
        if createGifTask != nil {
            createGifTask?.cancel()
        }
        renderImage(for: currentFrameIndex)
        do {
            gifURL = try await gifGenerator()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    
    //MARK: Frame Generation
    private(set) var isGeneratingFrames: Bool = false
    
    func generateFrames(count: Int) async {
        guard !isGeneratingFrames else { return }
        guard let canvasSize else { return }
        isGeneratingFrames = true
        var newFrames: [DrawingFrame] = []
        await withTaskGroup(of: DrawingFrame.self) { [weak self] group in
            for _ in 0..<count {
                guard let self else { return }
                group.addTask {
                    return await self.generateFrame()
                }
                
                for await frame in group {
                    newFrames.append(frame)
                }
            }
        }
        
        await withTaskGroup(of: UIImage.self) { [weak self] group in
            for index in 0..<newFrames.count {
                guard let self else { return }
                group.addTask {
                    return await self.createImage(for: newFrames[index].pathHead!, size: canvasSize)
                }
                
                for await image in group {
                    newFrames[index].image = image
                }
            }
        }
        frames.append(contentsOf: newFrames)
        
        isGeneratingFrames = false
    }
    
    private func generateFrame() async -> DrawingFrame {
        var frame: DrawingFrame = .init(name: "generatedFrame")
        guard let path = frame.pathHead else { return frame }
        for _ in 0..<Int.random(in: 1...10) {
            let shape = DrawableShape.allCases.randomElement() ?? .circle
            let color = Color.randomColor()
            let origin = CGPoint(x: .random(in: 0..<Int(canvasSize!.width) - 50) , y: .random(in: 0..<Int(canvasSize!.height) - 50))
            let scale: CGFloat = .random(in: 0.1..<5)
            let height: CGFloat = .random(in: 50..<canvasSize!.height / scale)
            let width: CGFloat = .random(in: 50..<canvasSize!.width / scale)
            let rotation: Angle = Angle(degrees: .random(in: 0..<360))
            if let shape = createShape(shape, color: color, origin: origin, scaleValue: scale, rotateAngle: rotation, width: width, height: height) {
                path.shapes.append(shape)
                frame.appendPath(.init())
            }
        }
        
        return frame
    }
    
    
    //MARK: Shapes
    private func addShape<T: Drawable>(_ shape: T) {
        if let path = frames[currentFrameIndex].pathHead, path.erasePath == nil, path.drawingPaths.isEmpty {
            path.shapes.append(shape)
        } else {
            frames[currentFrameIndex].appendPath(.init(shapes: [shape]))
        }
    }
    
    private func removeShape<T: Drawable>(_ shape: T) {
        guard let path = frames[currentFrameIndex].pathHead else { return }
        if shape.id == path.shapes.last?.id {
            path.shapes.removeLast()
            if path.shapes.isEmpty {
                frames[currentFrameIndex].removeFirstNode()
            }
        }
    }
    
    func undoablyAddShape(_ shape: DrawableShape, color: Color) {
        guard let newShape = createShape(shape, color: color) else { return }
        addShape(newShape)
        undoManager.registerUndo(frameID: frames[currentFrameIndex].id, removePrevious: true) { [weak self] in
            self?.undoablyRemoveShape(newShape)
        }
        frames[currentFrameIndex].didChanged = true
        if isFrameLineShowing {
            renderImage(for: currentFrameIndex)
        }
    }
    
    private func undoablyAddShape<T: Drawable>(_ shape: T) {
        addShape(shape)
        undoManager.registerUndo(frameID: frames[currentFrameIndex].id) { [weak self] in
            self?.undoablyRemoveShape(shape)
        }
        frames[currentFrameIndex].didChanged = true
        if isFrameLineShowing {
            renderImage(for: currentFrameIndex)
        }
    }
    
    private func undoablyRemoveShape<T: Drawable>(_ shape: T) {
        removeShape(shape)
        undoManager.registerRedo(frameID: frames[currentFrameIndex].id) { [weak self] in
            self?.undoablyAddShape(shape)
        }
        frames[currentFrameIndex].didChanged = true
        if isFrameLineShowing {
            renderImage(for: currentFrameIndex)
        }
    }
    
    private func createShape(_ shape: DrawableShape, color: Color, origin: CGPoint = .zero, scaleValue: CGFloat = 1, rotateAngle: Angle = .zero, width: CGFloat = 80, height: CGFloat = 80) -> (any Drawable)? {
        guard let canvasSize else { return nil }
        var origin = origin
        if origin == .zero {
            origin = CGPoint(x: canvasSize.width / 2 - width / 2, y: canvasSize.height / 2 - height / 2)
        }
        switch shape {
        case .circle:
            return DrawableCircle(scaleValue: scaleValue, rotateAngle: rotateAngle, origin: origin, color: color, width: width, height: height)
        case .rectangle:
            return DrawableRectangle(origin: origin, width: width, height: height, color: color, scale: scaleValue, rotateAngle: rotateAngle)
        case .triangle:
            return DrawableTriangle(origin: origin, width: width, height: height, color: color, scale: scaleValue, rotateAngle: rotateAngle)
        }
        
    }
    
    func moveShapeWithUndo<T: Drawable>(_ shape: T, to point: CGPoint, removeRedo: Bool = false) {
        let prevCenter = CGPoint(x: shape.origin.x + shape.width / 2, y: shape.origin.y + shape.height / 2)
        shape.move(to: point)
        undoManager.registerUndo(frameID: frames[currentFrameIndex].id, removePrevious: removeRedo) { [weak self] in
            self?.moveShapeBackWithRedo(shape, to: prevCenter)
        }
        frames[currentFrameIndex].didChanged = true
        if isFrameLineShowing {
            renderImage(for: currentFrameIndex)
        }
    }
    
    private func moveShapeBackWithRedo<T: Drawable>(_ shape: T, to point: CGPoint) {
        let prevCenter = CGPoint(x: shape.origin.x + shape.width / 2, y: shape.origin.y + shape.height / 2)
        shape.move(to: point)
        undoManager.registerRedo(frameID: frames[currentFrameIndex].id) { [weak self] in
            self?.moveShapeWithUndo(shape, to: prevCenter)
        }
        frames[currentFrameIndex].didChanged = true
        if isFrameLineShowing {
            renderImage(for: currentFrameIndex)
        }
    }
    
    func scaleAndRotateShapeWithUndo<T: Drawable>(_ shape: T, scale: CGFloat, angle: Angle, removeRedo: Bool = false) {
        let prevScale = shape.scaleValue
        let prevAngle = shape.rotateAngle
        shape.scaleValue *= scale
        shape.rotateAngle += angle
        undoManager.registerUndo(frameID: frames[currentFrameIndex].id, removePrevious: removeRedo) { [weak self] in
            self?.scaleAndRotateShapeWithRedo(shape, scale: prevScale / shape.scaleValue, angle: prevAngle - shape.rotateAngle)
        }
        frames[currentFrameIndex].didChanged = true
        if isFrameLineShowing {
            renderImage(for: currentFrameIndex)
        }
    }
    
    private func scaleAndRotateShapeWithRedo<T: Drawable>(_ shape: T, scale: CGFloat, angle: Angle) {
        let prevScale = shape.scaleValue
        let prevAngle = shape.rotateAngle
        shape.scaleValue *= scale
        shape.rotateAngle += angle
        undoManager.registerRedo(frameID: frames[currentFrameIndex].id) { [weak self] in
            self?.scaleAndRotateShapeWithUndo(shape, scale: prevScale / shape.scaleValue, angle: prevAngle - shape.rotateAngle)
        }
        frames[currentFrameIndex].didChanged = true
        if isFrameLineShowing {
            renderImage(for: currentFrameIndex)
        }
    }
}
