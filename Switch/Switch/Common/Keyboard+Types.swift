import Carbon

// MARK: - Modifiers
extension Keyboard {
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
}

// MARK: - KeyCode
extension Keyboard {
  enum KeyCode: UInt16 {
    // swiftlint:disable identifier_name
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
    case enter           = 0x24 // kVK_Return (sorry nerds, "return" is reserved and "enter" isn't differentiated)
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
    // swiftlint:enable identifier_name
  }
}

extension Keyboard.KeyCode {
  var description: String {
    switch self {
    case .a: return "A"
    case .s: return "S"
    case .d: return "D"
    case .f: return "F"
    case .h: return "H"
    case .g: return "G"
    case .z: return "Z"
    case .x: return "X"
    case .c: return "C"
    case .v: return "V"
    case .b: return "B"
    case .q: return "Q"
    case .w: return "W"
    case .e: return "E"
    case .r: return "R"
    case .y: return "Y"
    case .t: return "T"
    case .one: return "1"
    case .two: return "2"
    case .three: return "3"
    case .four: return "4"
    case .six: return "6"
    case .five: return "5"
    case .equal: return "="
    case .nine: return "9"
    case .seven: return "7"
    case .minus: return "-"
    case .eight: return "8"
    case .zero: return "0"
    case .rightBracket: return "]"
    case .o: return "O"
    case .u: return "U"
    case .leftBracket: return "["
    case .i: return "I"
    case .p: return "P"
    case .l: return "L"
    case .j: return "J"
    case .quote: return "'"
    case .k: return "K"
    case .semicolon: return ";"
    case .backslash: return "\\"
    case .comma: return ","
    case .slash: return "/"
    case .n: return "N"
    case .m: return "M"
    case .period: return "."
    case .grave: return "`"
    case .keypadDecimal: return ".⃣"
    case .keypadMultiply: return "×⃣"
    case .keypadPlus: return "+⃣"
    case .keypadClear: return "⌧⃣"
    case .keypadDivide: return "÷⃣"
    case .keypadEnter: return "⌤"
    case .keypadMinus: return "-⃣"
    case .keypadEquals: return "=⃣"
    case .keypad0: return "0︎⃣"
    case .keypad1: return "1︎⃣"
    case .keypad2: return "2︎⃣"
    case .keypad3: return "3︎⃣"
    case .keypad4: return "4︎⃣"
    case .keypad5: return "5︎⃣"
    case .keypad6: return "6︎⃣"
    case .keypad7: return "7︎⃣"
    case .keypad8: return "8︎⃣"
    case .keypad9: return "9︎⃣"
    case .enter: return "⏎"
    case .tab: return "⇥"
    case .space: return "␣"
    case .delete: return "⌫"
    case .escape: return "⎋"
    case .command: return "⌘"
    case .shift: return "⇧"
    case .capsLock: return "⇪"
    case .option: return "⌥"
    case .control: return "⌃"
    case .rightCommand: return "⌘"
    case .rightShift: return "⇧"
    case .rightOption: return "⌥"
    case .rightControl: return "⌃"
    case .function: return "fn"
    case .f17: return "F17"
    case .volumeUp: return "🔊"
    case .volumeDown: return "🔉"
    case .mute: return "🔇"
    case .f18: return "F18"
    case .f19: return "F19"
    case .f20: return "F20"
    case .f5: return "F5"
    case .f6: return "F6"
    case .f7: return "F7"
    case .f3: return "F3"
    case .f8: return "F8"
    case .f9: return "F9"
    case .f11: return "F11"
    case .f13: return "F13"
    case .f16: return "F16"
    case .f14: return "F14"
    case .f10: return "F10"
    case .f12: return "F12"
    case .f15: return "F15"
    case .help: return "help"
    case .home: return "↖︎"
    case .pageUp: return "⇞"
    case .forwardDelete: return "⌦"
    case .f4: return "F4"
    case .end: return "↘︎"
    case .f2: return "F2"
    case .pageDown: return "⇟"
    case .f1: return "F1"
    case .leftArrow: return "←"
    case .rightArrow: return "→"
    case .downArrow: return "↓"
    case .upArrow: return "↑"
    case .section: return "§"
    case .yen: return "¥"
    case .underscore: return "_"
    case .keypadComma: return ",⃣"
    case .eisu, .kana, .unknown: return "�"
    }
  }
}

// MARK: - HotKey
extension Keyboard {
  struct HotKey: Hashable, CustomStringConvertible, RawRepresentable {
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

    // MARK: CustomStringConvertible

    var description: String {
      return "\(modifiers.description)\(code.description)"
    }

    // MARK: RawRepresentable

    typealias RawValue = Int // swiftlint:disable:this nesting

    var rawValue: Int { Int(code.rawValue) | modifiers.rawValue }

    init?(rawValue: Int) {
      guard let code = KeyCode(rawValue: UInt16(rawValue & 0xFF)) else { return nil }
      self.code = code
      modifiers = .init(rawValue: rawValue & ~0xFF)
    }
  }
}
