//
//  memoize.h
//  NNKit
//
//  Created by Scott Perry on 06/23/15.
//  Copyright © 2015 Scott Perry. All rights reserved.
//

#define NNMemoize(block) _NNMemoize(self, _cmd, block)

id _NNMemoize(id self, SEL _cmd, id (^block)());
