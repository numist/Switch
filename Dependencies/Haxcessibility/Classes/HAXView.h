//  HAXView.h
//  Created by Kocsis Olivér on 2014-05-12
//  Copyright 2014 Joinect Technologies

#import <Cocoa/Cocoa.h>
#import <Haxcessibility/HAXElement.h>

@interface HAXView : HAXElement

@property (nonatomic) CGPoint carbonOrigin;
@property (nonatomic) NSPoint origin;
@property (nonatomic) CGSize size;
@property (nonatomic) CGRect carbonFrame;
@property (nonatomic) NSRect frame;
@property (nullable, readonly) NSString *title;
@property (nullable, readonly) NSScreen *screen;
@property (readonly, getter=isFullscreen) BOOL fullscreen;

@end

