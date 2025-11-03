//
//  ContentView.swift
//  GatoDresser
//
//  Created by Lauren Hsueh on 9/22/25.
//
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var currentStage: Stage = .tops
    @State private var placedItem: ClothingItem? = nil
    @State private var accessoryScale: CGFloat = 1.0
    @State private var showWalkthrough = true
    @State private var showDeleteOption = false
    @State private var dragOffset: CGSize = .zero
    @State private var finalOffset: CGSize = .zero
    @State private var placedTop: ClothingItem? = nil
    @State private var placedHat: ClothingItem? = nil
    @State private var placedAccessories: [AccessoryItem] = []
    @State private var selectedBackground: String = "background1"
    @State private var showFinalScreen = false
    @State private var snapshotImage: UIImage? = nil
    
    let tops = (1...5).map { "top\($0)" }
    let hats = (1...3).map { "hat\($0)" }
    let backgrounds = (1...4).map { "background\($0)" }
    let accessories = (1...5).map { "accessory\($0)" }
    
    var body: some View {
        ZStack {
            Image(selectedBackground)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                if showFinalScreen {
                    HStack {
                        Spacer()
                        Button(action: takeScreenshot) {
                            Image(systemName: "camera")
                                .font(.largeTitle)
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.trailing, 30)
                        .padding(.bottom, 30)
                    }
                }
            }

            VStack {
                Spacer()
                
                ZStack {
                    Image("elgato")
                        .resizable()
                        .scaledToFit()
                        .frame(width: showFinalScreen ? 320 : 370)
                        .offset(x: showFinalScreen ? 0 : -60, y: showFinalScreen ? 30 : 10)
                    
                    if let top = placedTop {
                        Image(top.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: showFinalScreen ? 320 : 370)
                            .offset(x: showFinalScreen ? 0 : -60 + dragOffset.width + finalOffset.width,
                                    y: showFinalScreen ? 30 : 10 + dragOffset.height + finalOffset.height)
                            .gesture(dragGesture)
                    }
                    
                    if let hat = placedHat {
                        Image(hat.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: showFinalScreen ? 320 : 370)
                            .offset(x: showFinalScreen ? 0 : -60 + dragOffset.width + finalOffset.width,
                                    y: showFinalScreen ? 30 : 10 + dragOffset.height + finalOffset.height)
                            .gesture(dragGesture)
                    }
                    
                    ForEach($placedAccessories) { $accessory in
                        Image(accessory.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: showFinalScreen ? 320 : 370)
                            .scaleEffect(accessory.scale)
                            .offset(x: showFinalScreen ? 0 : -60 + accessory.dragOffset.width + accessory.finalOffset.width,
                                    y: showFinalScreen ? 30 : 10 + accessory.dragOffset.height + accessory.finalOffset.height)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        accessory.dragOffset = value.translation
                                    }
                                    .onEnded { value in
                                        accessory.finalOffset.width += value.translation.width
                                        accessory.finalOffset.height += value.translation.height
                                        accessory.dragOffset = .zero
                                    }
                            )
                            .simultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        accessory.scale = value
                                    }
                                    .onEnded { _ in
                                        if accessory.scale < 0.5 { accessory.scale = 0.5 }
                                        if accessory.scale > 2.0 { accessory.scale = 2.0 }
                                    }
                            )
                            .highPriorityGesture(
                                LongPressGesture(minimumDuration: 3)
                                    .onEnded { _ in
                                        withAnimation {
                                            placedAccessories.removeAll { $0.id == accessory.id }
                                        }
                                    }
                            )
                    }
                }
                
                Spacer()
            }
            .padding(.bottom, showFinalScreen ? 50 : 0)

            if !showFinalScreen {
                HStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 20) {
                        Text(stageTitle)
                            .font(.title2)
                            .padding(.top)
                        VStack(spacing: -20) {
                            ForEach(currentClothingSet, id: \.self) { clothingName in
                                Image(clothingName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 150)
                                    .onDrag {
                                        NSItemProvider(object: clothingName as NSString)
                                    }
                                    .onTapGesture {
                                        if currentStage == .backgrounds {
                                            selectedBackground = clothingName
                                        }
                                    }
                            }
                        }
                        .padding(.vertical, 10)
                        Spacer()
                    }
                    .frame(width: 120)
                    .background(Color.white.opacity(0.6))
                }
            }

            if showWalkthrough {
                walkthroughOverlay
            }

            if !showFinalScreen {
                VStack {
                    Spacer()
                    HStack(spacing: 20) {
                        if currentStage != .tops {
                            Button(action: moveToPreviousStage) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                                .font(.headline)
                                .foregroundColor(.black)
                            }
                            .padding(10)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                        }
                        
                        Button(action: {
                            if currentStage == .backgrounds {
                                withAnimation {
                                    showFinalScreen = true
                                }
                            } else {
                                moveToNextStage()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text(currentStage == .backgrounds ? "Done" : "Next")
                                Image(systemName: "chevron.right")
                            }
                            .font(.headline)
                            .foregroundColor(.black)
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 55)
                .padding(.bottom, 110)
            }
        }
        .onDrop(of: [.text], delegate: DropViewDelegate(onDrop: handleDrop))
    }
    
    // MARK: - Computed Vars
    var currentClothingSet: [String] {
        switch currentStage {
        case .tops: return tops
        case .hats: return hats
        case .accessories: return accessories
        case .backgrounds: return backgrounds
        }
    }
    var stageTitle: String {
        switch currentStage {
        case .tops: return "Tops"
        case .hats: return "Hats"
        case .accessories: return "Accessories"
        case .backgrounds: return "Backgrounds"
        }
    }
    
    // MARK: - Gestures
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                finalOffset.width += value.translation.width
                finalOffset.height += value.translation.height
                dragOffset = .zero
            }
    }
    
    // MARK: - Drop Handling
    private func handleDrop(itemName: String) {
        switch currentStage {
        case .tops:
            placedTop = ClothingItem(imageName: itemName)
            dragOffset = .zero
            finalOffset = .zero
            
        case .hats:
            placedHat = ClothingItem(imageName: itemName)
            dragOffset = .zero
            finalOffset = .zero
            
        case .accessories:
            placedAccessories.append(AccessoryItem(imageName: itemName))
            
        case .backgrounds:
            selectedBackground = itemName
        }
    }
    
    // MARK: - Stage Navigation
    private func moveToPreviousStage() {
        switch currentStage {
        case .hats:
            currentStage = .tops
        case .accessories:
            currentStage = .hats
        case .backgrounds:
            currentStage = .accessories
        case .tops:
            break
        }
    }
    private func moveToNextStage() {
        switch currentStage {
        case .tops:
            currentStage = .hats
        case .hats:
            currentStage = .accessories
        case .accessories:
            currentStage = .backgrounds
        case .backgrounds:
            break
        }
    }
    
    private func takeScreenshot() {
        let window = UIApplication.shared.windows.first!
        let renderer = UIGraphicsImageRenderer(size: window.bounds.size)
        let image = renderer.image { ctx in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        snapshotImage = image
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    private func walkthroughStep(image: String, text: String) -> some View {
        VStack {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 100)
            Text(text)
                .foregroundColor(.white)
                .font(.headline)
        }
    }
    private var walkthroughOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            
            VStack(spacing: 30) {
                if currentStage == .tops {
                    walkthroughStep(image: "pointer_drag", text: "Drag a top to El Gato!")
                } else if currentStage == .accessories {
                    walkthroughStep(image: "pinch_gesture", text: "Pinch to resize accessory")
                    walkthroughStep(image: "hold_gesture", text: "Hold for 3 seconds to delete")
                } else if currentStage == .backgrounds {
                    walkthroughStep(image: "pointer_drag", text: "Tap a background to select it!")
                }
                
                Button("Got it!") {
                    withAnimation {
                        showWalkthrough = false
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Models
struct AccessoryItem: Identifiable {
    let id = UUID()
    let imageName: String
    var dragOffset: CGSize = .zero
    var finalOffset: CGSize = .zero
    var scale: CGFloat = 1.0
}

struct ClothingItem {
    let imageName: String
}

enum Stage {
    case tops, hats, accessories, backgrounds
}

// MARK: - Drop Delegate
struct DropViewDelegate: DropDelegate {
    let onDrop: (String) -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        if let item = info.itemProviders(for: [.text]).first {
            item.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { data, _ in
                if let data = data as? Data,
                   let name = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        onDrop(name)
                    }
                }
            }
            return true
        }
        return false
    }
}

#Preview {
    ContentView()
}
