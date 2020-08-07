//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 4.0
//

import Cocoa

import ShortcutRecorder


extension RecorderControlStyle.Components.Appearance {
    var systemRepresentation: NSAppearance {
        switch self {
        case .aqua:
            return NSAppearance(named: .aqua)!
        case .vibrantLight:
            return NSAppearance(named: .vibrantLight)!
        case .vibrantDark:
            return NSAppearance(named: .vibrantDark)!
        case .darkAqua:
            if #available(OSX 10.14, *) {
                return NSAppearance(named: .darkAqua)!
            } else {
                return NSAppearance.current
            }

        case .unspecified:
            fallthrough
        @unknown default:
            fatalError("Fix Me")
        }
    }
}


extension RecorderControlStyle.Components.LayoutDirection {
    var systemRepresentation: NSUserInterfaceLayoutDirection {
        switch self {
        case .leftToRight:
            return .leftToRight
        case .rightToLeft:
            return .rightToLeft

        case .unspecified:
            fallthrough
        @unknown default:
            fatalError("Fix Me")
        }
    }
}


extension RecorderControlStyle {
    var dictionaryRepresentation: [String: Any] {
        var d: [String: Any] = ["identifier": identifier]
        d.merge(preferredComponents.dictionaryRepresentation) { (current, _) in current }
        return d
    }

    convenience init(fromDictionaryRepresentation aDict: [String: Any]) {
        self.init(identifier: aDict["identifier"] as? String,
                  components: Components(fromDictionaryRepresentatio: aDict))
    }
}


extension RecorderControlStyle.Components {
    var dictionaryRepresentation: [String: Any] {
        return [
            "appearance": appearance.rawValue,
            "tint": tint.rawValue,
            "accessibility": accessibility.rawValue,
            "layoutDirection": layoutDirection.rawValue
        ]
    }

    convenience init(fromDictionaryRepresentatio aDict: [String: Any]) {
        let appearance = Appearance(rawValue: aDict["appearance"] as? UInt ?? 0)!
        let tint = Tint(rawValue: aDict["tint"] as? UInt ?? 0)!
        let accessibility = Accessibility(rawValue: aDict["accessibility"] as? UInt ?? 0)
        let layoutDirection = LayoutDirection(rawValue: aDict["layoutDirection"] as? UInt ?? 0)!
        self.init(appearance: appearance, accessibility: accessibility, layoutDirection: layoutDirection, tint: tint)
    }
}


extension NSView {
    func xAnchorForTag(_ tag: AnchorTag) -> NSLayoutXAxisAnchor? {
        switch tag {
        case .leading:
            return self.leadingAnchor
        case .xCenter:
            return self.centerXAnchor
        case .trailing:
            return self.trailingAnchor
        default:
            return nil
        }
    }

    func yAnchorForTag(_ tag: AnchorTag) -> NSLayoutYAxisAnchor? {
        switch tag {
        case .top:
            return self.topAnchor
        case .yCenter:
            return self.centerYAnchor
        case .firstBaseline:
            return self.firstBaselineAnchor
        case .bottom:
            return self.bottomAnchor
        default:
            return nil
        }
    }
}


/// Animation of style, layout and scale changes.
struct Animation {
    typealias Appearance = RecorderControlStyle.Components.Appearance
    typealias Accessibility = RecorderControlStyle.Components.Accessibility

    typealias StyleFragment = (appearance: Appearance, accessibility: Accessibility, isEnabled: Bool)
    typealias AnchorFragment = (x: AnchorTag, y: AnchorTag)
    typealias ScaleFragment = Int
    typealias Frame = (style: StyleFragment?, anchors: AnchorFragment?, scale: ScaleFragment?)

    let styles: [StyleFragment] = [
        (.aqua, [.none], false),
        (.aqua, [.none], true),
        (.aqua, [.highContrast], false),
        (.aqua, [.highContrast], true),
        (.darkAqua, [.none], false),
        (.darkAqua, [.none], true),
        (.darkAqua, [.highContrast], false),
        (.darkAqua, [.highContrast], true),
    ]
    let anchors: [AnchorFragment] = [
        (.leading, .top),
        (.xCenter, .firstBaseline),
        (.trailing, .bottom)
    ]
    let scales: [ScaleFragment] = [1, 2]

    var state: (style: Array<StyleFragment>.Iterator, anchor: Array<AnchorFragment>.Iterator, scale: Array<ScaleFragment>.Iterator)
    var frame: Frame = (nil, nil, nil)

    init() {
        state = (styles.makeIterator(), anchors.makeIterator(), scales.makeIterator())
    }

