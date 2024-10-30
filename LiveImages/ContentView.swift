//
//  ContentView.swift
//  LiveImages
//
//  Created by Nikolay Kavretsky on 28.10.2024.
//

import SwiftUI

fileprivate enum Instument: String {
    case pen = "Pen"
    case eraser = "Eraser"
    case brush = "Brush"
    case color = "Color"
    case instruments = "Instruments"
    case none
}

struct ContentView: View {
    var frameStore: FrameStore = .init()
    @State private var lineWidth: CGFloat = 25
    @State private var instrument: Instument = .none
    @State private var selectedColor: Color = .liveImagesBlue
    @State private var currentPath: [CGPoint] = []
    @State private var image: Image?
    @Environment(\.displayScale) var displayScale
    
    @State private var lastColors: [Color] = [.white, .liveImagesOrange, .liveImagesBlack, .liveImagesBlue]
    
    var body: some View {
        ZStack {
            Color(.black)
                .ignoresSafeArea()
            VStack {
                headerView
                Spacer(minLength: 32)
                drawingArea
                Spacer(minLength: 22)
                instrumentsView
                    .overlay(alignment: .bottom) {
                        if instrument == .color {
                            palette
                                .padding(.bottom, 48)
                                .transition(.blurReplace())
                                .animation(.spring(), value: instrument)
                        }
                    }
            }
            .padding(16)
        }
    }
    
    private var headerView: some View {
        HStack(alignment: .center) {
            undoRedoView
            Spacer()
            frameManagerView
            Spacer()
            animationView
        }
    }
    
    private var undoRedoView: some View {
        HStack(spacing: 8) {
            Button {
                frameStore.undo()
            } label: {
                Image(frameStore.canUndo ? .leftActive : .leftUnactive)
            }
            Button {
                frameStore.redo()
            } label: {
                Image(frameStore.canRedo ? .rightActive : .rightNotactive)
            }
        }
    }
    
    private var frameManagerView: some View {
        HStack(spacing: 16) {
            Button {
                //MARK: TODO
            } label: {
                Image(.bin)
            }
            
            Button {
//                renderer()
                frameStore.addFrame()
            } label: {
                Image(.filePlus)
            }
            
            Button {
                //MARK: TODO
            } label: {
                Image(.layers)
            }
            
        }
    }
    
    private var animationView: some View {
        HStack(spacing: 16) {
            Button {
                //MARK: TODO
            } label: {
                Image(.playUnactive)
            }
            
            Button {
                //MARK: TODO
            } label: {
                Image(.pauseUnactive)
            }
        }
    }
    
    
    
    private func canvas(for frameIndex: Int) -> some View {
        Canvas(colorMode: .nonLinear, rendersAsynchronously: false) { context, size in
            let savedContext = context
            if instrument == .eraser && frameIndex == frameStore.currentFrameIndex {
                if currentPath.count != 1 {
                    var currentDrawingPath = Path()
                    currentDrawingPath.addLines(currentPath)
                    context.clipToLayer(options: .inverse) { layerContext in
                        layerContext.stroke(currentDrawingPath, with: .color(selectedColor), style: strokeStyle)
                    }
                } else {
                    let path = Path(ellipseIn: CGRect(x: currentPath[0].x - lineWidth / 2, y: currentPath[0].y - lineWidth / 2, width: lineWidth, height: lineWidth))
                    context.clipToLayer(options: .inverse) { layerContext in
                        layerContext.fill(path, with: .color(selectedColor))
                    }
                }
            }
            
            let drawingPath: PathNode? = frameStore.frames[frameIndex].pathHead
            if let drawingPath {
                drawPath(drawingPath, in: &context)
            }
            
            if instrument != .eraser && frameIndex == frameStore.currentFrameIndex {
                if currentPath.count != 1 {
                    var currentDrawingPath = Path()
                    currentDrawingPath.addLines(currentPath)
                    savedContext.drawLayer { layerContext in
                        layerContext.stroke(currentDrawingPath, with: .color(selectedColor), style: strokeStyle)
                    }
                } else {
                    let path = Path(ellipseIn: CGRect(x: currentPath[0].x - lineWidth / 2, y: currentPath[0].y - lineWidth / 2, width: lineWidth, height: lineWidth))
                    savedContext.fill(path, with: .color(selectedColor))
                }
            }
            
        }
    }
    
