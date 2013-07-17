//
// NNMainThreadGuard.m
//
// Mostly taken from the commercial iOS PDF framework http://pspdfkit.com.
// Copyright © 2013 Peter Steinberger. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// You should only use this in debug builds. It doesn't use private API, but I wouldn't ship it.
//
// Modified from https://gist.github.com/steipete/5664345/391a9b069307448d5cc573f1cd077ad7e1f949bc for use with non-touch Cocoa.
//

#if DEBUG

#import <objc/runtime.h>
#import <objc/message.h>

// Compile-time selector checks.
#if DEBUG
#define PROPERTY(propName) NSStringFromSelector(@selector(propName))
#else
#define PROPERTY(propName) @#propName
#endif

// A better assert. NSAssert is too runtime dependant, and assert() doesn't log.
// http://www.mikeash.com/pyblog/friday-qa-2013-05-03-proper-use-of-asserts.html
// Accepts both:
// - NNAssert(x > 0);
// - NNAssert(y > 3, @"Bad value for y");
#define NNAssert(expression, ...) \
do { if(!(expression)) { \
NSLog(@"%@", [NSString stringWithFormat: @"Assertion failure: %s in %s on line %s:%d. %@", #expression, __PRETTY_FUNCTION__, __FILE__, __LINE__, [NSString stringWithFormat:@"" __VA_ARGS__]]); \
abort(); }} while(0)

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Helper for Swizzling

BOOL NNReplaceMethodWithBlock(Class c, SEL origSEL, SEL newSEL, id block) {
    NNAssert(c && origSEL && newSEL && block);
    Method origMethod = class_getInstanceMethod(c, origSEL);
    const char *encoding = method_getTypeEncoding(origMethod);
    
    // Add the new method.
    IMP impl = imp_implementationWithBlock(block);
    if (!class_addMethod(c, newSEL, impl, encoding)) {
        NSLog(@"Failed to add method: %@ on %@", NSStringFromSelector(newSEL), c);
        return NO;
    } else {
        // Ensure the new selector has the same parameters as the existing selector.
        Method newMethod = class_getInstanceMethod(c, newSEL);
        NNAssert(strcmp(method_getTypeEncoding(origMethod), method_getTypeEncoding(newMethod)) == 0, @"Encoding must be the same.");
        
        // If original doesn't implement the method we want to swizzle, create it.
        if (class_addMethod(c, origSEL, method_getImplementation(newMethod), encoding)) {
            class_replaceMethod(c, newSEL, method_getImplementation(origMethod), encoding);
        }else {
            method_exchangeImplementations(origMethod, newMethod);
        }
    }
    return YES;
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Tracks down calls into Cocoa from a Thread other than Main

static void AssertIfNotMainThread(void) {
    NNAssert([[NSThread currentThread] isMainThread], @"ERROR: All calls into Cocoa need to happen on the main thread. You have a bug in your code. Use dispatch_async(dispatch_get_main_queue(), ^{ ... }); if you're unsure what thread you're in.\n\nBreak on AssertIfNotMainThread to find out where.\n\nStacktrace: %@", [NSThread callStackSymbols]);
}

// This installs a small guard that checks for the most common threading-errors in Cocoa.
// This won't really slow down performance but still only is compiled in DEBUG versions of the application.
// @note No private API is used here.
__attribute__((constructor)) static void NNUIKitMainThreadGuard(void) {
    @autoreleasepool {
        
        NSString *selStr = PROPERTY(setNeedsDisplayInRect:);
        SEL selector = NSSelectorFromString(selStr);
        SEL newSelector = NSSelectorFromString([NSString stringWithFormat:@"nn_%@", selStr]);

        NNReplaceMethodWithBlock(NSView.class, selector, newSelector, ^(__unsafe_unretained NSView *_self, CGRect r) {
                AssertIfNotMainThread();
                ((void ( *)(id, SEL, CGRect))objc_msgSend)(_self, newSelector, r);
        });
        
        
        for (selStr in @[PROPERTY(setNeedsLayout:), PROPERTY(setNeedsDisplay:)]) {
            selector = NSSelectorFromString(selStr);
            newSelector = NSSelectorFromString([NSString stringWithFormat:@"nn_%@", selStr]);
            
            NNReplaceMethodWithBlock(NSView.class, selector, newSelector, ^(__unsafe_unretained NSView *_self, BOOL b) {
                AssertIfNotMainThread();
                ((void ( *)(id, SEL, BOOL))objc_msgSend)(_self, newSelector, b);
            });
        }
    }
}

#endif
