import Carbon
import OSLog

class Keyboard {
  struct Modifiers: OptionSet, Hashable, CustomStringConvertible {
    let rawValue: Int

    static let shift = Modifiers(rawValue: shiftKey)
    static let control = Modifiers(rawValue: controlKey)
    static let option = Modifiers(rawValue: optionKey)
    static let command = Modifiers(rawValue: cmdKey)

    init(rawValue: Int = 0) {
      self.rawValue = rawValue
    }

    init(_ flags: CGEventFlags) {
      var mods = Modifiers()
      if flags.contains(.maskShift) {
        mods.insert(.shift)
      }
      if flags.contains(.maskControl) {
        mods.insert(.control)
      }
      if flags.contains(.maskAlternate) {
        mods.insert(.option)
      }
      if flags.contains(.maskCommand) {
        mods.insert(.command)
      }
      rawValue = mods.rawValue
    }

    var description: String {
      var result = ""
      if self.contains(.control) {
        result += "⌃"
      }
      if self.contains(.option) {
        result += "⌥"
      }
      if self.contains(.shift) {
        result += "⇧"
      }
      if self.contains(.command) {
        result += "⌘"
      }
      return result
    }
  }

  // swiftlint:disable identifier_name
  enum KeyCode: UInt16 {
    case a               = 0x00 // kVK_ANSI_A
    case s               = 0x01 // kVK_ANSI_S
    case d               = 0x02 // kVK_ANSI_D
    case f               = 0x03 // kVK_ANSI_F
    case h               = 0x04 // kVK_ANSI_H
    case g               = 0x05 // kVK_ANSI_G
    case z               = 0x06 // kVK_ANSI_Z
    case x               = 0x07 // kVK_ANSI_X
    case c               = 0x08 // kVK_ANSI_C
    case v               = 0x09 // kVK_ANSI_V
    case b               = 0x0B // kVK_ANSI_B
    case q               = 0x0C // kVK_ANSI_Q
    case w               = 0x0D // kVK_ANSI_W
    case e               = 0x0E // kVK_ANSI_E
    case r               = 0x0F // kVK_ANSI_R
    case y               = 0x10 // kVK_ANSI_Y
    case t               = 0x11 // kVK_ANSI_T
    case one             = 0x12 // kVK_ANSI_1
    case two             = 0x13 // kVK_ANSI_2
    case three           = 0x14 // kVK_ANSI_3
    case four            = 0x15 // kVK_ANSI_4
    case six             = 0x16 // kVK_ANSI_6
    case five            = 0x17 // kVK_ANSI_5
    case equal           = 0x18 // kVK_ANSI_Equal
    case nine            = 0x19 // kVK_ANSI_9
    case seven           = 0x1A // kVK_ANSI_7
    case minus           = 0x1B // kVK_ANSI_Minus
    case eight           = 0x1C // kVK_ANSI_8
    case zero            = 0x1D // kVK_ANSI_0
    case rightBracket    = 0x1E // kVK_ANSI_RightBracket
    case o               = 0x1F // kVK_ANSI_O
    case u               = 0x20 // kVK_ANSI_U
    case leftBracket     = 0x21 // kVK_ANSI_LeftBracket
    case i               = 0x22 // kVK_ANSI_I
    case p               = 0x23 // kVK_ANSI_P
    case l               = 0x25 // kVK_ANSI_L
    case j               = 0x26 // kVK_ANSI_J
    case quote           = 0x27 // kVK_ANSI_Quote
    case k               = 0x28 // kVK_ANSI_K
    case semicolon       = 0x29 // kVK_ANSI_Semicolon
    case backslash       = 0x2A // kVK_ANSI_Backslash
    case comma           = 0x2B // kVK_ANSI_Comma
    case slash           = 0x2C // kVK_ANSI_Slash
    case n               = 0x2D // kVK_ANSI_N
    case m               = 0x2E // kVK_ANSI_M
    case period          = 0x2F // kVK_ANSI_Period
    case grave           = 0x32 // kVK_ANSI_Grave
    case keypadDecimal   = 0x41 // kVK_ANSI_KeypadDecimal
    case keypadMultiply  = 0x43 // kVK_ANSI_KeypadMultiply
    case keypadPlus      = 0x45 // kVK_ANSI_KeypadPlus
    case keypadClear     = 0x47 // kVK_ANSI_KeypadClear
    case keypadDivide    = 0x4B // kVK_ANSI_KeypadDivide
    case keypadEnter     = 0x4C // kVK_ANSI_KeypadEnter
    case keypadMinus     = 0x4E // kVK_ANSI_KeypadMinus
    case keypadEquals    = 0x51 // kVK_ANSI_KeypadEquals
    case keypad0         = 0x52 // kVK_ANSI_Keypad0
    case keypad1         = 0x53 // kVK_ANSI_Keypad1
    case keypad2         = 0x54 // kVK_ANSI_Keypad2
    case keypad3         = 0x55 // kVK_ANSI_Keypad3
    case keypad4         = 0x56 // kVK_ANSI_Keypad4
    case keypad5         = 0x57 // kVK_ANSI_Keypad5
    case keypad6         = 0x58 // kVK_ANSI_Keypad6
    case keypad7         = 0x59 // kVK_ANSI_Keypad7
    case keypad8         = 0x5B // kVK_ANSI_Keypad8
    case keypad9         = 0x5C // kVK_ANSI_Keypad9
    case enter           = 0x24 // kVK_Return (sorry nerds, "return" is a reserved word)
    case tab             = 0x30 // kVK_Tab
    case space           = 0x31 // kVK_Space
    case delete          = 0x33 // kVK_Delete
    case escape          = 0x35 // kVK_Escape
    case command         = 0x37 // kVK_Command
    case shift           = 0x38 // kVK_Shift
    case capsLock        = 0x39 // kVK_CapsLock
    case option          = 0x3A // kVK_Option
    case control         = 0x3B // kVK_Control
    case rightCommand    = 0x36 // kVK_RightCommand
    case rightShift      = 0x3C // kVK_RightShift
    case rightOption     = 0x3D // kVK_RightOption
    case rightControl    = 0x3E // kVK_RightControl
    case function        = 0x3F // kVK_Function
    case f17             = 0x40 // kVK_F17
    case volumeUp        = 0x48 // kVK_VolumeUp
    case volumeDown      = 0x49 // kVK_VolumeDown
    case mute            = 0x4A // kVK_Mute
    case f18             = 0x4F // kVK_F18
    case f19             = 0x50 // kVK_F19
    case f20             = 0x5A // kVK_F20
    case f5              = 0x60 // kVK_F5
    case f6              = 0x61 // kVK_F6
    case f7              = 0x62 // kVK_F7
    case f3              = 0x63 // kVK_F3
    case f8              = 0x64 // kVK_F8
    case f9              = 0x65 // kVK_F9
    case f11             = 0x67 // kVK_F11
    case f13             = 0x69 // kVK_F13
    case f16             = 0x6A // kVK_F16
    case f14             = 0x6B // kVK_F14
    case f10             = 0x6D // kVK_F10
    case f12             = 0x6F // kVK_F12
    case f15             = 0x71 // kVK_F15
    case help            = 0x72 // kVK_Help
    case home            = 0x73 // kVK_Home
    case pageUp          = 0x74 // kVK_PageUp
    case forwardDelete   = 0x75 // kVK_ForwardDelete
    case f4              = 0x76 // kVK_F4
    case end             = 0x77 // kVK_End
    case f2              = 0x78 // kVK_F2
    case pageDown        = 0x79 // kVK_PageDown
    case f1              = 0x7A // kVK_F1
    case leftArrow       = 0x7B // kVK_LeftArrow
    case rightArrow      = 0x7C // kVK_RightArrow
    case downArrow       = 0x7D // kVK_DownArrow
    case upArrow         = 0x7E // kVK_UpArrow
    case section         = 0x0A // kVK_ISO_Section
    case yen             = 0x5D // kVK_JIS_Yen
    case underscore      = 0x5E // kVK_JIS_Underscore
    case keypadComma     = 0x5F // kVK_JIS_KeypadComma
    case eisu            = 0x66 // kVK_JIS_Eisu
    case kana            = 0x68 // kVK_JIS_Kana
    case unknown         = 0xFF
  }
  // swiftlint:enable identifier_name

