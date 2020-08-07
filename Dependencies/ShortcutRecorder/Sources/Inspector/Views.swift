//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 4.0
//

import Cocoa
import Foundation

import ShortcutRecorder


extension NSEdgeInsets {
    var horizontal: CGFloat {
        return left + right
    }

    var vertical: CGFloat {
        return top + bottom
    }
}


extension NSView {
    static var drawsChessboardToken = "drawsCheckboard"
    static var chessboardPrimaryColorToken = "chessboardPrimaryColor"
    static var chessboardSecondaryColorToken = "chessboardSecondaryColor"

    static var drawsBaselineToken = "drawsBaseline"
    static var baselinePrimaryColorToken = "baselinePrimaryColor"
    static var baselineSecondaryColorToken = "baselineSecondaryColor"

    static var drawsAlignmentRectToken = "drawsAlignmentRect"
    static var alignmentRectColorToken = "alignmentRectColor"

    static var scaleToken = "scale"

    @objc var drawsChessboard: Bool {
        get {
            return objc_getAssociatedObject(self, &NSView.drawsChessboardToken) as? Bool ?? false
        }

        set {
            objc_setAssociatedObject(self, &NSView.drawsChessboardToken, newValue, .OBJC_ASSOCIATION_ASSIGN)
            needsDisplay = true
        }
    }

    @objc var chessboardPrimaryColor: NSColor {
        get {
            return objc_getAssociatedObject(self, &NSView.chessboardPrimaryColorToken) as? NSColor ?? NSColor.textBackgroundColor
        }

        set {
            objc_setAssociatedObject(self, &NSView.chessboardPrimaryColorToken, newValue, .OBJC_ASSOCIATION_RETAIN)
            needsDisplay = true
        }
    }

    @objc var chessboardSecondaryColor: NSColor {
        get {
            return objc_getAssociatedObject(self, &NSView.chessboardSecondaryColorToken) as? NSColor ?? NSColor.tertiaryLabelColor
        }

        set {
            objc_setAssociatedObject(self, &NSView.chessboardSecondaryColorToken, newValue, .OBJC_ASSOCIATION_RETAIN)
            needsDisplay = true
        }
    }

    @objc var drawsBaseline: Bool {
        get {
            return objc_getAssociatedObject(self, &NSView.drawsBaselineToken) as? Bool ?? false
        }

        set {
            objc_setAssociatedObject(self, &NSView.drawsBaselineToken, newValue, .OBJC_ASSOCIATION_ASSIGN)
            needsDisplay = true
        }
    }

    @objc var baselinePrimaryColor: NSColor {
        get {
            return objc_getAssociatedObject(self, &NSView.baselinePrimaryColorToken) as? NSColor ?? NSColor.red
        }

        set {
            objc_setAssociatedObject(self, &NSView.baselinePrimaryColorToken, newValue, .OBJC_ASSOCIATION_RETAIN)
            needsDisplay = true
        }
    }

    @objc var baselineSecondaryColor: NSColor {
        get {
            return objc_getAssociatedObject(self, &NSView.baselineSecondaryColorToken) as? NSColor ?? NSColor.blue
        }

        set {
            objc_setAssociatedObject(self, &NSView.baselineSecondaryColorToken, newValue, .OBJC_ASSOCIATION_RETAIN)
            needsDisplay = true
        }
    }

    @objc var drawsAlignmentRect: Bool {
        get {
            return objc_getAssociatedObject(self, &NSView.drawsAlignmentRectToken) as? Bool ?? false
        }

        set {
            objc_setAssociatedObject(self, &NSView.drawsAlignmentRectToken, newValue, .OBJC_ASSOCIATION_ASSIGN)
            needsDisplay = true
        }
    }

    @objc var alignmentRectColor: NSColor {
        get {
            return objc_getAssociatedObject(self, &NSView.alignmentRectColorToken) as? NSColor ?? NSColor.red
        }

        set {
            objc_setAssociatedObject(self, &NSView.alignmentRectColorToken, newValue, .OBJC_ASSOCIATION_RETAIN)
            needsDisplay = true
        }
    }

