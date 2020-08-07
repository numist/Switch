//: [Previous](@previous)

import AppKit
import AVFoundation
import PlaygroundSupport
import ShortcutRecorder


extension NSRect {
    var center: NSPoint {
        return NSPoint(x: midX, y: midY)
    }
}


extension NSDeviceDescriptionKey {
    //: https://developer.apple.com/documentation/appkit/nsscreen/1388360-devicedescription
    static var screenNumber: NSDeviceDescriptionKey {
        return NSDeviceDescriptionKey("NSScreenNumber")
    }
}


extension CAKeyframeAnimation {
    //: Keyframe animation with total and step durations infered from the states argument.
    convenience init<T: Collection>(states: T) where T.Element == (key: Any, value: TimeInterval) {
        self.init()
        calculationMode = .discrete
        timingFunction = CAMediaTimingFunction(name: .linear)

        guard states.count > 0 else {
            return
        }

        let totalDuration = states.reduce(TimeInterval(0.0)) { (result, element) in result + element.value }
        duration = totalDuration

        var values: [Any] = []
        var keyTimes: [TimeInterval] = []
        var currentKeyTime: TimeInterval = 0.0

        for (key, value) in states {
            values.append(key)
            keyTimes.append(currentKeyTime / totalDuration)
            currentKeyTime += value
        }

        precondition(keyTimes.last! <= 1.0)

        keyTimes.append(1.0)

        self.values = values
        self.keyTimes = keyTimes as [NSNumber]
    }
}


typealias AnimationChanges = (_ context: NSAnimationContext) -> Void
typealias AnimationCompletion = () -> Void

//: Utility class to chain animations.
struct Animation {
    var beforeDelay: TimeInterval = 0
    var afterDelay: TimeInterval = 0
    var changes: AnimationChanges
    var completion: AnimationCompletion?

    init(beforeDelay: TimeInterval, afterDelay: TimeInterval, changes: @escaping AnimationChanges, completion: AnimationCompletion?)
    {
        self.beforeDelay = beforeDelay
        self.afterDelay = afterDelay
        self.changes = changes
        self.completion = completion
    }

    init(beforeDelay: TimeInterval, afterDelay: TimeInterval, changes: @escaping AnimationChanges) {
        self.init(beforeDelay: beforeDelay, afterDelay: afterDelay, changes: changes, completion: nil)
    }

    init(changes: @escaping AnimationChanges) {
        self.init(beforeDelay: 0, afterDelay: 0, changes: changes, completion: nil)
    }

    init(changes: @escaping AnimationChanges, completion: @escaping AnimationCompletion) {
        self.init(beforeDelay: 0, afterDelay: 0, changes: changes, completion: completion)
    }
}



@objc enum AnimatableRecorderControlState: Int {
    case disabled, enabled
    case pressed
    case recording, cancelPressed, clearPressed
}

//: Control modified to enforce visual appearance without user interaction.
class AnimatableRecorderControl: RecorderControl {
    @objc dynamic var animationState: AnimatableRecorderControlState = .enabled {
        didSet {
            if oldValue != animationState {
                updateActiveConstraints()
                needsDisplay = true
            }
        }
    }

    @objc dynamic var animationLabel: String? {
        didSet {
            if oldValue != animationLabel {
                needsDisplay = true
            }
        }
    }

    override var isMainButtonHighlighted: Bool {
        return super.isMainButtonHighlighted || animationState == .pressed
    }

    override var isCancelButtonHighlighted: Bool {
        return super.isCancelButtonHighlighted || animationState == .cancelPressed
    }

    override var isClearButtonHighlighted: Bool {
        return super.isClearButtonHighlighted || animationState == .clearPressed
    }

    override var isRecording: Bool {
        return super.isRecording || [.recording, .cancelPressed, .clearPressed].contains(animationState)
    }

    override var isEnabled: Bool {
        get {
            return super.isEnabled && animationState != .disabled
        }

        set {
            super.isEnabled = newValue
        }
    }

    override var drawingLabel: String {
        return animationLabel ?? super.drawingLabel
    }
}


//: View that draws standard macOS pointer arrow cursor.
class CursorView: NSView {
    override var intrinsicContentSize: NSSize {
        return NSCursor.arrow.image.size
    }

    override func updateLayer() {
        layer!.contents = NSCursor.arrow.image
    }

    override var wantsUpdateLayer: Bool {
        return true
    }

