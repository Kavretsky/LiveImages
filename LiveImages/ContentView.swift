//
//  ContentView.swift
//  LiveImages
//
//  Created by Nikolay Kavretsky on 28.10.2024.
//

import SwiftUI

enum Instument: String {
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
    
    var body: some View {
            ZStack {
                Color(.origianlBlack)
                    .ignoresSafeArea()
                if frameStore.showProgress {
                    ProgressView()
                } else {
                    VStack(spacing: 0) {
                        if frameStore.isFrameLineShowing {
                            frameLineView
                            Spacer(minLength: 8)
                        } else {
                            headerView
                            Spacer(minLength: 32)
                        }
                        if frameStore.isPlaying {
                            animatableArea
                        } else {
                            drawingArea
                        }
                        Spacer(minLength: 24)
                        instrumentsView
                            .overlay(alignment: .bottom) {
                                if instrument == .color {
                                    ChangeColorView(selectedColor: $selectedColor)
                                        .padding(.bottom, 48)
                                        .transition(.blurReplace())
                                        .animation(.spring(), value: instrument)
                                }
                            }
                        
                    }
                    .padding(16)
                }
            }
            .alert("Are you sure to delete all frames?", isPresented: $showDeleteAllAlert) {
                Button("Delete All", role: .destructive) {
                    frameStore.removeAllFrames()
                }
            }
    }
    
    private var headerView: some View {
        HStack(alignment: .center) {
            if !frameStore.isPlaying {
                undoRedoView
                Spacer()
                frameManagerView
            } else {
                playSpeedView
            }
            Spacer()
            playControls
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
                frameStore.removeFrame()
            } label: {
                Image(.bin)
            }
            
            Button {
                frameStore.addFrame()
            } label: {
                Image(.filePlus)
            }
            
            Button {
                frameStore.toggleFrameLine()
            } label: {
                Image(.layers)
            }
            frameMenu
        }
    }
    
    @State private var showDeleteAllAlert: Bool = false
    
    private var frameMenu: some View {
        Menu {
            Button {
                frameStore.duplicateFrame()
            } label: {
                Label {
                    Text("Duplicate")
                } icon: {
                    Image(.duplicate)
                        .renderingMode(.template)
                }

                
            }
            Button {
                //TODO: generate
            } label: {
                Label {
                    Text("Generate")
                } icon: {
                    Image(systemName: "timelapse")
                }
            }
            Divider()
            Button(role: .destructive) {
                showDeleteAllAlert = true
            } label: {
                Label {
                    Text("Remove all")
                } icon: {
                    Image(.removeAll)
                        .renderingMode(.template)
                }
            }
            
        } label: {
            Image(systemName: "ellipsis")
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
        }
    }
    
    private var playControls: some View {
        HStack(spacing: 16) {
            if frameStore.isPlaying {
                Button {
                    frameStore.stopPlay()
                } label: {
                    Image(frameStore.isPlaying ? .pauseActive : .pauseUnactive)
                }
            }
            Button {
                instrument = .none
                frameStore.startPlay()
            } label: {
                Image(frameStore.frames.count > 1 ? .playActive : .playUnactive)
            }
            
        }
    }
    
    @State private var playSpeed = 1.0
    
    private var playSpeedView: some View {
        
        Menu {
            Button {
                playSpeed = 1.0
                frameStore.setFramePerSecond(playSpeed)
            } label: {
                Text("1 frame per second")
            }
            ForEach(1...6, id: \.self) { i in
                Button {
                    playSpeed = Double(5 * i)
                    frameStore.setFramePerSecond(playSpeed)
                } label: {
                    Text("\(5 * i) frame per second")
                }
            }
            
        } label: {
            Label("FPS: \(Int(playSpeed))", systemImage: "goforward")
        }
    }
    
    private func canvas(for frameIndex: Int) -> some View {
        Canvas(colorMode: .nonLinear, rendersAsynchronously: false) { context, size in
            if frameStore.canvasSize == nil {
                frameStore.canvasSize = size
            }
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
    
    private var animatableArea: some View {
        ZStack {
            Image(.canvasBackground)
                .resizable()
            frameStore.frames[frameStore.animationFrameIndex].image
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private var drawingArea: some View {
        ZStack {
            Image(.canvasBackground)
                .resizable()
            if frameStore.currentFrameIndex > 0 {
                canvas(for: frameStore.currentFrameIndex - 1)
                    .opacity(0.5)
            }
            canvas(for: frameStore.currentFrameIndex)
                .gesture(
                    drawingGesture, isEnabled: instrument == .pen || instrument == .eraser
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private func drawPath(_ drawingPath: PathNode, in context: inout GraphicsContext) {
        if let toErase = drawingPath.erasePath {
            var path = Path()
            path.addLines(toErase.points)
            context.clipToLayer(options: .inverse){ clippedContext in
                clippedContext.stroke(path, with: .color(toErase.color), style: strokeStyle)
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
    
    @ViewBuilder
    private var instrumentsView: some View {
        if frameStore.isPlaying {
            Color.clear
                .frame(height: 32)
        } else {
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
    }
    
    
    private var frameLineView: some View {
        HStack(spacing: 0) {
            Button {
                frameStore.toggleFrameLine()
            } label: {
                Image(systemName: "xmark.circle")
                    .fontWidth(.expanded)
                    .tint(.white)
                    .font(.title)
            }
            .padding(.horizontal, 12)
            ScrollView(.horizontal) {
                LazyHStack(spacing: 3) {
                    ForEach(0..<frameStore.frames.count, id: \.self) { index in
                        ZStack {
                            Image(.canvasBackground)
                                .resizable()
                                .frame(width: 56 * frameStore.canvasAspectRation, height: 56)
                            if frameStore.frames[index].image != nil {
                                frameStore.frames[index].image!
                                    .resizable()
                                    .frame(width: 56 * frameStore.canvasAspectRation, height: 56)
                            } else {
                                ProgressView()
                                    .onAppear {
                                        frameStore.updateImage(for: index)
                                    }
                            }
                        }
                        .border(.accent, width: index == frameStore.currentFrameIndex ? 2 : 0)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                        .onTapGesture {
                            frameStore.changeCurrentFrame(to: index)
                        }
                    }
                }
            }
        }
        .frame(height: 56)
    }
    
    private var strokeStyle: StrokeStyle {
        StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round, miterLimit: 0, dash: [], dashPhase: 0)
    }
}



#Preview {
    ContentView()
    
}