    mutating func next(allowStyle: Bool = true, allowLayout: Bool = true, allowScale: Bool = true) -> Frame {
        var overflow = true
        var scale: ScaleFragment?
        var anchor: AnchorFragment?
        var style: StyleFragment?

        if overflow && allowScale {
            if let newScale = state.scale.next() {
                scale = newScale
                overflow = false
            }
            else {
                state.scale = scales.makeIterator()
                scale = state.scale.next()
            }
        }

        if overflow && allowLayout {
            if let newAnchors = state.anchor.next() {
                anchor = newAnchors
                overflow = false
            }
            else {
                state.anchor = anchors.makeIterator()
                anchor = state.anchor.next()
            }
        }

        if overflow && allowStyle {
            if let newStyle = state.style.next() {
                style = newStyle
                overflow = false
            }
            else {
                state.style = styles.makeIterator()
                style = state.style.next()
            }
        }

        return Frame(style, anchor, scale)
    }
}


class LayoutInspectorController: NSViewController {
    @IBOutlet weak var scaledView: ScaledChessboardView!
    @IBOutlet weak var recorderControl: ScaledRecorderControl!

    @IBOutlet weak var scaledWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var scaledHeightConstraint: NSLayoutConstraint!

    @IBOutlet var button: ScaledButton!
    @IBOutlet var label: ScaledTextField!
    @IBOutlet var textField: ScaledTextField!

    @objc dynamic var style: [String: Any]! {
        didSet {
            updateRecorderControlStyle()
        }
    }

    @objc dynamic var animateStyle: Bool = false { didSet { resetAnimation() } }
    @objc dynamic var animateScale: Bool = false { didSet { resetAnimation() } }
    @objc dynamic var animateLayout: Bool = false { didSet { resetAnimation() } }
    @objc dynamic var animationSpeed: Int = 2 { didSet { resetAnimation() } }
    var animationTimer: Timer?
    var animation = Animation()

    weak var control: NSControl!
    var xConstraint: NSLayoutConstraint?
    var yConstraint: NSLayoutConstraint?

    var recorderControlValueObserver: NSKeyValueObservation!
    var controlTagObserver: NSKeyValueObservation!
    var controlXAnchorTagObserver: NSKeyValueObservation!
    var controlXAnchorConstantObserver: NSKeyValueObservation!
    var controlYAnchorTagObserver: NSKeyValueObservation!
    var controlYAnchorConstantObserver: NSKeyValueObservation!
    var recorderControlXAnchorTagObserver: NSKeyValueObservation!
    var recorderControlYAnchorTagObserver: NSKeyValueObservation!
    var assetScaleTagObserver: NSKeyValueObservation!
    var controlAlphaObserver: NSKeyValueObservation!
    var controlDrawsChessboardObserver: NSKeyValueObservation!
    var controlDrawsBaselineObserver: NSKeyValueObservation!
    var controlDrawsAlignmentRectObserver: NSKeyValueObservation!
    var controlZoomObserver: NSKeyValueObservation!

    deinit {
        animationTimer?.invalidate()
    }
    
    func updateRecorderControlStyle() {
        recorderControl.style = RecorderControlStyle(fromDictionaryRepresentation: style)
        let components = recorderControl.style.preferredComponents!

        if components.appearance != .unspecified {
            view.window?.appearance = components.appearance.systemRepresentation
        }
        else {
            // Let window inherite its appearance from the system.
            view.window?.appearance = nil
        }
    }

    func updateXAnchors(_ defaults: UserDefaults, _ change: NSKeyValueObservedChange<Int>? = nil) {
        xConstraint?.isActive = false
        let controlAnchor = control.xAnchorForTag(AnchorTag(rawValue: defaults.controlXAnchorTag)!)!
        let recorderControlAnchor = recorderControl.xAnchorForTag(AnchorTag(rawValue: defaults.recorderControlXAnchorTag)!)!
        xConstraint = controlAnchor.constraint(equalTo: recorderControlAnchor, constant: defaults.controlXAnchorConstant)
        xConstraint!.isActive = true
    }

    func updateYAnchors(_ defaults: UserDefaults, _ change: NSKeyValueObservedChange<Int>? = nil) {
        yConstraint?.isActive = false
        let controlAnchor = control.yAnchorForTag(AnchorTag(rawValue: defaults.controlYAnchorTag)!)!
        let recorderControlAnchor = recorderControl.yAnchorForTag(AnchorTag(rawValue: defaults.recorderControlYAnchorTag)!)!
        yConstraint = controlAnchor.constraint(equalTo: recorderControlAnchor, constant: defaults.controlYAnchorConstant)
        yConstraint!.isActive = true
    }

    func resetAnimation() {
        animationTimer?.invalidate()

        if animateStyle || animateLayout || animateScale {
            animationTimer = Timer.scheduledTimer(timeInterval: TimeInterval(animationSpeed),
                                                  target: self,
                                                  selector: #selector(nextAnimationFrame),
                                                  userInfo: nil,
                                                  repeats: true)
            animationTimer!.fire()
        }
    }