    @objc var scale: CGFloat {
        get {
            return objc_getAssociatedObject(self, &NSView.scaleToken) as? CGFloat ?? 2.0
        }

        set {
            objc_setAssociatedObject(self, &NSView.scaleToken, newValue, .OBJC_ASSOCIATION_ASSIGN)
            needsDisplay = true
        }
    }

    func withScaledContext(scale: CGFloat, drawer: () -> Void) {
        NSGraphicsContext.saveGraphicsState()
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                   pixelsWide: Int(bounds.size.width * scale),
                                   pixelsHigh: Int(bounds.size.height * scale),
                                   bitsPerSample: 8,
                                   samplesPerPixel: 4,
                                   hasAlpha: true,
                                   isPlanar: false,
                                   colorSpaceName: .calibratedRGB,
                                   bytesPerRow: 0,
                                   bitsPerPixel: 0)!
        rep.size = bounds.size
        rep.setCompression(.none, factor: 1.0)
        NSGraphicsContext.current = NSGraphicsContext(cgContext: NSGraphicsContext(bitmapImageRep: rep)!.cgContext, flipped: isFlipped)
        drawer()
        NSGraphicsContext.restoreGraphicsState()

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current!.imageInterpolation = .none
        rep.draw(in: bounds, from: .zero, operation: .sourceOver, fraction: 1.0, respectFlipped: false, hints: nil)
        NSGraphicsContext.restoreGraphicsState()
    }

    /// Draw a line along the pixels directly above the baseline.
    func drawBaseline(with operation: NSCompositingOperation = .sourceAtop) {
        #if TARGET_INTERFACE_BUILDER
        return
        #endif
        
        precondition(isFlipped)

        NSGraphicsContext.saveGraphicsState()
        defer {
            NSGraphicsContext.restoreGraphicsState()
        }

        NSGraphicsContext.current?.cgContext.setAlpha(0.5)

        baselinePrimaryColor.setFill()
        let offset = alignmentRectInsets.top + firstBaselineOffsetFromTop
        let pixelSize = 1.0 / backingScaleFactor()
        let rect = NSRect(x: 0.0, y: offset - pixelSize, width: bounds.width, height: pixelSize)
        rect.fill(using: operation)
    }

    /// Fill a frame directly within alignment insets.
    func drawAlignmentRect(with operation: NSCompositingOperation = .sourceOver) {
        #if TARGET_INTERFACE_BUILDER
        return
        #endif

        precondition(isFlipped)

        NSGraphicsContext.saveGraphicsState()
        defer {
            NSGraphicsContext.restoreGraphicsState()
        }

        NSGraphicsContext.current?.cgContext.setAlpha(0.25)

        baselineSecondaryColor.setFill()
        bounds.fill()

        alignmentRectColor.setFill()
        NSRect(x: alignmentRectInsets.left,
               y: alignmentRectInsets.top,
               width: bounds.width - alignmentRectInsets.horizontal,
               height: bounds.height - alignmentRectInsets.vertical).fill(using: operation)
    }

    func drawPixelChessboard(squareSize: NSSize = NSSize(width: 1.0, height: 1.0), operation: NSCompositingOperation = .sourceAtop) {
        #if TARGET_INTERFACE_BUILDER
        return
        #endif

        NSGraphicsContext.saveGraphicsState()
        defer {
            NSGraphicsContext.restoreGraphicsState()
        }

        NSGraphicsContext.current?.cgContext.setAlpha(0.5)

        let patternSize = NSSize(width: squareSize.width * 2.0, height: squareSize.height * 2.0)
        let patternImage = NSImage(size: patternSize, flipped: false) { (rect) -> Bool in
            for y in stride(from: 0.0, to: rect.height, by: squareSize.height) {
                var isSecondary = !y.truncatingRemainder(dividingBy: 2 * squareSize.height).isEqual(to: 0.0)
                for x in stride(from: 0.0, to: rect.width, by: squareSize.width) {
                    (isSecondary ? self.chessboardSecondaryColor : self.chessboardPrimaryColor).setFill()
                    NSRect(x: x, y: y, width: squareSize.width, height: squareSize.height).fill(using: .sourceOver)
                    isSecondary = !isSecondary
                }
            }
            return true
        }
        let patternColor = NSColor(patternImage: patternImage)
        patternColor.setFill()

        var rects: UnsafePointer<NSRect>!
        var count = Int()
        getRectsBeingDrawn(&rects, count: &count)

        for i in 0..<count {
            let dirtyRect = rects[i]
            let xFrom = (dirtyRect.minX / patternSize.width).rounded(.down) * patternSize.width
            let xTo = (dirtyRect.maxX / patternSize.width).rounded(.up) * patternSize.width
            let yFrom = (dirtyRect.minY / patternSize.height).rounded(.down) * patternSize.height
            let yTo = (dirtyRect.maxY / patternSize.height).rounded(.up) * patternSize.height

            NSRect(x: xFrom, y: yFrom, width: xTo - xFrom, height: yTo - yFrom).fill(using: operation)
        }
    }

    func backingScaleFactor() -> CGFloat {
        let deviceSize = NSGraphicsContext.current?.cgContext.convertToDeviceSpace(NSMakeSize(1.0, 1.0))

        if let scaleFactor = deviceSize?.width {
            return scaleFactor
        }
        else {
            return 1.0
        }
    }
}


