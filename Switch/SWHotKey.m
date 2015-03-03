//
//  SWHotKey.m
//  Switch
//
//  Created by Scott Perry on 07/16/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SWHotKey.h"


static NSDictionary *specialKeys = nil;


@implementation SWHotKey

#pragma mark - Initialization

+ (void)initialize;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        specialKeys = @{
            @(kVK_Return)                    : @"⏎",
            @(kVK_Tab)                       : @"⇥",
            @(kVK_Space)                     : @"␠",
            @(kVK_Delete)                    : @"⌫",
            @(kVK_Escape)                    : @"⎋",
            @(kVK_Command)                   : @"⌘", // Modifier key
            @(kVK_Shift)                     : @"⇧", // Modifier key
            @(kVK_CapsLock)                  : @"⇪",
            @(kVK_Option)                    : @"⌥", // Modifier key
            @(kVK_Control)                   : @"⌃", // Modifier key
            /// @(kVK_RightShift)                : @"", // Unsupported
            /// @(kVK_RightOption)               : @"", // Unsupported
            /// @(kVK_RightControl)              : @"", // Unsupported
            /// @(kVK_Function)                  : @"", // Modifier key, unsupported
            @(kVK_F17)                       : @"F17",
            /// @(kVK_VolumeUp)                  : @"", // Unsupported
            /// @(kVK_VolumeDown)                : @"", // Unsupported
            /// @(kVK_Mute)                      : @"", // Unsupported
            @(kVK_F18)                       : @"F18",
            @(kVK_F19)                       : @"F19",
            @(kVK_F20)                       : @"F20",
            @(kVK_F5)                        : @"F5",
            @(kVK_F6)                        : @"F6",
            @(kVK_F7)                        : @"F7",
            @(kVK_F3)                        : @"F3",
            @(kVK_F8)                        : @"F8",
            @(kVK_F9)                        : @"F9",
            @(kVK_F11)                       : @"F11",
            @(kVK_F13)                       : @"F13",
            @(kVK_F16)                       : @"F16",
            @(kVK_F14)                       : @"F14",
            @(kVK_F10)                       : @"F10",
            @(kVK_F12)                       : @"F12",
            @(kVK_F15)                       : @"F15",
            /// @(kVK_Help)                      : @"", // Unsupported
            /// @(kVK_Home)                      : @"", // Unsupported
            @(kVK_PageUp)                    : @"⇞",
            @(kVK_ForwardDelete)             : @"⌦",
            @(kVK_F4)                        : @"F4",
            /// @(kVK_End)                       : @"", // Unsupported
            @(kVK_F2)                        : @"F2",
            @(kVK_PageDown)                  : @"⇟",
            @(kVK_F1)                        : @"F1",
            @(kVK_LeftArrow)                 : @"←",
            @(kVK_RightArrow)                : @"→",
            @(kVK_DownArrow)                 : @"↓",
            @(kVK_UpArrow)                   : @"↑"
        };
    });
}

+ (SWHotKey *)hotKeyWithKeycode:(CGKeyCode)code modifiers:(SWHotKeyModifierKey)modifiers;
{
    return [[SWHotKey alloc] initWithKeycode:code modifiers:modifiers];
}

+ (SWHotKey *)hotKeyFromEvent:(CGEventRef)event;
{
    SWHotKeyModifierKey modifiers = 0;
    if ((CGEventGetFlags(event) & kCGEventFlagMaskAlternate) == kCGEventFlagMaskAlternate) {
        modifiers |= SWHotKeyModifierOption;
    }
    if ((CGEventGetFlags(event) & kCGEventFlagMaskShift) == kCGEventFlagMaskShift) {
        modifiers |= SWHotKeyModifierShift;
    }
    if ((CGEventGetFlags(event) & kCGEventFlagMaskControl) == kCGEventFlagMaskControl) {
        modifiers |= SWHotKeyModifierControl;
    }
    if ((CGEventGetFlags(event) & kCGEventFlagMaskCommand) == kCGEventFlagMaskCommand) {
        modifiers |= SWHotKeyModifierCmd;
    }
    
    CGKeyCode keycode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);

    return [self hotKeyWithKeycode:keycode modifiers:modifiers];
}

- (instancetype)initWithKeycode:(CGKeyCode)code modifiers:(SWHotKeyModifierKey)modifiers;
{
    BailUnless(self = [super init], nil);
    
    _modifiers = modifiers;
    _code = code;
    
    return self;
}

#pragma mark - NSObject

- (NSUInteger)hash;
{
    return self.modifiers ^ self.code;
}

- (BOOL)isEqual:(id)object;
{
    return [self isKindOfClass:[object class]] && [object isKindOfClass:[self class]] && ((SWHotKey *)object).code == self.code && ((SWHotKey *)object).modifiers == self.modifiers;
}

- (instancetype)copyWithZone:(NSZone *)zone;
{
    return self;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"%@%@",
            [self modifierDescription],
            [self codeDescription]];
}

#pragma mark - Internal

- (NSString *)codeDescription;
{
    NSString *result = specialKeys[@(self.code)];

    if (!result) {
        TISInputSourceRef currentKeyboard = TISCopyCurrentKeyboardInputSource();
        CFDataRef layoutData = TISGetInputSourceProperty(currentKeyboard, kTISPropertyUnicodeKeyLayoutData);
        const UCKeyboardLayout *keyboardLayout = (const UCKeyboardLayout *)CFDataGetBytePtr(layoutData);
        
        UInt32 keysDown = 0;
        UniChar chars[4];
        UniCharCount realLength;
        
        UCKeyTranslate(keyboardLayout,
                       self.code,
                       kUCKeyActionDisplay,
                       self.modifiers,
                       LMGetKbdType(),
                       kUCKeyTranslateNoDeadKeysBit,
                       &keysDown,
                       sizeof(chars) / sizeof(chars[0]),
                       &realLength,
                       chars);
        CFRelease(currentKeyboard);
        
        result = [NSString stringWithCharacters:chars length:realLength];
    }
    
    return result;
}


- (NSString *)modifierDescription;
{
    NSString *result = @"";
    
    if (self.modifiers & SWHotKeyModifierCmd) {
        result = [result stringByAppendingString:specialKeys[@(kVK_Command)]];
    }
    if (self.modifiers & SWHotKeyModifierShift) {
        result = [result stringByAppendingString:specialKeys[@(kVK_Shift)]];
    }
    if (self.modifiers & SWHotKeyModifierOption) {
        result = [result stringByAppendingString:specialKeys[@(kVK_Option)]];
    }
    if (self.modifiers & SWHotKeyModifierControl) {
        result = [result stringByAppendingString:specialKeys[@(kVK_Control)]];
    }
    
    return result;
}

@end