  struct HotKey: Hashable, CustomStringConvertible {
    let modifiers: Modifiers
    let code: KeyCode

    init(_ modifiers: Modifiers, _ code: KeyCode) {
      self.code = code
      self.modifiers = modifiers
    }

    init(_ event: CGEvent) {
      modifiers = Modifiers(event.flags)
      code = KeyCode(rawValue: UInt16(event.getIntegerValueField(.keyboardEventKeycode))) ?? .unknown
    }

    var description: String {
      print("HotKey -description is not *really* implemented yet")
      return "\(modifiers.description)\(code)"
    }
  }
}

// Would have used CGSSetGlobalHotKeyOperatingMode & co.,
// but then I wouldn't be able to do shenanigans with ⌘Q and ⌘⇥
extension Keyboard {
  private static var eventTap: EventTap?

  private static var callbacks = [HotKey: (Bool)->Bool]()

  private static func keyboardEvent(_ type: CGEventType, _ event: CGEvent) -> CGEvent? {
    precondition(type == .keyUp || type == .keyDown)
    let hotKey = HotKey(event)
    if let callback = callbacks[hotKey] {
      if !callback(type == .keyDown) {
        return nil
      }
    }
    return event
  }

  static func enableHotKeys() throws {
    eventTap = try EventTap(observing: [.keyDown, .keyUp], callback: Keyboard.keyboardEvent)
  }

  static func disableHotKeys() {
    eventTap = nil
  }

  static func register(_ hotkey: HotKey, _ closure: @escaping (Bool) -> Bool) {
    callbacks[hotkey] = closure
  }

  static func deregister(_ hotkey: HotKey) {
    callbacks.removeValue(forKey: hotkey)
  }
}
