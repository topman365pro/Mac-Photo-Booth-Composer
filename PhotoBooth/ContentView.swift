//
//  ContentView.swift
//  PhotoBooth (macOS)
//
//  Created by arham on 10/26/25.
//

import SwiftUI
import Combine
import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins
import UniformTypeIdentifiers
import PDFKit

// MARK: - ContentView

struct ContentView: View {
    // Camera permission state
    @State private var cameraAccessGranted: Bool? = nil

    // Camera & capture state
    @StateObject private var camera = CameraController()
    // Camera UI state
    @State private var selectedCameraID: String? = nil
    @State private var torchEnabled: Bool = false
    @State private var torchLevel: Float = 0.6
    @State private var captured: [NSImage?] = Array(repeating: nil, count: 3)
    @State private var activeSlot: Int = 0

    // Collage settings
    @State private var spacing: CGFloat = 30
    @State private var inset: CGFloat = 150
    @State private var cornerRadius: CGFloat = 8
    @State private var drawBorder: Bool = true
    @State private var borderWidth: CGFloat = 1
    @State private var mirrorPhotos: Bool = false
    @State private var cropToFourByThree: Bool = true
    @State private var layoutMode: CollageLayoutMode = .simpleStrip
    // Controls vertical length of the strip (height only; width unchanged)
    @State private var stripLengthFactor: CGFloat = 1.6

    // Background image
    @State private var backgroundImage: NSImage? = nil
    @State private var collageWidthFraction: CGFloat = 1.0 // fraction of A4 width after rotation placement

    // Bottom margin bias (extra margin at bottom of strip vs top)
    @State private var bottomMarginExtra: CGFloat = 240

