//
//  SegmentControllerView.swift
//  LiveImages
//
//  Created by Nikolay Kavretsky on 01.11.2024.
//


import SwiftUI

enum SegmentControllerSelection: String, CaseIterable {
    case palette = "Palette"
    case manual = "Manual"
}

struct SegmentControllerView: View {
    @Binding var selected: SegmentControllerSelection
    @Namespace var typeNamespaceID
    
    var body: some View {
        HStack {
            ForEach(SegmentControllerSelection.allCases, id: \.rawValue) { element in
                itemView(for: element)
                    .onTapGesture {
                        withAnimation {
                            selected = element
                        }
                    }
                    .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.9, blendDuration: 1), value: selected)
                    .zIndex(element == selected ? 1 : 0)
            }
        }
        .padding(4)
        .background {
            Capsule()
                .fill(Color(.white))
                
        }
    }
    
    func itemView(for element: SegmentControllerSelection) -> some View {
        Text(element.rawValue)
            .foregroundStyle(element == selected ? .white : .black)
            .font(.headline)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background {
                if selected == element {
                    Capsule()
                        .fill(Color(.accent))
                        .offset(x: 0)
                        .matchedGeometryEffect(id: "typeBackgroundID", in: typeNamespaceID)
                }
            }
    }
    
    
}
