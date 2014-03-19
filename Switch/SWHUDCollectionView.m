//
//  SWHUDCollectionView.m
//  Switch
//
//  Created by Scott Perry on 05/28/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SWHUDCollectionView.h"

#import "SWHUDView.h"
#import "SWSelectionBoxView.h"


@interface SWHUDCollectionView ()

@property (nonatomic, assign) CGFloat maxCellSize;
@property (nonatomic, assign, readwrite) NSUInteger numberOfCells;
@property (nonatomic, strong, readonly) NSMutableArray *cells;
@property (nonatomic, strong, readonly) SWHUDView *hud;

@property (nonatomic, strong, readwrite) SWSelectionBoxView *selectionBox;

@property (nonatomic, assign, readwrite) BOOL reloading;
@property (nonatomic, assign, readwrite) NSUInteger selectedIndex;

@end


@implementation SWHUDCollectionView

#pragma mark Initialization

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    
    _cells = [NSMutableArray new];
    return self;
}

#pragma mark NSResponder

- (BOOL)acceptsFirstResponder;
{
    return YES;
}

- (void)mouseMoved:(NSEvent *)theEvent;
{
    NSUInteger i = [self _indexForCellAtPoint:theEvent.locationInWindow];
    
    if (i < self.numberOfCells && self.selectedIndex != i) {
        id<SWHUDCollectionViewDelegate> delegate = self.delegate;
        
        self.selectedIndex = i;
        
        if ([delegate respondsToSelector:@selector(HUDCollectionView:willSelectCellAtIndex:)]) {
            [delegate HUDCollectionView:self willSelectCellAtIndex:i];
        }
        
        [self selectCellAtIndex:self.selectedIndex];
        
        if ([delegate respondsToSelector:@selector(HUDCollectionView:didSelectCellAtIndex:)]) {
            [delegate HUDCollectionView:self didSelectCellAtIndex:self.selectedIndex];
        }
    }
    
    [super mouseMoved:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent;
{
    NSUInteger i = [self _indexForCellAtPoint:theEvent.locationInWindow];
    
    if (i < self.numberOfCells) {
        id<SWHUDCollectionViewDelegate> delegate = self.delegate;
        
        Check(self.selectedIndex == i);
        self.selectedIndex = i;
        
        if ([delegate respondsToSelector:@selector(HUDCollectionView:activateCellAtIndex:)]) {
            [delegate HUDCollectionView:self activateCellAtIndex:i];
        }
    } else {
        [super mouseUp:theEvent];
    }
}

- (void)mouseDown:(NSEvent *)theEvent;
{
    // Do not pass this event up the responder chain.
    return;
}

#pragma mark NSView

- (void)viewWillMoveToSuperview:(NSView *)newSuperview;
{
    if (!self.hud) {
        _hud = [[SWHUDView alloc] initWithFrame:NSZeroRect];
        [self addSubview:self.hud];
    }
}

#pragma mark SWHUDCollectionView

- (void)setDataSource:(id<SWHUDCollectionViewDataSource>)dataSource;
{
    NSAssert([[NSThread currentThread] isMainThread], @"UI on main thread only!");
    _dataSource = dataSource;
    
    [self reloadData];
}

- (NSView *)cellForIndex:(NSUInteger)index;
{
    NSAssert([[NSThread currentThread] isMainThread], @"UI on main thread only!");
    
    // Flush pending reloadData
    [self _reloadDataIfNeeded];

    if (index < [self.cells count]) {
        return [self.cells objectAtIndex:index];
    }
    return nil;
}

- (void)selectCellAtIndex:(NSUInteger)index;
{
    NSAssert([[NSThread currentThread] isMainThread], @"UI on main thread only!");
    
    self.selectedIndex = index;

    if (!self.selectionBox) {
        SWSelectionBoxView *selectionBox = [[SWSelectionBoxView alloc] initWithFrame:NSZeroRect];
        [self.hud addSubview:selectionBox positioned:NSWindowBelow relativeTo:nil];
        self.selectionBox = selectionBox;
    }
    
    self.selectionBox.frame = nnItemRect((self.hud.frame.size.height - kNNWindowToThumbInset * 2.0), self.selectedIndex);
    [self.selectionBox setNeedsDisplay:YES];
}

- (void)deselectCell;
{
    [self.selectionBox removeFromSuperview];
    self.selectionBox = nil;
}

- (void)reloadData;
{
    NSAssert([[NSThread currentThread] isMainThread], @"UI on main thread only!");
    
    if (!self.reloading) {
        self.reloading = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _reloadDataIfNeeded];
        });
    }
}

