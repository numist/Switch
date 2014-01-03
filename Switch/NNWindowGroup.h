//
//  NNWindowGroup.h
//  Switch
//
//  Created by Scott Perry on 12/24/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNWindow.h"


@class NNApplication;


@interface NNWindowGroup : NNWindow

@property (nonatomic, strong, readonly) NNWindow *mainWindow;
@property (nonatomic, strong, readonly) NSOrderedSet *windows;

- (instancetype)initWithWindows:(NSOrderedSet *)windows mainWindow:(NNWindow *)mainWindow;

@end
