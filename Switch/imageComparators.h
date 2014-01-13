//
//  imageComparators.h
//  Switch
//
//  Created by Scott Perry on 03/02/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

static BOOL (^imagesDifferByCachedTIFFComparison)(NSImage *, NSImage *) = ^(NSImage *a, NSImage *b) {
    static void *tiffContextKey = (void *)1999428944; // Guaranteed random by arc4random()
    NSData *(^TIFFForImage)(NSImage *) = ^(NSImage *image) {
        NSData *result = objc_getAssociatedObject(image, tiffContextKey);
        if (!result) {
            result = [image TIFFRepresentation];
            objc_setAssociatedObject(image, tiffContextKey, result, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        return result;
    };
    
    NSData *aData = TIFFForImage(a);
    NSData *bData = TIFFForImage(b);
    return (BOOL)![aData isEqualToData:bData];
};

/// This used to be the fastest option, but something changed in CG and it's now doing a whole lot of buffer copying. I suspect it used to be returning references (instead of copies) from calls to CGDataProviderCopyData
//static BOOL (^imagesDifferByCGDataProviderComparison)(CGImageRef, CGImageRef) = ^(CGImageRef a, CGImageRef b) {
//    BOOL result = NO;
//    
//    CGDataProviderRef aDataProvider = CGImageGetDataProvider(a);
//    CGDataProviderRef bDataProvider = CGImageGetDataProvider(b);
//    
//    CFDataRef aData = NNCFAutorelease(CGDataProviderCopyData(aDataProvider));
//    CFDataRef bData = NNCFAutorelease(CGDataProviderCopyData(bDataProvider));
//    
//    if (CFDataGetLength(aData) != CFDataGetLength(bData)) {
//        result = YES;
//    }
//    
//    if (!result) {
//        // It turns out that striding over the buffers is slower than memcmp. Jesus.
//        result = !!memcmp(CFDataGetBytePtr(aData), CFDataGetBytePtr(bData), (unsigned long)CFDataGetLength(aData));
//    }
//    
//    return result;
//};

/// This was both slow and inexact.
//static BOOL (^imagesDifferByCachedBitmapContextComparison)(NSImage *, NSImage *) = ^(NSImage *a, NSImage *b) {
//    static void *bitmapContextKey = (void *)1567529422; // Guaranteed random by arc4random()
//    NSSize imageSize = a.size;
//    assert(a.size.width == b.size.width);
//    assert(a.size.height == b.size.height);
//    
//    // Sane number of testing points per axis.
//    CGFloat maxSize = 32;
//    CGFloat x = maxSize * imageSize.width / MAX(imageSize.width, imageSize.height);
//    CGFloat y = maxSize * imageSize.height / MAX(imageSize.width, imageSize.height);
//    
//    CGContextRef (^contextForImage)(NSImage *) = ^(NSImage *image) {
//        CGContextRef result = (CGContextRef)CFBridgingRetain(objc_getAssociatedObject(image, bitmapContextKey));
//        if (!result) {
//            // Bake the old image data into a (smallish) buffer.
//            result = CGBitmapContextCreate(NULL, (unsigned)x, (unsigned)y, 8, 0, [[NSColorSpace genericRGBColorSpace] CGColorSpace], kCGBitmapByteOrder32Host|kCGImageAlphaPremultipliedFirst);
//            [NSGraphicsContext saveGraphicsState];
//            [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:result flipped:NO]];
//            [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
//            [image drawInRect:NSMakeRect(0, 0, x, y) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
//            [NSGraphicsContext restoreGraphicsState];
//            objc_setAssociatedObject(image, bitmapContextKey, (__bridge id)result, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//        }
//        return result;
//    };
//    
//    CGContextRef aContext = contextForImage(a);
//    void *aData = CGBitmapContextGetData(aContext);
//    
//    CGContextRef bContext = contextForImage(b);
//    void *bData = CGBitmapContextGetData(bContext);
//    
//    // Determine the size of the buffers.
//    size_t bytesPerRow = CGBitmapContextGetBytesPerRow(bContext);
//    size_t height = CGBitmapContextGetHeight(bContext);
//    size_t len = bytesPerRow * height;
//    
//    // Determine image equality, with hoizTestPointCount * vertTestPointCount pixel samples.
//    BOOL result = !!memcmp(aData, bData, len);
//    
//    // Clean up.
//    CFRelease(aContext);
//    CFRelease(bContext);
//    
//    return result;
//};