#pragma mark Internal

- (void)_setHUDSize:(NSSize)size;
{
    self.hud.frame = (NSRect){
        .size = size,
        .origin.x = ((self.frame.size.width - size.width) / 2.0),
        .origin.y = ((self.frame.size.height - size.height) / 2.0)
    };
}

- (CGFloat)_computeCellSize;
{
    CGFloat cellSize = self.maxCellSize;
    CGFloat maxTheoreticalWindowWidth = nnTotalWidth(cellSize, self.numberOfCells);
    CGFloat requiredPaddings = nnTotalPadding(self.numberOfCells);
    
    if (maxTheoreticalWindowWidth > self.frame.size.width) {
        cellSize = floor((self.frame.size.width - requiredPaddings) / self.numberOfCells);
    }

    return cellSize;
}

- (NSSize)_computeCollectionViewSize;
{
    CGFloat cellSize = [self _computeCellSize];
    CGFloat maxTheoreticalWindowWidth = nnTotalWidth(cellSize, self.numberOfCells);
    
    if (self.numberOfCells == 0) {
        CGFloat min = MIN(kNNWindowToThumbInset + self.maxCellSize + kNNWindowToThumbInset, self.frame.size.width);
        return (NSSize){
            .height = min,
            .width = min
        };
    }

    return (NSSize){
        .width = MIN(self.frame.size.width, maxTheoreticalWindowWidth),
        .height = kNNWindowToThumbInset + cellSize + kNNWindowToThumbInset
    };
}

- (NSRect)_computeFrameForCellAtIndex:(NSUInteger)index;
{
    return nnThumbRect([self _computeCellSize], index);
}

- (NSUInteger)_indexForCellAtPoint:(NSPoint)point;
{
    unsigned i;
    for (i = 0; i < self.numberOfCells; ++i) {
        NSRect frame = [self.hud convertRect:[self _computeFrameForCellAtIndex:i] toView:self];
        
        if (NSPointInRect(point, frame)) {
            break;
        }
    }
    
    return i < [self.cells count] ? i : NSNotFound;
}

- (void)_reloadDataIfNeeded;
{
    if (!self.reloading) { return; }
    
    self.reloading = NO;
    
    __strong __typeof__(self.dataSource) dataSource = self.dataSource;
    
    if (!self.maxCellSize) {
        self.maxCellSize = [dataSource HUDCollectionViewMaximumCellSize:self];
        // dataSource side effect may have called reloadData, in which case it's not safe to continue anymore.
        if (self.reloading) { return; }
    }
    
    [self.cells makeObjectsPerformSelector:NNTypedSelector(NSView, removeFromSuperview)];
    [self.cells removeAllObjects];
    
    self.numberOfCells = [dataSource HUDCollectionViewNumberOfCells:self];
    // dataSource side effect may have called reloadData, in which case it's not safe to continue anymore.
    if (self.reloading) { return; }
    
    [self _setHUDSize:[self _computeCollectionViewSize]];
    
    for (NSUInteger i = 0; i < self.numberOfCells; i++) {
        NSView *cell = [dataSource HUDCollectionView:self viewForCellAtIndex:i];
        // dataSource side effect may have called reloadData, in which case it's not safe to continue anymore.
        if (self.reloading) { return; }
        
        [self.cells insertObject:cell atIndex:i];
        cell.frame = [self _computeFrameForCellAtIndex:i];
        [self.hud addSubview:cell];
    }
    
    if (self.selectionBox) {
        self.selectionBox.frame = nnItemRect((self.hud.frame.size.height - kNNWindowToThumbInset * 2.0), self.selectedIndex);
        [self.hud addSubview:self.selectionBox positioned:NSWindowBelow relativeTo:nil];
    }
    
    [self.hud setNeedsDisplay:YES];
}

@end
