//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 4.0
//

import Foundation


enum AnchorTag: Int {
    case leading
    case xCenter
    case trailing
    case top
    case yCenter
    case firstBaseline
    case bottom
}


enum ControlTag: Int {
    case button
    case label
    case textField
}


enum Setting: String {
    case showBindingsWindow
    case showAssetsWindow
    case shortcut
    case style
    case isEnabled
    case controlTag
    case controlAlpha
    case controlZoom
    case controlDrawsChessboard
    case controlDrawsBaseline
    case controlDrawsAlignmentRect
    case controlXAnchorTag
    case controlXAnchorConstant
    case controlYAnchorTag
    case controlYAnchorConstant
    case recorderControlXAnchorTag
    case recorderControlYAnchorTag
    case assetScaleTag
}


extension UserDefaults {
    @objc dynamic var controlTag: Int {
        return integer(forKey: Setting.controlTag.rawValue)
    }

    @objc dynamic var controlXAnchorTag: Int {
        get {
            return integer(forKey: Setting.controlXAnchorTag.rawValue)
        }

        set {
            set(newValue, forKey: Setting.controlXAnchorTag.rawValue)
        }
    }

    @objc dynamic var controlXAnchorConstant: CGFloat {
        return CGFloat(double(forKey: Setting.controlXAnchorConstant.rawValue))
    }

    @objc dynamic var controlYAnchorTag: Int {
        get {
            return integer(forKey: Setting.controlYAnchorTag.rawValue)
        }

        set {
            set(newValue, forKey: Setting.controlYAnchorTag.rawValue)
        }
    }

    @objc dynamic var controlYAnchorConstant: CGFloat {
        return CGFloat(double(forKey: Setting.controlYAnchorConstant.rawValue))
    }

    @objc dynamic var recorderControlXAnchorTag: Int {
        get {
            return integer(forKey: Setting.recorderControlXAnchorTag.rawValue)
        }

        set {
            set(newValue, forKey: Setting.recorderControlXAnchorTag.rawValue)
        }
    }

    @objc dynamic var recorderControlYAnchorTag: Int {
        get {
            return integer(forKey: Setting.recorderControlYAnchorTag.rawValue)
        }

        set {
            set(newValue, forKey: Setting.recorderControlYAnchorTag.rawValue)
        }
    }

    @objc dynamic var assetScaleTag: Int {
        get {
            return integer(forKey: Setting.assetScaleTag.rawValue)
        }

        set {
            set(newValue, forKey: Setting.assetScaleTag.rawValue)
        }
    }

    @objc dynamic var controlAlpha: CGFloat {
        return CGFloat(double(forKey: Setting.controlAlpha.rawValue))
    }

    @objc dynamic var controlDrawsChessboard: Bool {
        return bool(forKey: Setting.controlDrawsChessboard.rawValue)
    }

    @objc dynamic var controlDrawsBaseline: Bool {
        return bool(forKey: Setting.controlDrawsBaseline.rawValue)
    }

    @objc dynamic var controlDrawsAlignmentRect: Bool {
        return bool(forKey: Setting.controlDrawsAlignmentRect.rawValue)
    }

    @objc dynamic var controlZoom: Int {
        return integer(forKey: Setting.controlZoom.rawValue)
    }

    @objc dynamic var isEnabled: Bool {
        get {
            return bool(forKey: Setting.isEnabled.rawValue)
        }

        set {
            set(newValue, forKey: Setting.isEnabled.rawValue)
        }
    }
}
