//
//  NNSelfInvalidatingObject.h
//  NNKit
//
//  Created by Scott Perry on 09/05/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <Foundation/Foundation.h>


/*!
 * @class NNSelfInvalidatingObject
 *
 * @discussion
 * For use when an object has to do cleanup work asynchronously, or outside of
 * <code>dealloc</code>. Simply implement the <code>invalidate</code> method and
 * call <code>[super invalidate]</code> when the actor has finished cleaning up.
 */
@interface NNSelfInvalidatingObject : NSObject

/*!
 * @method invalidate
 *
 * @discussion
 * Called only once, either explicitly (by an interested object) or when the
 * object has been fully-released.
 *
 * When invalidation is complete, [super invalidate] must be called to complete
 * deallocation of the object.
 */
- (void)invalidate;

@end
