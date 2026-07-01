import Foundation
import AppKit
import Vision
import CoreImage

let imagePath = "/Users/gu/Desktop/Focus4Good-ios/Focus4Good/Focus4Good/Assets.xcassets/plannercard.imageset/Gemini_Generated_Image_937le1937le1937l (1).png"

guard let nsImage = NSImage(contentsOfFile: imagePath),
      let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("Could not load image")
    exit(1)
}

if #available(macOS 14.0, *) {
    let request = VNGenerateForegroundInstanceMaskRequest()
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    
    do {
        try handler.perform([request])
        if let result = request.results?.first {
            let maskPixelBuffer = try result.generateMaskedImage(
                ofInstances: result.allInstances,
                from: handler,
                croppedToInstancesExtent: false
            )
            
            let ciImage = CIImage(cvPixelBuffer: maskPixelBuffer)
            
            // Create white background
            let whiteBg = CIImage(color: CIColor.white).cropped(to: ciImage.extent)
            
            // Composite foreground over white
            let composited = ciImage.composited(over: whiteBg)
            
            let context = CIContext()
            if let finalCGImage = context.createCGImage(composited, from: composited.extent) {
                let finalNSImage = NSImage(cgImage: finalCGImage, size: nsImage.size)
                
                let destPath = "/Users/gu/Desktop/Focus4Good-ios/Focus4Good/Focus4Good/Assets.xcassets/plannercard.imageset/Gemini_Generated_Image_937le1937le1937l_white.png"
                let destURL = URL(fileURLWithPath: destPath)
                
                let bitmapRep = NSBitmapImageRep(cgImage: finalCGImage)
                if let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                    try pngData.write(to: destURL)
                    print("Successfully saved to \(destPath)")
                    exit(0)
                }
            }
        }
    } catch {
        print("Error: \(error)")
    }
} else {
    print("Requires macOS 14.0+")
}
