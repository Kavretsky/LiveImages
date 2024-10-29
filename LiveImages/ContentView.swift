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
    case none
}

struct ContentView: View {
    var frameStore: FrameStore = .init()
    @State private var lineWidth: CGFloat = 25
    @State private var instrument: Instument = .none
    @State private var selectedColor: Color = .red
    @State private var currentPath: [CGPoint] = []
    @State private var currentFrameIndex = 0
    
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
                //MARK: TODO
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
    
    private var drawingArea: some View {
        ZStack {
            Image(.whiteboard)
                .resizable()
            Canvas(colorMode: .nonLinear, rendersAsynchronously: false) { context, size in
                
                let savedContext = context
                if instrument == .eraser {
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
                
                let drawingPath: PathNode? = frameStore.frames[currentFrameIndex].pathHead
                if let drawingPath {
                    drawPath(drawingPath, in: &context)
                }
                
                if instrument != .eraser {
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
            .gesture(
                drawingGesture
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
            let elipsePath = Path(ellipseIn: CGRect(x: path.points[0].x - path.lineWidth / 2, y: path.points[0].y - path.lineWidth / 2, width: path.lineWidth, height: path.lineWidth))
            context.fill(elipsePath, with: .color(path.color))
        }
    }
    
    @GestureState private var gestureState: (Bool, CGPoint) = (false, .zero)
    private var drawingGesture: some Gesture {
        LongPressGesture(minimumDuration: 0, maximumDistance: 10).simultaneously(with: DragGesture(minimumDistance: 0, coordinateSpace: .local))
            .updating($gestureState) { value, state, transaction in
                guard instrument != .none else { return }
                state.1 = value.second?.location ?? .zero
                state.0 = value.first ?? false
                currentPath.append(state.1)
            }
            .onEnded{ value in
                guard instrument != .none else { return }
                let newPath = DrawingPath(points: currentPath, color: selectedColor, lineWidth: lineWidth, type: instrument == .eraser ? .erase : .fill)
                frameStore.addPathWithUndo(newPath, to: currentFrameIndex, clearRedo: true)
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
            Button {
                //MARK: TODO
            } label: {
                Image(.brush)
            }
            
            Button {
                instrument = instrument == .eraser ? .none : .eraser
            } label: {
                Image(.erase)
                    .renderingMode(.template)
                    .foregroundStyle(instrument == .eraser ? .accent : .white)
            }
            
            Button {
                //MARK: TODO
            } label: {
                Image(.instruments)
            }
            
            Button {
                //MARK: TODO
            } label: {
                Image(.color)
            }
        }
    }
    private var strokeStyle: StrokeStyle {
        StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round, miterLimit: 0, dash: [], dashPhase: 0)
    }
}


#Preview {
    ContentView()
        
}