    func setPointerOrigin(_ newOrigin: NSPoint) {
        var newOrigin = newOrigin
        newOrigin.y -= 3
        newOrigin.x -= 3
        self.setFrameOrigin(newOrigin)
    }
}


//: View with recorder control and label styled for a given appearance.
class ShowcaseView: NSView {
    var recorder: AnimatableRecorderControl!
    var label: NSTextField!
    var cursor: CursorView!

    var recorderCenter: NSPoint {
        return recorder.convert(recorder.style.labelDrawingGuide.frame, to: self).center
    }

    var cancelButtonCenter: NSPoint {
        return recorder.convert(recorder.style.cancelButtonDrawingGuide!.frame, to: self).center
    }

    var clearButtonCenter: NSPoint {
        return recorder.convert(recorder.style.clearButtonDrawingGuide!.frame, to: self).center
    }

    convenience init(labelString: String, appearance: NSAppearance.Name) {
        self.init()

        wantsLayer = true
        self.appearance = NSAppearance(named: appearance)

        label = NSTextField(labelWithString: labelString)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        recorder = AnimatableRecorderControl()
        recorder.translatesAutoresizingMaskIntoConstraints = false
        addSubview(recorder)

        cursor = CursorView()
        cursor.setFrameSize(cursor.intrinsicContentSize)
        cursor.isHidden = true
        addSubview(cursor)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            label.centerXAnchor.constraint(equalTo: recorder.centerXAnchor),
            recorder.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
            recorder.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            recorder.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            recorder.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }

    override func updateLayer() {
        layer!.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }

    override var wantsUpdateLayer: Bool {
        return true
    }

    override var isFlipped: Bool {
        return true
    }
}


class SceneView: NSView, AVCaptureFileOutputRecordingDelegate {
    var showcaseViews: [ShowcaseView]!
    var gridView: NSGridView!
    var captureSession: AVCaptureSession = AVCaptureSession()

    let videoURL = URL(fileURLWithPath: "/tmp/sr.mov")
    let gifURL = URL(fileURLWithPath: "/tmp/sr.gif")

    convenience init() {
        self.init(frame: NSZeroRect)
        self.translatesAutoresizingMaskIntoConstraints = false

        let accComponents = RecorderControlStyle.Components(appearance: .unspecified,
                                                            accessibility: .highContrast,
                                                            layoutDirection: .unspecified,
                                                            tint: .unspecified)
        let accStyle = RecorderControlStyle(identifier: nil, components: accComponents)

        let aquaView = ShowcaseView(labelString: "Aqua", appearance: .aqua)
        aquaView.appearance = NSAppearance(named: .aqua)

        let aquaAccView = ShowcaseView(labelString: "Aqua High Contrast", appearance: .aqua)
        aquaAccView.appearance = NSAppearance(named: .aqua)
        aquaAccView.recorder.style = accStyle

        let darkView = ShowcaseView(labelString: "Dark Aqua", appearance: .aqua)
        darkView.appearance = NSAppearance(named: .darkAqua)

        let darkAccView = ShowcaseView(labelString: "Dark Aqua High Contrast", appearance: .aqua)
        darkAccView.appearance = NSAppearance(named: .darkAqua)
        darkAccView.recorder.style = accStyle

        gridView = NSGridView(views: [[aquaView, darkView], [aquaAccView, darkAccView]])
        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.rowSpacing = 1
        gridView.columnSpacing = 1
        addSubview(gridView)

        showcaseViews = [aquaView, darkView, aquaAccView, darkAccView]

        NSLayoutConstraint.activate([
            gridView.topAnchor.constraint(equalTo: topAnchor),
            gridView.leftAnchor.constraint(equalTo: leftAnchor),
            gridView.widthAnchor.constraint(equalTo: widthAnchor),
            gridView.heightAnchor.constraint(equalTo: heightAnchor)
        ])
    }

