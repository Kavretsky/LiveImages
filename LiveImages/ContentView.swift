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
    case shapes = "Shapes"
    case linewidth = "Width"
    case none
}

enum DrawableShape: CaseIterable {
    case rectangle
    case circle
    case triangle
    
    var image: Image {
        switch self {
        case .circle: Image(.circle)
        case .rectangle: Image(.square)
        case .triangle: Image(.triangle)
        }
    }
}



struct ContentView: View {
    var frameStore: FrameStore = .init()
    @State private var lineWidth: CGFloat = 10
    @State private var instrument: Instument = .none
    @State private var selectedColor: Color = .liveImagesBlue
    @State private var currentPath: [CGPoint] = []
    @State private var selectedShape: DrawableShape?
    
    init() {
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = .accent
    }
    
    var body: some View {
            ZStack {
                Color(.background)
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
                                if instrument == .linewidth {
                                    LineWidthEditor(lineWidth: $lineWidth)
                                        .padding(16)
                                        .overlayBase()
                                        .padding(.bottom, 48)
                                }
                                if instrument == .shapes {
                                    ShapePicker(selectedShape: $selectedShape)
                                        .padding(.bottom, 48)
                                }
                            }
                        
                    }
                    .padding(16)
                }
            }
            .ignoresSafeArea(.keyboard)
            .alert("Are you sure to delete all frames?", isPresented: $showDeleteAllAlert) {
                Button("Delete All", role: .destructive) {
                    frameStore.removeAllFrames()
                }
            }
            .alert("Frame count", isPresented: $showGenerateFramesAlert) {
                generateFramesAlert
            } message: {
                Text("Enter frame count to generate")
            }
            .onChange(of: selectedShape) {
                if let selectedShape {
                    frameStore.undoablyAddShape(selectedShape, color: selectedColor)
                    instrument = .none
                }
            }
            .onChange(of: instrument) { oldValue, newValue in
                selectedShape = nil
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { [weak frameStore] _ in
                frameStore?.receiveMemoryWarningNotification()
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
                Image(.leftActive)
                    .renderingMode(.template)
                    .tint(.buttonTint)
            }
            
            .disabled(!frameStore.canUndo)
            Button {
                frameStore.redo()
            } label: {
                Image(.rightActive)
                    .renderingMode(.template)
                    .tint(.buttonTint)
            }
            .disabled(!frameStore.canRedo)
        }
    }
    
    private var frameManagerView: some View {
        HStack(spacing: 16) {
            Button {
                frameStore.removeFrame()
            } label: {
                Image(.bin)
                    .renderingMode(.template)
                    .tint(.buttonTint)
            }
            
            Button {
                frameStore.addFrame()
            } label: {
                Image(.filePlus)
                    .renderingMode(.template)
                    .tint(.buttonTint)
            }
            
            Button {
                frameStore.toggleFrameLine()
            } label: {
                Image(.layers)
                    .renderingMode(.template)
                    .tint(.buttonTint)
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
                guard !frameStore.isGeneratingFrames else { return }
                showGenerateFramesAlert = true
                frameCountTFFocus = true
            } label: {
                Label {
                    Text(!frameStore.isGeneratingFrames ? "Generate" : "Generating...")
                } icon: {
                    Image(systemName: "timelapse")
                        .symbolEffect(.pulse, options: .repeating, isActive: frameStore.isGeneratingFrames)
                }
            }
            .disabled(frameStore.isGeneratingFrames)
            
            Button {
                Task {
                    await frameStore.createGIF()
                }
            } label: {
                Label {
                    Text(frameStore.isCreatingGIF ? "Creating GIF..." : "Create GIF")
                } icon: {
                    Image(systemName: "photo.on.rectangle.angled")
                }
            }
            if let gifURL = frameStore.gifURL {
                ShareLink(item: gifURL, preview: SharePreview("madeyourself.gif", image: Image(uiImage: frameStore.frames.first?.image ?? .canvasBackground)))
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
                        .tint(.buttonTint)
                }
            }
            
        } label: {
            if frameStore.isGeneratingFrames {
                Image(systemName: "timelapse")
                    .symbolEffect(.pulse.byLayer, options: .repeating, isActive: frameStore.isGeneratingFrames)
                    .font(.title2)
                    .foregroundStyle(.buttonTint)
                    .frame(width: 32, height: 32)
            } else if frameStore.isCreatingGIF {
                Image(systemName: "photo.on.rectangle.angled")
                    .symbolEffect(.pulse.byLayer, options: .repeating, isActive: frameStore.isCreatingGIF)
                    .font(.title2)
                    .foregroundStyle(.buttonTint)
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: "ellipsis")
                    .font(.title2)
                    .foregroundStyle(.buttonTint)
                    .frame(width: 32, height: 32)
            }
            
        }
    }
    
    @State private var frameCount:String = "10"
    @State private var showGenerateFramesAlert = false
    @FocusState private var frameCountTFFocus: Bool
    private var generateFramesAlert: some View {
        VStack{
            TextField("Enter frame count", text: $frameCount)
                .focused($frameCountTFFocus)
                .keyboardType(.numberPad)
            Button("Generate") {
                Task {
                    await frameStore.generateFrames(count: Int(frameCount) ?? 10)
                }
            }
            .tint(.buttonTint)
            Button("Cancel", role: .cancel) {}
                .tint(.buttonTint)
        }
    }
    
    private var playControls: some View {
        HStack(spacing: 16) {
            if frameStore.isPlaying {
                Button {
                    frameStore.stopPlay()
                } label: {
                    Image(.pauseActive)
                        .renderingMode(.template)
                        .tint(.buttonTint)
                }
            }
            Button {
                instrument = .none
                frameStore.startPlay()
            } label: {
                Image(.playActive)
                    .renderingMode(.template)
                    .tint(.buttonTint)
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
                        layerContext.stroke(currentDrawingPath, with: .color(selectedColor), style: strokeStyle(with: lineWidth))
                        
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
                        layerContext.stroke(currentDrawingPath, with: .color(selectedColor), style: strokeStyle(with: lineWidth))
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
            
            if let uiImage = frameStore.frames[frameStore.animationFrameIndex].image {
                Image(uiImage: uiImage)
                    .resizable()
            } else {
                ProgressView()
                    .onAppear {
                        frameStore.updateImage(for: frameStore.animationFrameIndex)
                    }
            }
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
                    drawingGesture.simultaneously(with:zoomAndRotateGesture)
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .drawingGroup()
    }
    
    private func drawPath(_ drawingPath: PathNode, in context: inout GraphicsContext) {
        if let toErase = drawingPath.erasePath {
            var path = Path()
            path.addLines(toErase.points)
            context.clipToLayer(options: .inverse){ clippedContext in
                clippedContext.stroke(path, with: .color(toErase.color), style: strokeStyle(with: toErase.lineWidth))
            }
        }
        
        if let next = drawingPath.next {
            var newContext = context
            drawPath(next, in: &newContext)
        }
        for shape in drawingPath.shapes {
            shape.draw(using: &context, isSelected: shape.id == frameStore.frames[frameStore.currentFrameIndex].pathHead?.shapes.last?.id && instrument == .none)
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
                layerContext.stroke(currentDrawingPath, with: .color(path.color), style: strokeStyle(with: path.lineWidth))
            }
        } else {
            let ellipsePath = Path(ellipseIn: CGRect(x: path.points[0].x - path.lineWidth / 2, y: path.points[0].y - path.lineWidth / 2, width: path.lineWidth, height: path.lineWidth))
            context.fill(ellipsePath, with: .color(path.color))
        }
    }
    
    private var drawingGesture: some Gesture {
         DragGesture(minimumDistance: 0)
            .onChanged({ value in
                if instrument == .none, let shape = frameStore.frames[frameStore.currentFrameIndex].pathHead?.shapes.last {
                    shape.draggingOrigin = value.location
                    return
                }
                if instrument == .pen || instrument == .eraser {
                    currentPath.append(value.location)
                }
                if instrument == .color {
                    instrument = .pen
                }
            })
            .onEnded{ value in
                if  instrument == .pen || instrument == .eraser {
                    let newPath = DrawingPath(points: currentPath, color: selectedColor, lineWidth: lineWidth, type: instrument == .eraser ? .erase : .fill)
                    frameStore.addPathWithUndo(newPath, clearRedo: true)
                    currentPath = []
                }
                if instrument == .none, let shape = frameStore.frames[frameStore.currentFrameIndex].pathHead?.shapes.last{
                    frameStore.moveShapeWithUndo(shape, to: value.location)
                }
            }
    }
    
    private var zoomAndRotateGesture: some Gesture {
        MagnifyGesture().simultaneously(with: RotateGesture())
            .onChanged({ value in
                if let shape = frameStore.frames[frameStore.currentFrameIndex].pathHead?.shapes.last{
                    shape.scaleChange = value.first?.magnification ?? 1
                    shape.rotationChange = value.second?.rotation ?? .zero
                }
            })
            .onEnded({ value in
                if let shape = frameStore.frames[frameStore.currentFrameIndex].pathHead?.shapes.last{
                    shape.scaleChange = 1
                    shape.rotationChange = .zero
                    frameStore.scaleAndRotateShapeWithUndo(shape, scale: value.first?.magnification ?? 1, angle: value.second?.rotation ?? .zero, removeRedo: true)
                }
            })
    }
    
    private var fontWeight: Font.Weight {
        switch lineWidth {
        case 0...10: .thin
        case 10...20: .medium
        case 20...30: .semibold
        case 30...40: .bold
        default: .heavy
        }
    }
    
    @ViewBuilder
    private var instrumentsView: some View {
        if frameStore.isPlaying {
            Color.clear
                .frame(height: 32)
        } else {
            HStack(spacing: 16) {
                Button {
                    instrument = instrument == .linewidth ? .none : .linewidth
                } label: {
                    Image(systemName: "scribble.variable")
                        .font(.system(size: 20))
                        .foregroundStyle(instrument == .linewidth ? .accent : .buttonTint)
                        .fontWeight(
                            fontWeight
                        )
                        .frame(width: 32, height: 32)
                }
                Button {
                    instrument = instrument == .pen ? .none : .pen
                } label: {
                    Image(.pencil)
                        .renderingMode(.template)
                        .foregroundStyle(instrument == .pen ? .accent : .buttonTint)
                        .frame(width: 32, height: 32)
                }
                
//                Button {
//                    instrument = instrument == .brush ? .none : .brush
//                } label: {
//                    Image(.brush)
//                        .renderingMode(.template)
//                        .foregroundStyle(instrument == .brush ? .accent : .buttonTint)
//                        .frame(width: 32, height: 32)
//                }
                
                Button {
                    instrument = instrument == .eraser ? .none : .eraser
                } label: {
                    Image(.erase)
                        .renderingMode(.template)
                        .foregroundStyle(instrument == .eraser ? .accent : .buttonTint)
                        .frame(width: 32, height: 32)
                }
                
                Button {
                    instrument = instrument == .shapes ? .none : .shapes
                } label: {
                    Image(.instruments)
                        .renderingMode(.template)
                        .foregroundStyle(instrument == .shapes ? .accent : .buttonTint)
                        .frame(width: 32, height: 32)
                }
                
                Button {
                    instrument = instrument == .color ? .none : .color
                } label: {
                    ZStack {
                        Circle()
                            .foregroundStyle(instrument == .color ? .accent : .buttonTint)
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
                    .tint(.buttonTint)
                    .font(.title)
            }
            .padding(.horizontal, 12)
            ScrollView(.horizontal) {
                LazyHStack(spacing: 3) {
                    ForEach(frameStore.frames) { frame in
                        ZStack {
                            if let image = frame.image{
                                Image(uiImage: image)
                                    .resizable()
                                    .frame(width: 56 * frameStore.canvasAspectRation, height: 56)
                            } else {
                                Image(.canvasBackground)
                                    .resizable()
                                    .frame(width: 56 * frameStore.canvasAspectRation, height: 56)
                                ProgressView()
                                    .task {
                                        frameStore.updateImage(for: frame.id)
                                    }
                                    .onDisappear {
                                        frameStore.cancelUpdateImage(for: frame.id)
                                    }
                            }
                        }
                        .onDisappear {
                            frameStore.cancelUpdateImage(for: frame.id)
                        }
                        .border(.accent, width: frame.id == frameStore.frames[frameStore.currentFrameIndex].id ? 2 : 0)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                        .onTapGesture {
                            frameStore.changeCurrentFrame(to: frame)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            
        }
        .frame(height: 56)
    }
    
    private func strokeStyle(with lineWidth: CGFloat) -> StrokeStyle {
        StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round, miterLimit: 0, dash: [], dashPhase: 0)
    }
}



#Preview {
    ContentView()
    
}