    @objc func nextAnimationFrame() {
        let nextFrame = animation.next(allowStyle: animateStyle,
                                       allowLayout: animateLayout,
                                       allowScale: animateScale)

        let defaults = UserDefaults.standard

        if let (appearance, accessibility, isEnabled) = nextFrame.style {
            let styleUpdate: [String : Any] = [
                "appearance": appearance.rawValue,
                "accessibility": accessibility.rawValue
            ]
            self.style = self.style.merging(styleUpdate) { (_, new) in new }
            defaults.isEnabled = isEnabled
        }

        if let (xAnchor, yAnchor) = nextFrame.anchors {
            defaults.controlXAnchorTag = xAnchor.rawValue
            defaults.controlYAnchorTag = yAnchor.rawValue
            defaults.recorderControlXAnchorTag = xAnchor.rawValue
            defaults.recorderControlYAnchorTag = yAnchor.rawValue
        }

        if let scale = nextFrame.scale {
            defaults.assetScaleTag = scale
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        recorderControl.bind(.enabled, to: UserDefaults.standard, withKeyPath: Setting.isEnabled.rawValue, options: nil)

        let defaults = UserDefaults.standard

        controlZoomObserver = defaults.observe(\.controlZoom, options: [.initial, .new]) { (_, change) in
            self.scaledView.zoom = CGFloat(change.newValue!)
        }

        controlTagObserver = defaults.observe(\.controlTag, options: [.initial, .new]) { (_, change) in
            self.control?.removeFromSuperview()

            switch ControlTag(rawValue: change.newValue!)! {
            case .button:
                self.control = self.button
            case .label:
                self.control = self.label
            case .textField:
                self.control = self.textField
            }

            self.scaledView.addSubview(self.control)
            self.updateXAnchors(UserDefaults.standard)
            self.updateYAnchors(UserDefaults.standard)
        }

        controlXAnchorTagObserver = defaults.observe(\.controlXAnchorTag, options: [.new], changeHandler: updateXAnchors)
        recorderControlXAnchorTagObserver = defaults.observe(\.recorderControlXAnchorTag, options: [.new], changeHandler: updateXAnchors)
        controlYAnchorTagObserver = defaults.observe(\.controlYAnchorTag, options: [.new], changeHandler: updateYAnchors)
        recorderControlYAnchorTagObserver = defaults.observe(\.recorderControlYAnchorTag, options: [.new], changeHandler: updateYAnchors)

        let allViews = [scaledView, recorderControl, button, label, textField]
        let allControls = [recorderControl, button, label, textField]
        let macOSControls = [button, label, textField]

        assetScaleTagObserver = defaults.observe(\.assetScaleTag, options: [.initial, .new]) { (_, change) in
            let scale = CGFloat(change.newValue!)
            allViews.forEach { (view) in
                view!.scale = scale
            }
        }

        controlAlphaObserver = defaults.observe(\.controlAlpha, options: [.initial, .new]) { (_, change) in
            let alpha = change.newValue!
            macOSControls.forEach { (view) in
                view!.alphaValue = alpha
                view!.isHidden = alpha.isEqual(to: 0.0)
            }
        }

        controlDrawsChessboardObserver = defaults.observe(\.controlDrawsChessboard, options: [.initial, .new]) { (_, change) in
            let draws = change.newValue!
            allControls.forEach { (view) in
                view!.drawsChessboard = draws
            }
        }

        controlXAnchorConstantObserver = defaults.observe(\.controlXAnchorConstant, options: [.initial, .new]) { (_, change) in
            self.xConstraint?.constant = change.newValue!
        }

        controlYAnchorConstantObserver = defaults.observe(\.controlYAnchorConstant, options: [.initial, .new]) { (_, change) in
            self.yConstraint?.constant = change.newValue!
        }

        controlDrawsBaselineObserver = defaults.observe(\.controlDrawsBaseline, options: [.initial, .new]) { (_, change) in
            let draws = change.newValue!
            allControls.forEach { (view) in
                view!.drawsBaseline = draws
            }
        }

        controlDrawsAlignmentRectObserver = defaults.observe(\.controlDrawsAlignmentRect, options: [.initial, .new]) { (_, change) in
            let draws = change.newValue!
            allControls.forEach { (view) in
                view!.drawsAlignmentRect = draws
            }
        }

        recorderControlValueObserver = recorderControl.observe(\.stringValue, options: [.initial, .new]) { (_, change) in
            let value = change.newValue!
            self.button.attributedTitle = NSAttributedString(string: value, attributes: [.foregroundColor: NSColor.red])
            self.label.stringValue = value
            self.textField.stringValue = value
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        style = UserDefaults.standard.dictionary(forKey: Setting.style.rawValue)!
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        UserDefaults.standard.set(style, forKey: Setting.style.rawValue)
    }
}