@IBDesignable
class ScaledRecorderControl: RecorderControl {
    override func draw(_ dirtyRect: NSRect) {
        withScaledContext(scale: scale) {
            super.draw(dirtyRect)

            if drawsAlignmentRect {
                self.drawAlignmentRect()
            }

            if drawsBaseline {
                self.drawBaseline()
            }

            if drawsChessboard {
                let scaleFactor = self.backingScaleFactor()
                self.drawPixelChessboard(squareSize: NSSize(width: 1.0 / scaleFactor, height: 1.0 / scaleFactor))
            }
        }
    }

    override func drawFocusRingMask() {
        // No focus ring.
    }
}


@IBDesignable
class ScaledButton: NSButton {
    override func draw(_ dirtyRect: NSRect) {
        withScaledContext(scale: scale) {
            super.draw(dirtyRect)

            if drawsAlignmentRect {
                self.drawAlignmentRect()
            }

            if drawsBaseline {
                self.drawBaseline()
            }

            if drawsChessboard {
                let scaleFactor = self.backingScaleFactor()
                self.drawPixelChessboard(squareSize: NSSize(width: 1.0 / scaleFactor, height: 1.0 / scaleFactor))
            }
        }
    }

    override var attributedTitle: NSAttributedString {
        get {
            return super.attributedTitle
        }

        set {
            super.attributedTitle = newValue
        }
    }
}


@IBDesignable
class ScaledTextField: NSTextField {
    override func draw(_ dirtyRect: NSRect) {
        withScaledContext(scale: scale) {
            super.draw(dirtyRect)

            if drawsAlignmentRect {
                drawAlignmentRect()
            }

            if drawsBaseline {
                if isBezeled {
                    self.drawBaseline(with: .sourceAtop)
                }
                else {
                    self.drawBaseline(with: .sourceOver)
                }
            }

            if drawsChessboard {
                let backingScaleFactor = self.backingScaleFactor()
                let squareSize = NSSize(width: 1.0 / backingScaleFactor, height: 1.0 / backingScaleFactor)
                self.drawPixelChessboard(squareSize: squareSize, operation: .sourceAtop)
            }
        }
    }
}


class ScaledChessboardView: NSView {
    var zoom: CGFloat = 1.0 {
        didSet {
            let factor = zoom / oldValue
            scaleUnitSquare(to: NSSize(width: factor, height: factor))
            centerBoundsOrigin()
            needsDisplay = true
        }
    }

    func centerBoundsOrigin() {
        setBoundsOrigin(NSPoint(x: (frame.width - bounds.width) / 2.0, y: (frame.height - bounds.height) / 2.0))
    }

    override func draw(_ dirtyRect: NSRect) {
        if drawsChessboard {
            let squareSize = NSSize(width: 1.0 / scale, height: 1.0 / scale)
            self.drawPixelChessboard(squareSize: squareSize, operation: .sourceOver)
        }

        super.draw(dirtyRect)
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        centerBoundsOrigin()
    }

    override func setBoundsSize(_ newSize: NSSize) {
        super.setBoundsSize(newSize)
        centerBoundsOrigin()
    }
}
