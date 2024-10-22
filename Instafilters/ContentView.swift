//
//  ContentView.swift
//  Instafilters
//
//  Created by Jatin Singh on 30/09/24.
//
import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import StoreKit
import PhotosUI

struct ContentView: View {
    @State private var processedImage : Image?
    @State private var filterIntensity = 0.5
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingFilters = false
    
    @AppStorage("filter count") var filterCount = 0
    @Environment(\.requestReview) var requestReview
    
    @State private var currentFilter : CIFilter = CIFilter.sepiaTone()
    let context = CIContext()
    
    var body: some View {
        NavigationStack {
            VStack {
                
                Spacer()
                PhotosPicker(selection: $selectedItem) {
                    if let processedImage {
                        processedImage
                            .resizable()
                            .scaledToFit()
                    }else {
                        ContentUnavailableView("No picture", systemImage: "photo.badge.plus", description: Text("tap to import a photo"))
                    }
                }
                .buttonStyle(.plain)
                .onChange(of: selectedItem, loadImage)
                
                Spacer()
                
                HStack {
                    Text("Intensity")
                    Slider(value: $filterIntensity)
                        .onChange(of: filterIntensity, applyProcessing)
                }
                
                HStack {
                    Button("change filter", action: changeFilter)
                    Spacer()
                    if let processedImage {
                        ShareLink(item: processedImage, preview: SharePreview("Instafilter image" , image: processedImage))
                    }
                }
            
            }
            .padding([.horizontal, .bottom])
            .navigationTitle("Instafilters")
            .confirmationDialog("select a filter", isPresented: $showingFilters) {
                Button("Crystallize") { setFilter(CIFilter.crystallize() ) }
                Button("Edges") { setFilter(CIFilter.edges() ) }
                Button("Gaussian Blur") { setFilter(CIFilter.gaussianBlur() ) }
                Button("Pixellate") { setFilter(CIFilter.pixellate() ) }
                Button("Sepia Tone") { setFilter(CIFilter.sepiaTone() ) }
                Button("Unsharp Mask") { setFilter(CIFilter.unsharpMask() ) }
                Button("Vignette") { setFilter(CIFilter.vignette() ) }
                Button("cancel", role: .cancel) {
                    //
                }
            }
        }
    }
    
    func changeFilter() {
        showingFilters = true
    }
    
    func loadImage() {
        Task {
            guard let imageData = try await selectedItem?.loadTransferable(type: Data.self)
            else { return }
            guard let inputImage = UIImage(data: imageData) else { return }
            
            let beginImage = CIImage(image: inputImage)
            currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
            applyProcessing()
        }
    }
    
    func applyProcessing() {
        //currentFilter.intensity = Float(filterIntensity)
        //currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey)
        
        let inputKeys = currentFilter.inputKeys
        
        if inputKeys.contains(kCIInputIntensityKey) {
            currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey)
        }
        if inputKeys.contains(kCIInputRadiusKey) {
            currentFilter.setValue(filterIntensity*200, forKey: kCIInputRadiusKey)
        }
        if inputKeys.contains(kCIInputScaleKey) {
            currentFilter.setValue(filterIntensity*10, forKey: kCIInputScaleKey)
        }
        
        guard let outputImage = currentFilter.outputImage else { return }
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent)
        else { return }
        let uiImage = UIImage(cgImage: cgImage)
        processedImage = Image(uiImage: uiImage)
    }
    
    func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        loadImage()
        
        filterCount += 1
        if filterCount >= 20 {
            requestReview()
        }
    }
}

#Preview {
    ContentView()
}
