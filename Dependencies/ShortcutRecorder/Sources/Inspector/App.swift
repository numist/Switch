//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 4.0
//

import os
import Cocoa
import ShortcutRecorder


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, ShortcutActionTarget {
    var bindingsInspector: NSWindowController!
    var layoutInspector: NSWindowController!

    let purrSound = NSSound(named: "Purr")!

    override func awakeFromNib() {

        let shortcut = Shortcut(code: KeyCode.ansiA, modifierFlags: [.shift, .control, .option, .command], characters: "A", charactersIgnoringModifiers: "a")
        let shortcutData = NSKeyedArchiver.archivedData(withRootObject: shortcut)

        UserDefaults.standard.register(defaults: [
            "NSFullScreenMenuItemEverywhere": false,
            "NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints": true,
            Setting.showBindingsWindow.rawValue: true,
            Setting.showAssetsWindow.rawValue: true,
            Setting.shortcut.rawValue: shortcutData,
            Setting.style.rawValue: RecorderControlStyle.init().dictionaryRepresentation,
            Setting.isEnabled.rawValue: true,
            Setting.controlTag.rawValue: ControlTag.label.rawValue,
            Setting.recorderControlXAnchorTag.rawValue: AnchorTag.xCenter.rawValue,
            Setting.controlXAnchorTag.rawValue: AnchorTag.xCenter.rawValue,
            Setting.recorderControlYAnchorTag.rawValue: AnchorTag.firstBaseline.rawValue,
            Setting.controlYAnchorTag.rawValue: AnchorTag.firstBaseline.rawValue,
            Setting.assetScaleTag.rawValue: 2,
            Setting.controlAlpha.rawValue: CGFloat(0.5),
            Setting.controlDrawsChessboard.rawValue: false,
            Setting.controlDrawsBaseline.rawValue: false,
            Setting.controlDrawsAlignmentRect.rawValue: false,
            Setting.controlXAnchorConstant.rawValue: CGFloat(0.0),
            Setting.controlYAnchorConstant.rawValue: CGFloat(0.0),
            Setting.controlZoom.rawValue: 8
        ])

        ValueTransformer.setValueTransformer(MutableDictionaryTransformer(), forName: .mutableDictionaryTransformerName)

        super.awakeFromNib()
    }

    func showWindows() {
        let s = NSStoryboard(name: "Main", bundle: nil)

        layoutInspector = s.instantiateController(withIdentifier: "LayoutInspector") as? NSWindowController
        bindingsInspector = s.instantiateController(withIdentifier: "BindingsInspector") as? NSWindowController

        let layoutWindow = layoutInspector.window!
        let bindingsWindow = bindingsInspector.window!

        // The Window submenu already lists all available windows.
        layoutWindow.isExcludedFromWindowsMenu = true
        bindingsWindow.isExcludedFromWindowsMenu = true

        bindingsInspector.showWindow(self)
        layoutInspector.showWindow(self)

        // Center both windows on the screen.
        // Must be called _after_ window is shown, otherwise frame origin may not be respected.
        layoutWindow.center()
        var layoutOrigin = layoutWindow.frame.origin
        layoutOrigin.x = (layoutOrigin.x + bindingsWindow.frame.width / 2.0).rounded()
        layoutWindow.setFrameOrigin(layoutOrigin)

        var bindingsOrigin = layoutOrigin
        bindingsOrigin.x -= bindingsWindow.frame.width
        bindingsWindow.setFrameOrigin(bindingsOrigin)

        layoutWindow.setFrameAutosaveName("SRLayoutInspector")
        bindingsWindow.setFrameAutosaveName("SRBindingsInspector")
    }

    @IBAction func showBindingsInspector(_ sender: Any) {
        bindingsInspector.showWindow(sender)
    }

    @IBAction func showLayoutInspector(_ sender: Any) {
        layoutInspector.showWindow(sender)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        showWindows()
    }

    func perform(shortcutAction anAction: ShortcutAction) -> Bool {
        purrSound.play()
        return true
    }
}