    // Export feedback
    @State private var isExporting: Bool = false
    @State private var exportMessage: String? = nil

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            mainArea
        }
        .onAppear {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            switch status {
            case .authorized:
                cameraAccessGranted = true
                camera.start()
                camera.refreshDevices()
                selectedCameraID = camera.currentDevice?.uniqueID
                torchEnabled = camera.isTorchOn
                torchLevel = camera.torchLevel
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    DispatchQueue.main.async {
                        cameraAccessGranted = granted
                        if granted {
                            camera.start()
                            camera.refreshDevices()
                            selectedCameraID = camera.currentDevice?.uniqueID
                            torchEnabled = camera.isTorchOn
                            torchLevel = camera.torchLevel
                        }
                    }
                }
            default:
                cameraAccessGranted = false
            }
        }
        .onDisappear {
            if cameraAccessGranted == true {
                camera.stop()
            }
        }
    }

    // MARK: Sidebar with controls
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Photo Booth Builder")
                .font(.title2).bold()
            Text("1) Snap 3 photos → 2) Build collage → 3) Export A4 PDF")
                .font(.callout)
                .foregroundStyle(.secondary)

            GroupBox("Camera") {
                VStack(alignment: .leading, spacing: 8) {
                    // Camera picker
                    Picker("Device", selection: Binding(
                        get: { selectedCameraID ?? camera.currentDevice?.uniqueID ?? "" },
                        set: { newID in
                            selectedCameraID = newID
                            camera.switchToDevice(withID: newID)
                        })) {
                        ForEach(camera.devices, id: \.uniqueID) { dev in
                            Text(dev.localizedName).tag(dev.uniqueID)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    // Torch (continuity camera / iPhone) if available
                    Toggle("Torch", isOn: Binding(
                        get: { camera.isTorchOn },
                        set: { on in
                            torchEnabled = on
                            camera.setTorch(on: on, level: torchLevel)
                        }))
                    .disabled(!camera.isTorchAvailable)
                    
                    HStack {
                        Text("Torch Level")
                        Slider(value: Binding(
                            get: { Double(camera.torchLevel) },
                            set: { newVal in
                                torchLevel = Float(newVal)
                                if camera.isTorchOn {
                                    camera.setTorch(on: true, level: Float(newVal))
                                }
                            }), in: 0.1...1.0)
                    }
                    .opacity(camera.isTorchAvailable ? 1 : 0.5)
                    .disabled(!camera.isTorchAvailable)
                }
            }

            GroupBox("Collage Settings") {
                VStack(alignment: .leading) {
                    Picker("Layout", selection: $layoutMode) {
                        ForEach(CollageLayoutMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.bottom, 4)
                    Group {
                        HStack { Text("Spacing"); Spacer(); Text("\(Int(spacing))") }
                        Slider(value: $spacing, in: 0...120)
                        HStack { Text("Outer Margin"); Spacer(); Text("\(Int(inset))") }
                        Slider(value: $inset, in: 0...320)
                    }
                    .disabled(layoutMode == .templateLayout)
                    HStack { Text("Corner Radius"); Spacer(); Text("\(Int(cornerRadius))") }
                    Slider(value: $cornerRadius, in: 0...80)
                    Toggle("Border", isOn: $drawBorder)
                    if drawBorder {
                        HStack { Text("Border Width"); Spacer(); Text("\(String(format: "%.1f", borderWidth))") }
                        Slider(value: $borderWidth, in: 0.5...20)
                    }
                    Toggle("Mirror Photos", isOn: $mirrorPhotos)
                    Toggle("Crop Photos to 4:3", isOn: $cropToFourByThree)
                    Text("When enabled, images are cropped to a 4:3 frame before placement.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Group {
                        HStack { Text("Bottom Margin Extra"); Spacer(); Text("\(Int(bottomMarginExtra))") }
                        Slider(value: $bottomMarginExtra, in: 0...240)
                    }
                    .disabled(layoutMode == .templateLayout)
                    HStack { Text("Strip Length"); Spacer(); Text("\(Int(stripLengthFactor * 100))%") }
                    Slider(value: $stripLengthFactor, in: 0.6...2.5)
                }
                .padding(.top, 4)
            }

            GroupBox("Background") {
                HStack {
                    Button("Choose Background…") { pickBackground() }
                    if backgroundImage != nil {
                        Button("Clear") { backgroundImage = nil }
                    }
                }
                if let bg = backgroundImage {
                    Image(nsImage: bg)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(.quaternary))
                }
            }


            GroupBox("Export") {
                HStack { Text("Strip width on A4"); Spacer(); Text("\(Int(collageWidthFraction * 100))%") }
                Slider(value: $collageWidthFraction, in: 0.1...1.0)
                Button(role: .none) { exportPDF() } label: {
                    Label("Export A4 PDF…", systemImage: "square.and.arrow.down")
                }
                .disabled(!isReadyToExport)
                if let msg = exportMessage { Text(msg).font(.footnote).foregroundStyle(.secondary) }
            }

            Spacer()
        }
        .padding()
        .navigationSplitViewColumnWidth(min: 240, ideal: 280)
    }

    // MARK: Main area with camera & filmstrip
    private var mainArea: some View {
        VStack(spacing: 12) {
            if cameraAccessGranted == false {
                ContentUnavailableView("Camera access required", systemImage: "camera.fill.badge.xmark", description: Text("Please allow camera access in System Settings to use the photo booth."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        CameraPreviewView(session: camera.session)
                            .background(Color.black.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(alignment: .bottom) {
                                HStack(spacing: 12) {
                                    Button { captureToActiveSlot() } label: {
                                        Label("Snap", systemImage: "camera.circle.fill")
                                            .labelStyle(.titleAndIcon)
                                    }
                                    .keyboardShortcut(.space, modifiers: [])
                                    .disabled(!camera.canCapture)

                                    Button { clearActiveSlot() } label: { Label("Clear Slot", systemImage: "trash") }
                                        .disabled(captured[activeSlot] == nil)
                                }
                                Group {
                                    if !camera.canCapture {
                                        Text("Camera starting… or no permission")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .padding(8)
                            }
                    }
                    .frame(minWidth: 420, minHeight: 300)

                    VStack(spacing: 10) {
                        Text("Filmstrip (3)").font(.headline)
                        ForEach(0..<3, id: \.self) { idx in
                            filmSlot(index: idx)
                        }
                        Spacer()
                    }
                    .frame(width: 220)
                }

                Divider()

                // Live collage preview
                GroupBox("Collage Preview") {
                    GeometryReader { geo in
                        let canvasW = geo.size.width
                        let canvasH = max(geo.size.height, 300)
                        if let collage = buildCollagePreview(size: CGSize(width: canvasW, height: canvasH * stripLengthFactor)) {
                            ZStack {
                                // Keep the preview area neutral; the strip already includes its own background
                                Color.clear
                                VStack(spacing: 0) {
                                    Image(nsImage: collage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: canvasW * collageWidthFraction)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                                .padding(.top, 8)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                        } else {
                            ContentUnavailableView("Need 3 photos", systemImage: "rectangle.on.rectangle.slash", description: Text("Snap all 3 slots to preview the collage. \n (Ignore the resulting previews, they're kinda broken)"))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
            }
        }
        .padding()
    }

    private func filmSlot(index: Int) -> some View {
        Button {
            activeSlot = index
        } label: {
            ZStack {
                if let img = captured[index] {
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 90)
                        .clipped()
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "camera")
                        Text("Slot \(index + 1)")
                    }
                    .frame(height: 90)
                    .frame(maxWidth: .infinity)
                    .background(Color.secondary.opacity(0.12))
                }
                if activeSlot == index { RoundedRectangle(cornerRadius: 6).stroke(Color.accentColor, lineWidth: 3) }
                else { RoundedRectangle(cornerRadius: 6).stroke(.quaternary, lineWidth: 1) }
            }
        }
        .buttonStyle(.plain)
    }

    private var isReadyToExport: Bool { captured.allSatisfy { $0 != nil } }

    private func captureToActiveSlot() {
        camera.capturePhoto { image in
            if let image {
                // Save into current slot
                captured[activeSlot] = image
                
                // Advance selection: prefer the next empty slot, otherwise wrap to next index
                let total = captured.count
                if let nextEmpty = (0..<total)
                    .map({ (activeSlot + 1 + $0) % total })
                    .first(where: { captured[$0] == nil }) {
                    activeSlot = nextEmpty
                } else {
                    activeSlot = (activeSlot + 1) % total
                }
            }
        }
    }

    private func clearActiveSlot() { captured[activeSlot] = nil }

    private func pickBackground() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if panel.runModal() == .OK, let url = panel.url, let img = NSImage(contentsOf: url) {
            backgroundImage = img
        }
    }

    private func buildCollagePreview(size: CGSize) -> NSImage? {
        guard captured.allSatisfy({ $0 != nil }) else { return nil }
        let imgs = captured.compactMap { $0 }
        return CollageRenderer.makeVerticalCollage(
            photos: imgs,
            canvasSize: size,
            spacing: spacing,
            insetTop: inset,
            insetBottom: inset + bottomMarginExtra,
            cornerRadius: cornerRadius,
            borderWidth: drawBorder ? borderWidth : 0,
            background: backgroundImage,
            mirror: mirrorPhotos,
            cropToFourByThree: cropToFourByThree,
            layoutMode: layoutMode
        )
    }

    private func exportPDF() {
        guard let collageVertical = buildCollagePreview(size: CGSize(width: 1000, height: 2000 * stripLengthFactor)) else { return }

        // Rotate collage 90° for landscape placement on PDF
        let rotated = collageVertical.rotated90(clockwise: true)

        // A4 size in points (72 dpi): 595 x 842 portrait
        let a4 = CGSize(width: 595, height: 842)
        let margin: CGFloat = 24
        let targetWidth = (a4.width - 2 * margin) * collageWidthFraction
        let scale = targetWidth / rotated.size.width
        let drawSize = CGSize(width: rotated.size.width * scale, height: rotated.size.height * scale)
        let collageX = (a4.width - drawSize.width) / 2.0
        let topY = a4.height - margin

        let pdfData = PDFRenderer.createA4PDF { ctx in
            // Bind AppKit graphics context to this PDF context
            NSGraphicsContext.saveGraphicsState()
            let nsctx = NSGraphicsContext(cgContext: ctx, flipped: false)
            NSGraphicsContext.current = nsctx

            // 1) Compute collage rect (rotated image already computed)
            let collageRect = CGRect(x: collageX, y: topY - drawSize.height, width: drawSize.width, height: drawSize.height)

            // Draw the rotated collage image directly, no extra PDF background
            rotated.draw(in: collageRect)

            NSGraphicsContext.restoreGraphicsState()
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.pdf]
        panel.nameFieldStringValue = "PhotoBooth-A4.pdf"
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try pdfData.write(to: url)
                exportMessage = "Saved to \(url.path)"
            } catch {
                exportMessage = "Failed to save: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Camera Controller (AVCapturePhotoOutput)

final class CameraController: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()
    let objectWillChange = ObservableObjectPublisher()
    @Published var isRunning: Bool = false
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")

    @Published var devices: [AVCaptureDevice] = []
    @Published var currentDevice: AVCaptureDevice? = nil
    // Torch state
    @Published var isTorchOn: Bool = false
    @Published var torchLevel: Float = 0.6
    var isTorchAvailable: Bool { currentDevice?.hasTorch == true }

    var canCapture: Bool {
        guard session.isRunning else { return false }
        if let c = photoOutput.connection(with: .video) {
            return c.isEnabled && c.isActive
        }
        return photoOutput.connections.contains { $0.isEnabled && $0.isActive }
    }

    override init() {
        super.init()
    }

    private func configureIfNeeded() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        if session.inputs.isEmpty {
            if let device = AVCaptureDevice.default(for: .video),
               let input = try? AVCaptureDeviceInput(device: device),
               session.canAddInput(input) {
                session.addInput(input)
                currentDevice = device
            } else {
                print("Camera unavailable or cannot add input")
            }
        }
        if !session.outputs.contains(photoOutput) {
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
                photoOutput.isHighResolutionCaptureEnabled = true
            } else {
                print("Cannot add photo output")
            }
        }
        session.commitConfiguration()
    }

    func start() {
        sessionQueue.async {
            self.configureIfNeeded()
            self.refreshDevices()
            guard !self.session.isRunning else {
                DispatchQueue.main.async { self.isRunning = true }
                return
            }
            self.session.startRunning()
            DispatchQueue.main.async { self.isRunning = true }
        }
    }

    func stop() {
        sessionQueue.async {
            if self.session.isRunning { self.session.stopRunning() }
            DispatchQueue.main.async { self.isRunning = false }
        }
    }

    private var captureHandler: ((NSImage?) -> Void)?

    func capturePhoto(completion: @escaping (NSImage?) -> Void) {
        captureHandler = completion
        guard canCapture else {
            print("No active and enabled video connection; skipping capture.")
            DispatchQueue.main.async { completion(nil) }
            return
        }
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func refreshDevices() {
        let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .externalUnknown, .continuityCamera], mediaType: .video, position: .unspecified)
        let list = discovery.devices
        DispatchQueue.main.async { self.devices = list }
        if currentDevice == nil, let first = list.first {
            switchToDevice(first)
        }
    }

    func switchToDevice(withID id: String) {
        guard let dev = devices.first(where: { $0.uniqueID == id }) else { return }
        switchToDevice(dev)
    }

    private func switchToDevice(_ device: AVCaptureDevice) {
        sessionQueue.async {
            self.session.beginConfiguration()
            // remove existing video inputs
            for input in self.session.inputs {
                if let vin = input as? AVCaptureDeviceInput, vin.device.hasMediaType(.video) {
                    self.session.removeInput(vin)
                }
            }
            if let newInput = try? AVCaptureDeviceInput(device: device), self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
                self.currentDevice = device
            }
            self.session.commitConfiguration()
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }

    func setTorch(on: Bool, level: Float) {
        guard let dev = currentDevice, dev.hasTorch else { return }
        do {
            try dev.lockForConfiguration()
            if on {
                let lvl = max(0.1, min(level, 1.0))
                if dev.isTorchModeSupported(.on) {
                    try dev.setTorchModeOn(level: lvl)
                    isTorchOn = true
                    torchLevel = lvl
                }
            } else {
                dev.torchMode = .off
                isTorchOn = false
            }
            dev.unlockForConfiguration()
        } catch {
            print("Torch config error: \(error)")
        }
    }

    // AVCapturePhotoCaptureDelegate
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error { print("Capture error: \(error)") }
        if let data = photo.fileDataRepresentation(), let img = NSImage(data: data) {
            DispatchQueue.main.async { self.captureHandler?(img) }
        } else {
            DispatchQueue.main.async { self.captureHandler?(nil) }
        }
    }
}

