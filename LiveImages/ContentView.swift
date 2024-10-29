//
//  ContentView.swift
//  LiveImages
//
//  Created by Nikolay Kavretsky on 28.10.2024.
//

import SwiftUI

fileprivate enum Instument: Int {
    case pen
    case eraser
    case brush
    case none
}

struct ContentView: View {
    @EnvironmentObject var frameStore: FrameStore
    @State private var lineWidth: CGFloat = 25
    @State private var instrument: Instument = .none
    @State private var selectedColor: Color = .red
    @State private var currentPath: DrawingPath = .init(points: [], color: Color(.liveImagesBlue), lineWidth: 5)
    @State private var currentFrameIndex = 0
    
    @Environment(\.undoManager) var undoManager
    
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
                undoManager?.undo()
            } label: {
                Image(.rightUnactive)
            }
            Button {
                undoManager?.redo()
            } label: {
                Image(.leftUnactive)
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
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Canvas(colorMode: .nonLinear, rendersAsynchronously: false) { context, size in
                let strokeStype = StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round, miterLimit: 0, dash: [], dashPhase: 0)
                
                if !frameStore.frames.isEmpty {
                    for layer in frameStore.frames[currentFrameIndex].paths {
                        var path = Path()
                        if layer.points.count > 1 {
                            path.addLines(layer.points)
                            context.stroke(path, with: .color(layer.color), style: strokeStype)
                        } else {
                            let path = Path(ellipseIn: CGRect(x: layer.points.first!.x - layer.lineWidth / 2, y: layer.points.first!.y - layer.lineWidth / 2, width: layer.lineWidth, height: layer.lineWidth))
                            context.fill(path, with: .color(layer.color))
                        }
                        
                    }
                }
                
                if currentPath.points.count != 1 {
                    var currentDrawingPath = Path()
                    currentDrawingPath.addLines(currentPath.points)
                    context.stroke(currentDrawingPath, with: .color(currentPath.color), style: strokeStype)
                } else {
                    let path = Path(ellipseIn: CGRect(x: currentPath.points[0].x - lineWidth / 2, y: currentPath.points[0].y - lineWidth / 2, width: lineWidth, height: lineWidth))
                    context.fill(path, with: .color(currentPath.color))
                }
                
            }
            .gesture(
                drawingGesture
            )
        }
    }
    
    @GestureState private var gestureState: (Bool, CGPoint) = (false, .zero)
    private var drawingGesture: some Gesture {
        LongPressGesture(minimumDuration: 0, maximumDistance: 10).simultaneously(with: DragGesture(minimumDistance: 0, coordinateSpace: .local))
            .updating($gestureState) { value, state, transaction in
                state.1 = value.second?.location ?? .zero
                state.0 = value.first ?? false
                currentPath.points.append(state.1)
            }
            .onEnded{ value in
                frameStore.frames[currentFrameIndex].paths.append(currentPath)
                currentPath = .init(points: [], color: selectedColor, lineWidth: lineWidth)
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
    
    private func erasePoints(at location: CGPoint) {
        
    }
}

#Preview {
    ContentView()
        .environmentObject(FrameStore())
}