    private var drawingArea: some View {
        ZStack {
            Image(.whiteboard)
                .resizable()
//            if currentFrameIndex > 0, frameStore.frames[currentFrameIndex - 1].image != nil {
//            if let image {
////                frameStore.frames[currentFrameIndex - 1].image!
//                image
//                    .resizable()
//                    .opacity(0.5)
//            }
            if frameStore.currentFrameIndex > 0 {
                canvas(for: frameStore.currentFrameIndex - 1)
                    .opacity(0.5)
            }
            canvas(for: frameStore.currentFrameIndex)
                .gesture(
                    drawingGesture, isEnabled: instrument == .pen || instrument == .eraser
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func drawPath(_ drawingPath: PathNode, in context: inout GraphicsContext) {
        if let toErase = drawingPath.erasePath {
            var path = Path()
            path.addLines(toErase.points)
            context.clipToLayer(options: .inverse){ clipedContext in
                clipedContext.stroke(path, with: .color(toErase.color), style: strokeStyle)
            }
        }
        if let next = drawingPath.next {
            var newContext = context
            drawPath(next, in: &newContext)
        }
        for path in drawingPath.drawingPaths {
            drawPath(path, in: &context)
        }
    }
    
    private func drawPath(_ path: DrawingPath, in context: inout GraphicsContext) {
        if path.points.count != 1 {
            var currentDrawingPath = Path()
            currentDrawingPath.addLines(path.points)
            context.drawLayer { layerContext in
                layerContext.stroke(currentDrawingPath, with: .color(path.color), style: strokeStyle)
            }
        } else {
            let ellipsePath = Path(ellipseIn: CGRect(x: path.points[0].x - path.lineWidth / 2, y: path.points[0].y - path.lineWidth / 2, width: path.lineWidth, height: path.lineWidth))
            context.fill(ellipsePath, with: .color(path.color))
        }
    }
    
    private var drawingGesture: some Gesture {
        LongPressGesture(minimumDuration: 0, maximumDistance: 10).simultaneously(with: DragGesture(minimumDistance: 0))
            .onChanged({ value in
                currentPath.append(value.second?.location ?? .zero)
            })
            .onEnded{ value in
                let newPath = DrawingPath(points: currentPath, color: selectedColor, lineWidth: lineWidth, type: instrument == .eraser ? .erase : .fill)
                frameStore.addPathWithUndo(newPath, clearRedo: true)
                currentPath = []
            }
    }
    
    private var instrumentsView: some View {
        HStack(spacing: 16) {
            Image(.pencil)
                .renderingMode(.template)
                .foregroundStyle(instrument == .pen ? .accent : .white)
                .onTapGesture {
                    instrument = instrument == .pen ? .none : .pen
                }
                .frame(width: 32, height: 32)
            Button {
                instrument = instrument == .brush ? .none : .brush
            } label: {
                Image(.brush)
                    .renderingMode(.template)
                    .foregroundStyle(instrument == .brush ? .accent : .white)
                    .frame(width: 32, height: 32)
            }
            
            Button {
                instrument = instrument == .eraser ? .none : .eraser
            } label: {
                Image(.erase)
                    .renderingMode(.template)
                    .foregroundStyle(instrument == .eraser ? .accent : .white)
                    .frame(width: 32, height: 32)
            }
            
            Button {
                instrument = instrument == .instruments ? .none : .instruments
            } label: {
                Image(.instruments)
                    .renderingMode(.template)
                    .foregroundStyle(instrument == .instruments ? .accent : .white)
                    .frame(width: 32, height: 32)
            }
            
            Button {
                instrument = instrument == .color ? .none : .color
            } label: {
                ZStack {
                    Circle()
                        .foregroundStyle(instrument == .color ? .accent : .white)
                        .frame(width: 28, height: 28)
                    Circle()
                        .foregroundStyle(selectedColor)
                        .frame(width: 26, height: 26)
                }
                .frame(width: 32, height: 32)
            }
            
        }
    }
    private var strokeStyle: StrokeStyle {
        StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round, miterLimit: 0, dash: [], dashPhase: 0)
    }
    
    
    @State private var showMoreColors = false
    
    private var palette: some View {
        
        HStack(spacing: 16) {
            Image(.pallete)
                .renderingMode(.template)
                .foregroundStyle(showMoreColors ? .accent : .white)
            
            ForEach(lastColors, id: \.self) { color in
                Circle()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(color)
                    .padding(4)
                    .onTapGesture {
                        selectedColor = color
                        
                    }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(.black.opacity(0.10), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.14))
                        .blur(radius: 10)
                )
            
        )
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    
}


#Preview {
    ContentView()
    
}
