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

/**
 * Statistical analysis of different image comparison techniques from Wolfram Alpha using live data collected on a MacBookAir5,1.
 *
 *         TIFF        cachedTIFF  bitmapContext   cachedBitmapContext
 * mean    0.044355s   0.030984s   0.042822s       0.027414s
 * s.d.    0.030811s   0.025442s   0.032570s       0.025652s
 * min.    0.0063680s  0.0045800s  0.0099460s      0.0049860s
 * median  0.041264s   0.025762s   0.041444s       0.025496s
 * max.    0.34393s    0.25831s    0.29573s        0.32560s
 * total   45.420s     31.728s     43.850s         28.072s
 * count   1024        1024        1024            1024
 *
 * • The worst case cache times (cache miss) are the same as the worst case of their uncached counterparts, plus the cost of looking up and setting an associated object, but the cache is only invalidated when a window is created or resized, which are far less common operations.
 * • The tiff technique is 100% accurate whereas the bitmap technique effectively samples the image at regular intervals.
 * • Explore using the CGImage's CGDataProvider to save a drawInRect/TIFFRepresentation
 * • Explore using IOSurfaces if possible?
 */

__attribute__((unused)) static BOOL (^imagesDifferByCachedTIFFComparison)(NSImage *, NSImage *) = ^(NSImage *a, NSImage *b) {
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

static BOOL (^imagesDifferByCachedBitmapContextComparison)(NSImage *, NSImage *) = ^(NSImage *a, NSImage *b) {
    static void *bitmapContextKey = (void *)1567529422; // Guaranteed random by arc4random()
    NSSize imageSize = a.size;
    assert(a.size.width == b.size.width);
    assert(a.size.height == b.size.height);
    
    // Sane number of testing points per axis.
    unsigned maxSize = 32;
    unsigned x = maxSize * imageSize.width / MAX(imageSize.width, imageSize.height);
    unsigned y = maxSize * imageSize.height / MAX(imageSize.width, imageSize.height);
    
    CGContextRef (^contextForImage)(NSImage *) = ^(NSImage *image) {
        CGContextRef result = (CGContextRef)CFBridgingRetain(objc_getAssociatedObject(image, bitmapContextKey));
        if (!result) {
            // Bake the old image data into a (smallish) buffer.
            result = CGBitmapContextCreate(NULL, x, y, 8, 0, [[NSColorSpace genericRGBColorSpace] CGColorSpace], kCGBitmapByteOrder32Host|kCGImageAlphaPremultipliedFirst);
            [NSGraphicsContext saveGraphicsState];
            [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:result flipped:NO]];
            [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
            [image drawInRect:NSMakeRect(0, 0, x, y) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
            [NSGraphicsContext restoreGraphicsState];
            objc_setAssociatedObject(image, bitmapContextKey, (__bridge id)result, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        return result;
    };
    
    CGContextRef aContext = contextForImage(a);
    void *aData = CGBitmapContextGetData(aContext);
    
    CGContextRef bContext = contextForImage(b);
    void *bData = CGBitmapContextGetData(bContext);
    
    // Determine the size of the buffers.
    size_t bytesPerRow = CGBitmapContextGetBytesPerRow(bContext);
    size_t height = CGBitmapContextGetHeight(bContext);
    size_t len = bytesPerRow * height;
    
    // Determine image equality, with hoizTestPointCount * vertTestPointCount pixel samples.
    BOOL result = !!memcmp(aData, bData, len);
    
    // Clean up.
    CFRelease(aContext);
    CFRelease(bContext);
    
    return result;
};