    deinit {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(SceneView.startRecording), object: nil)
    }

    //: Start recording once window gets its final frame.
    func startRecordingWhenReady() {
        NotificationCenter.default.addObserver(self, selector: #selector(SceneView.scheduleStartRecording), name: NSWindow.didMoveNotification, object: window!)
    }

    @objc private func startRecording() {
        NotificationCenter.default.removeObserver(self, name: NSWindow.didMoveNotification, object: window!)

        captureSession.beginConfiguration()
        let displayID = window!.screen!.deviceDescription[.screenNumber] as! CGDirectDisplayID
        let screenInput = AVCaptureScreenInput(displayID: displayID)!
        screenInput.capturesCursor = false
        screenInput.minFrameDuration = CMTime(value: 1, timescale: 60)
        screenInput.cropRect = window!.convertToScreen(convert(gridView.frame, to: nil))
        captureSession.addInput(screenInput)
        let fileOutput = AVCaptureMovieFileOutput()
        captureSession.addOutput(fileOutput)
        captureSession.commitConfiguration()
        captureSession.startRunning()
        try? FileManager.default.removeItem(at: videoURL)
        fileOutput.startRecording(to: videoURL, recordingDelegate: self)
    }

    @objc private func scheduleStartRecording() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(SceneView.startRecording), object: nil)
        perform(#selector(SceneView.startRecording), with: nil, afterDelay: 0.1)
    }

    func startAnimation() {
        let mousePressDuration: TimeInterval = 0.25
        let mouseMoveTotalDuration: TimeInterval = 2.5 // Total duration to move the mouse horizontally from one side to another
        let holdStateDuration: TimeInterval = 0.5
        let keyPressDuration: TimeInterval = 0.5

        /// Assumes that bounds of all showcase views are almost identical.
        let referenceView = showcaseViews.last!

        func mouseMoveDuration(_ to: CGFloat) -> TimeInterval {
            let currentX = referenceView.cursor.frame.minX
            return mouseMoveTotalDuration * Double((to - currentX).magnitude / referenceView.bounds.width)
        }

        func animateMouseMove(context: NSAnimationContext, to: NSPoint) {
            context.duration = mouseMoveDuration(to.x)
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            context.allowsImplicitAnimation = true
            showcaseViews.forEach { (view) in
                view.cursor.setPointerOrigin(to)
            }
        }

        func animateRecorderStateTransition(context: NSAnimationContext,
                                            interimStates: KeyValuePairs<AnimatableRecorderControlState, TimeInterval>,
                                            targetState: AnimatableRecorderControlState) {
            let animation = CAKeyframeAnimation(states: interimStates.map { e in (e.key.rawValue, e.value) })
            showcaseViews.forEach { (view) in
                view.recorder.animations = ["animationState": animation]
                view.recorder.animator().animationState = targetState
            }
        }

        let enableRecorderAnimation = Animation(beforeDelay: 1, afterDelay: 0) { (context) in
            animateRecorderStateTransition(context: context,
                                           interimStates: [.disabled: holdStateDuration,
                                                           .enabled: holdStateDuration],
                                           targetState: .enabled)
        }

        let moveMouseInAnimation = Animation { (context) in
            animateMouseMove(context: context, to: referenceView.recorderCenter)
        }

        let pressRecorderAnimation = Animation { (context) in
            animateRecorderStateTransition(context: context,
                                           interimStates: [.enabled: holdStateDuration,
                                                           .pressed: mousePressDuration,
                                                           .recording: holdStateDuration],
                                           targetState: .recording)
        }

        let typeInAnimation = Animation(beforeDelay: 0, afterDelay: holdStateDuration, changes: { (context) in
            self.showcaseViews.forEach { (view) in
                view.cursor.isHidden = true
                let states: KeyValuePairs = [
                    "⌃": keyPressDuration,
                    "⌃⌥": keyPressDuration,
                    "⌃⌥⇧": keyPressDuration,
                    "⌃⌥⇧⌘": keyPressDuration,
                    "⌃⌥⇧⌘A": 0
                ]
                let animation = CAKeyframeAnimation(states: states.map { e in (e.key, e.value) })
                view.recorder.animations = ["animationLabel": animation]
                view.recorder.animator().animationLabel = "⌃⌥⇧⌘A"
            }
        }, completion: {
            self.showcaseViews.forEach { (view) in
                view.recorder.animationState = .enabled
                view.recorder.objectValue = Shortcut(keyEquivalent: "⌃⌥⇧⌘A")
                view.recorder.animationLabel = nil
                view.cursor.isHidden = false
            }
        })

        let moveMouseToCancelAnimation = Animation { (context) in
            animateMouseMove(context: context, to: referenceView.cancelButtonCenter)
        }

        let pressCancelAnimation = Animation { (context) in
            animateRecorderStateTransition(context: context,
                                           interimStates: [.recording: holdStateDuration,
                                                           .cancelPressed: mousePressDuration,
                                                           .enabled: holdStateDuration],
                                           targetState: .enabled)
        }

        let moveMouseToClearAnimation = Animation { (context) in
            animateMouseMove(context: context, to: referenceView.clearButtonCenter)
        }

        let pressClearAnimation = Animation(beforeDelay: 0, afterDelay: holdStateDuration, changes: { (context) in
            animateRecorderStateTransition(context: context,
                                           interimStates: [.recording: holdStateDuration,
                                                           .clearPressed: mousePressDuration],
                                           targetState: .clearPressed)
        }, completion: {
            self.showcaseViews.forEach { (view) in
                view.recorder.objectValue = nil
                view.recorder.animationState = .enabled
            }
        })

        let moveMouseOutAnimation = Animation { (context) in
            context.duration = mouseMoveDuration(referenceView.bounds.maxX)
            context.timingFunction = CAMediaTimingFunction(name: .linear)
            self.showcaseViews.forEach { (v) in
                v.cursor.animator().setFrameOrigin(NSPoint(x: v.bounds.maxX, y: v.cursor.frame.minY))
            }
        }

        var animations = [
            enableRecorderAnimation,
            moveMouseInAnimation,
            pressRecorderAnimation,
            typeInAnimation,
            pressRecorderAnimation,
            moveMouseToCancelAnimation,
            pressCancelAnimation,
            pressRecorderAnimation,
            moveMouseToClearAnimation,
            pressClearAnimation,
            moveMouseOutAnimation
        ]

        // Run animations one after another with respect to the specified delays.
        func animate() {
            guard !animations.isEmpty else {
                if let fileOutput = self.captureSession.outputs.last as? AVCaptureMovieFileOutput {
                    DispatchQueue.main.asyncAfter(deadline: .now() + holdStateDuration) {
                        fileOutput.stopRecording()
                    }
                }
                return
            }

            let nextAnimation = animations.removeFirst()

            DispatchQueue.main.asyncAfter(deadline: .now() + nextAnimation.beforeDelay) {
                NSAnimationContext.runAnimationGroup({ (context) in
                    nextAnimation.changes(context)
                }) {
                    if let completion = nextAnimation.completion {
                        completion()
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + nextAnimation.afterDelay) {
                        animate()
                    }
                }
            }
        }

        showcaseViews.forEach { (v) in
            v.cursor.setFrameOrigin(NSPoint(x: -v.cursor.frame.width, y: referenceView.recorderCenter.y))
            v.cursor.isHidden = false
            v.recorder.animationState = .disabled
        }

        animate()
    }

    func startEncoding() {
        let task = try! NSUserUnixTask(url: URL(fileURLWithPath: "/usr/local/bin/ffmpeg"))
        let scale = (self.gridView.frame.width * 1.5).rounded()
        let args = [
            "-y",
            "-i", self.videoURL.absoluteString,
            "-vf", "fps=24,scale=\(scale):-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse",
            "-loop", "0",
            self.gifURL.absoluteString
        ]
        task.execute(withArguments: args) { (error) in
            guard error == nil else {
                print("failed to encode:", error!)
                return
            }

            print("finished encoding")
            NSWorkspace.shared.activateFileViewerSelecting([self.gifURL])
        }
    }

    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("started recording")

        DispatchQueue.main.async {
            self.startAnimation()
        }
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        captureSession.stopRunning()

        guard error == nil else {
            print("failed to record:", error!)
            return
        }

        print("finished recording")
        DispatchQueue.main.async {
            print("started encoding")
            self.startEncoding()
        }
    }
}

PlaygroundPage.current.needsIndefiniteExecution = true
let mainView = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 500))
PlaygroundPage.current.liveView = mainView

let sceneView = SceneView()
mainView.addSubview(sceneView)
NSLayoutConstraint.activate([
    mainView.widthAnchor.constraint(equalToConstant: mainView.frame.width),
    mainView.heightAnchor.constraint(equalToConstant: mainView.frame.height),
    sceneView.centerXAnchor.constraint(equalTo: mainView.centerXAnchor),
    sceneView.centerYAnchor.constraint(equalTo: mainView.centerYAnchor)
])

// Make sure the live view is shown and is big enough. Do not occlude it as this is a screen recoding under the hood.
sceneView.startRecordingWhenReady()

//: [Next](@next)