// MARK: - Camera Preview (NSViewRepresentable)

struct CameraPreviewView: NSViewRepresentable {
    let session: AVCaptureSession

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        view.wantsLayer = true
        view.layer = layer
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView.layer as? AVCaptureVideoPreviewLayer)?.session = session
    }
}

// MARK: - Collage Renderer

enum CollageRenderer {
    static func makeVerticalCollage(
        photos: [NSImage],
        canvasSize: CGSize,
        spacing: CGFloat,
        insetTop: CGFloat,
        insetBottom: CGFloat,
        cornerRadius: CGFloat,
        borderWidth: CGFloat,
        background: NSImage?,
        mirror: Bool,
        cropToFourByThree: Bool,
        layoutMode: CollageLayoutMode
    ) -> NSImage {
        // Ensure exactly 3 images by trimming or repeating last
        let imgs = Array(photos.prefix(3)) + Array(repeating: photos.last ?? photos.first!, count: max(0, 3 - photos.count))
        let drawImgs: [NSImage] = mirror ? imgs.map { $0.mirroredHorizontally() } : imgs

        let image = NSImage(size: canvasSize, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

            // Background fill (if provided)
            if let bg = background {
                bg.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
                // add a slight overlay for contrast
                ctx.setFillColor(NSColor.black.withAlphaComponent(0.05).cgColor)
                ctx.fill(rect)
            } else {
                NSColor.windowBackgroundColor.setFill()
                ctx.fill(rect)
            }

            let slotAspect: CGFloat = 4.0 / 3.0
            let frames: [CGRect]
            switch layoutMode {
            case .simpleStrip:
                // Asymmetric outer margins: top and bottom can differ
                var inner = rect.insetBy(dx: insetTop, dy: 0)
                inner.origin.y = rect.minY + insetBottom
                inner.size.height = rect.height - insetTop - insetBottom

                let totalSpacing = spacing * 2
                let photoHeight = (inner.height - totalSpacing) / 3
                let photoWidth = inner.width
                frames = (0..<3).map { i in
                    let y = inner.minY + CGFloat(i) * (photoHeight + spacing)
                    return CGRect(x: inner.minX, y: y, width: photoWidth, height: photoHeight)
                }
            case .templateLayout:
                frames = templateFrameRects(in: rect)
            }

            for (index, frame) in frames.enumerated() {
                let img = drawImgs[index]

                // Path with corner radius
                let path = CGPath(roundedRect: frame, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
                ctx.addPath(path)
                ctx.clip()

                // Draw image scaled to fill
                if cropToFourByThree {
                    let cropRect = cropRect(for: img.size, to: slotAspect)
                    img.draw(in: frame, from: cropRect, operation: .sourceOver, fraction: 1)
                } else {
                    let fitted = aspectFillRect(for: img.size, in: frame)
                    img.draw(in: fitted)
                }

                // Restore clip for next pass
                ctx.resetClip()

                if borderWidth > 0 {
                    ctx.addPath(path)
                    ctx.setStrokeColor(NSColor.labelColor.withAlphaComponent(0.6).cgColor)
                    ctx.setLineWidth(borderWidth)
                    ctx.strokePath()
                }
            }

            return true
        }
        return image
    }

    private static let templateFrameRectsNormalized: [CGRect] = [
        CGRect(x: 0.153257, y: 0.047648, width: 0.691571, height: 0.199638),
        CGRect(x: 0.153257, y: 0.257539, width: 0.691571, height: 0.199638),
        CGRect(x: 0.153257, y: 0.467431, width: 0.691571, height: 0.199035)
    ]

    private static func templateFrameRects(in rect: CGRect) -> [CGRect] {
        templateFrameRectsNormalized.map { normalized in
            rectFromTopLeftNormalized(normalized, in: rect)
        }
    }

    private static func rectFromTopLeftNormalized(_ normalized: CGRect, in rect: CGRect) -> CGRect {
        let x = rect.minX + rect.width * normalized.minX
        let width = rect.width * normalized.width
        let height = rect.height * normalized.height
        let yFromTop = rect.minY + rect.height * normalized.minY
        let y = rect.maxY - yFromTop - height
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private static func aspectFillRect(for imageSize: CGSize, in target: CGRect) -> CGRect {
        let scale = max(target.width / imageSize.width, target.height / imageSize.height)
        let w = imageSize.width * scale
        let h = imageSize.height * scale
        let x = target.midX - w / 2
        let y = target.midY - h / 2
        return CGRect(x: x, y: y, width: w, height: h)
    }

    private static func cropRect(for imageSize: CGSize, to aspect: CGFloat) -> CGRect {
        let imageAspect = imageSize.width / imageSize.height
        if imageAspect > aspect {
            let newWidth = imageSize.height * aspect
            let x = (imageSize.width - newWidth) / 2
            return CGRect(x: x, y: 0, width: newWidth, height: imageSize.height)
        } else {
            let newHeight = imageSize.width / aspect
            let y = (imageSize.height - newHeight) / 2
            return CGRect(x: 0, y: y, width: imageSize.width, height: newHeight)
        }
    }
}

enum CollageLayoutMode: String, CaseIterable, Identifiable {
    case simpleStrip
    case templateLayout

    var id: String { rawValue }

    var title: String {
        switch self {
        case .simpleStrip:
            return "Simple strip"
        case .templateLayout:
            return "Template layout"
        }
    }
}

// MARK: - PDF Renderer

enum PDFRenderer {
    static func createA4PDF(draw: (CGContext) -> Void) -> Data {
        let a4 = CGRect(x: 0, y: 0, width: 595, height: 842) // 72 dpi
        let data = NSMutableData()
        let consumer = CGDataConsumer(data: data as CFMutableData)!
        var mediaBox = a4
        let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)!
        ctx.beginPDFPage(nil)
        draw(ctx)
        ctx.endPDFPage()
        ctx.closePDF()
        return data as Data
    }
}

// MARK: - NSImage helpers

extension NSImage {
    func rotated90(clockwise: Bool) -> NSImage {
        let newSize = CGSize(width: size.height, height: size.width)
        let img = NSImage(size: newSize)
        img.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else { img.unlockFocus(); return self }
        if clockwise {
            ctx.translateBy(x: newSize.width, y: 0)
            ctx.rotate(by: .pi / 2)
        } else {
            ctx.translateBy(x: 0, y: newSize.height)
            ctx.rotate(by: -.pi / 2)
        }
        draw(at: .zero, from: CGRect(origin: .zero, size: size), operation: .sourceOver, fraction: 1)
        img.unlockFocus()
        return img
    }

    func mirroredHorizontally() -> NSImage {
        let newSize = self.size
        let img = NSImage(size: newSize)
        img.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else { img.unlockFocus(); return self }
        ctx.translateBy(x: newSize.width, y: 0)
        ctx.scaleBy(x: -1, y: 1)
        self.draw(in: CGRect(origin: .zero, size: newSize), from: .zero, operation: .sourceOver, fraction: 1.0)
        img.unlockFocus()
        return img
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
