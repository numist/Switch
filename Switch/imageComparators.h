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
 *         TIFF        cachedTIFF  bitmapContext   cachedBitmapContext  cgDataProvider
 * mean    0.044355s   0.030984s   0.042822s       0.027414s            0.017454s
 * s.d.    0.030811s   0.025442s   0.032570s       0.025652s            0.0090117s
 * min.    0.0063680s  0.0045800s  0.0099460s      0.0049860s           0.0012610s
 * median  0.041264s   0.025762s   0.041444s       0.025496s            0.016456s
 * max.    0.34393s    0.25831s    0.29573s        0.32560s             0.088242s
 * total   45.420s     31.728s     43.850s         28.072s              17.890s
 * count   1024        1024        1024            1024                 1024
 *
 * • The worst case cache times (cache miss) are the same as the worst case of their uncached counterparts, plus the cost of looking up and setting an associated object, but the cache is only invalidated when a window is created or resized, which are far less common operations.
 * • The tiff technique is 100% accurate whereas the bitmap technique effectively samples the image at regular intervals.
 * • There is no need for a cached version of cgDataProvider. It looks like CGDataProviderCopyData marks the CGDataProvider's memory space as copy-on-write. Since imagesDifferByCGDataProviderComparison doesn't write to the data buffers, most time is spent in memcmp.
 * TODO: AVCaptureScreenInput? IOSurfaces?
 */

static BOOL (^imagesDifferByCGDataProviderComparison)(CGImageRef, CGImageRef) = ^(CGImageRef a, CGImageRef b) {
    BOOL result = NO;
    
    CGDataProviderRef aDataProvider = CGImageGetDataProvider(a);
    CGDataProviderRef bDataProvider = CGImageGetDataProvider(b);
    
    CFDataRef aData = NNCFAutorelease(CGDataProviderCopyData(aDataProvider));
    CFDataRef bData = NNCFAutorelease(CGDataProviderCopyData(bDataProvider));
    
    if (CFDataGetLength(aData) != CFDataGetLength(bData)) {
        result = YES;
    }
    
    if (!result) {
        // It turns out that striding over the buffers is slower than memcmp. Jesus.
        result = !!memcmp(CFDataGetBytePtr(aData), CFDataGetBytePtr(bData), (unsigned long)CFDataGetLength(aData));
    }
    
    return result;
};
