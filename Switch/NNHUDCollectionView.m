//
//  NNHUDCollectionView.m
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

#import "NNHUDCollectionView.h"

#import "constants.h"
#import "NNSelectionBoxView.h"


typedef NS_ENUM(uint8_t, NNHUDCollectionViewUpdateType) {
    NNHUDCollectionViewUpdateInsert,
    NNHUDCollectionViewUpdateMove,
    NNHUDCollectionViewUpdateDelete
};

@interface NNHUDCollectionViewUpdate : NSObject
@property (nonatomic, assign, readonly) NNHUDCollectionViewUpdateType type;
@property (nonatomic, assign, readonly) NSUInteger index;
@property (nonatomic, assign, readonly) NSUInteger newIndex;
@property (nonatomic, assign, readonly) BOOL animate;
@end

@implementation NNHUDCollectionViewUpdate
- (instancetype)initWithType:(NNHUDCollectionViewUpdateType)type index:(NSUInteger)index animate:(BOOL)animate;
{ self = [super init]; if (!self) { return nil; } _type = type; _index = index; _animate = animate; return self; }
- (instancetype)initMoveWithIndex:(NSUInteger)index newIndex:(NSUInteger)newIndex;
{ self = [self initWithType:NNHUDCollectionViewUpdateMove index:index animate:YES]; _newIndex = newIndex; return self; }
@end


@interface NNHUDCollectionView ()

@property (nonatomic, assign) NSUInteger numberOfCells;
@property (nonatomic, strong) NSMutableArray *cells;

@property (nonatomic, strong) NNSelectionBoxView *selectionBox;
@property (nonatomic, assign) NSUInteger selectedIndex;

@property (nonatomic, strong) NSMutableArray *updates;

@end


@implementation NNHUDCollectionView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    
    _cells = [NSMutableArray new];
    _updates = [NSMutableArray new];
    
    return self;
}

#pragma mark - NNHUDCollectionView properties

- (void)setDataSource:(id<NNHUDCollectionViewDataSource>)dataSource;
{
    NSAssert([[NSThread currentThread] isMainThread], @"UI on main thread only!");
    _dataSource = dataSource;
    
    [self reloadData];
}

#pragma mark - NNHUDCollectionView methods

- (NSView *)cellForIndex:(NSUInteger)index;
{
    NSAssert([[NSThread currentThread] isMainThread], @"UI on main thread only!");

    if (index < [self.cells count]) {
        return [self.cells objectAtIndex:index];
    }
    return nil;
}

- (NSUInteger)indexForCell:(NSView *)cell;
{
    NSAssert([[NSThread currentThread] isMainThread], @"UI on main thread only!");

    return [self.cells indexOfObject:cell];
}

- (NSUInteger)indexForSelectedRow;
{
    NSAssert([[NSThread currentThread] isMainThread], @"UI on main thread only!");
    abort();

    return NSNotFound;
}

- (void)selectCellAtIndex:(NSUInteger)index;
{
    // TODO(numist): this should probably be coalesced into the current update block if such a thing exists.
    NSAssert([[NSThread currentThread] isMainThread], @"UI on main thread only!");
    
    self.selectedIndex = index;

    if (!self.selectionBox) {
        NNSelectionBoxView *selectionBox = [[NNSelectionBoxView alloc] initWithFrame:NSZeroRect];
        [self addSubview:selectionBox positioned:NSWindowBelow relativeTo:nil];
        self.selectionBox = selectionBox;
    }
    
    self.selectionBox.frame = nnItemRect((self.frame.size.height - kNNWindowToThumbInset * 2.0), self.selectedIndex);
    [self.selectionBox setNeedsDisplay:YES];
}

- (void)deselectCell;
{
    // TODO(numist): this should probably be coalesced into the current update block if such a thing exists.
    [self.selectionBox removeFromSuperview];
    self.selectionBox = nil;
}

- (void)beginUpdates;
{
    NSAssert([[NSThread currentThread] isMainThread], @"UI on main thread only!");
    
    [self.updates addObject:[NSMutableArray new]];
}

- (void)endUpdates;
{
    NSAssert([[NSThread currentThread] isMainThread], @"UI on main thread only!");
    NSAssert([self.updates count], @"endUpdates called without a corresponding call to beginUpdates");
    
    NSArray *updates = [self.updates lastObject];
    [self.updates removeLastObject];

    for (NNHUDCollectionViewUpdate *update in updates) {
        NSView *cell = update.index < [self.cells count] ? [self.cells objectAtIndex:update.index] : nil;
        switch (update.type) {
            case NNHUDCollectionViewUpdateDelete:
                [self.cells removeObjectAtIndex:update.index];
                [cell removeFromSuperview];
                cell = nil;
                self.numberOfCells--;
                break;
                
            case NNHUDCollectionViewUpdateInsert:
                cell = [self.dataSource HUDView:self viewForCellAtIndex:update.index];
                [self.cells insertObject:cell atIndex:update.index];
                [self addSubview:cell];
                self.numberOfCells++;
                break;
                
            case NNHUDCollectionViewUpdateMove: {
                cell = [self.cells objectAtIndex:update.index];
                [self.cells removeObjectAtIndex:update.index];
                [self.cells insertObject:cell atIndex:update.newIndex];
                break;
            }
        }
        
        [self setSize:[self computeCollectionViewSize]];
        self.selectionBox.frame = nnItemRect((self.frame.size.height - kNNWindowToThumbInset * 2.0), self.selectedIndex);
        for (NSUInteger i = 0; i < [self.cells count]; i++) {
            ((NSView *)[self.cells objectAtIndex:i]).frame = [self computeFrameForCellAtIndex:i];
        }
    }
    
    if ([updates count]) {
        [self setNeedsDisplay:YES];
    }
}

- (void)insertCellsAtIndexes:(NSArray *)indexes withAnimation:(BOOL)animate;
{
    NSAssert([[NSThread currentThread] isMainThread], @"UI on main thread only!");
    
    NSMutableArray *updates = [self.updates lastObject];
    for (NSNumber *index in indexes) {
        [updates addObject:[[NNHUDCollectionViewUpdate alloc] initWithType:NNHUDCollectionViewUpdateInsert index:[index unsignedIntegerValue] animate:animate]];
    }
}

- (void)deleteCellsAtIndexes:(NSArray *)indexes withAnimation:(BOOL)animate;
{
    NSAssert([[NSThread currentThread] isMainThread], @"UI on main thread only!");
    
    NSMutableArray *updates = [self.updates lastObject];
    for (NSNumber *index in indexes) {
        [updates addObject:[[NNHUDCollectionViewUpdate alloc] initWithType:NNHUDCollectionViewUpdateDelete index:[index unsignedIntegerValue] animate:animate]];
    }
}

- (void)moveCellAtIndex:(NSUInteger)index toIndex:(NSUInteger)newIndex;
{
    NSAssert([[NSThread currentThread] isMainThread], @"UI on main thread only!");
    
    [[self.updates lastObject] addObject:[[NNHUDCollectionViewUpdate alloc] initMoveWithIndex:index newIndex:newIndex]];
}

- (void)reloadData;
{
    NSAssert([[NSThread currentThread] isMainThread], @"UI on main thread only!");
    
    static BOOL reloading = NO;
    
    // Keep honking, I'm reloading.
    if (!reloading) {
        reloading = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            reloading = NO;

            __strong __typeof__(self.dataSource) dataSource = self.dataSource;

            [self.cells removeAllObjects];
            self.subviews = @[];
            
            self.numberOfCells = [dataSource HUDViewNumberOfCells:self];
            // dataSource side effect may have called reloadData, in which case it's not safe to continue anymore.
            if (reloading) { return; }
            
            [self setSize:[self computeCollectionViewSize]];
            
            for (NSUInteger i = 0; i < self.numberOfCells; i++) {
                NSView *cell = [dataSource HUDView:self viewForCellAtIndex:i];
                // dataSource side effect may have called reloadData, in which case it's not safe to continue anymore.
                if (reloading) { return; }
                
                [self.cells insertObject:cell atIndex:i];
                cell.frame = [self computeFrameForCellAtIndex:i];
                [self addSubview:cell];
            }
            
            if (self.selectionBox) {
                self.selectionBox.frame = nnItemRect((self.frame.size.height - kNNWindowToThumbInset * 2.0), self.selectedIndex);
                [self addSubview:self.selectionBox positioned:NSWindowBelow relativeTo:nil];
            }
            
            [self setNeedsDisplay:YES];
        });
    }
}

#pragma mark - NSResponder

- (BOOL)acceptsFirstResponder;
{
    return YES;
}

- (void)mouseMoved:(NSEvent *)theEvent;
{
    NSUInteger i = [self indexForCellAtPoint:theEvent.locationInWindow];
    
    if (i < self.numberOfCells && self.selectedIndex != i) {
        id<NNHUDCollectionViewDelegate> delegate = self.delegate;
        
        self.selectedIndex = i;
        
        if ([delegate respondsToSelector:@selector(HUDView:willSelectCellAtIndex:)]) {
            [delegate HUDView:self willSelectCellAtIndex:i];
        }
        
        [self selectCellAtIndex:self.selectedIndex];
        
        if ([delegate respondsToSelector:@selector(HUDView:didSelectCellAtIndex:)]) {
            [delegate HUDView:self didSelectCellAtIndex:self.selectedIndex];
        }
    }
    
    [super mouseMoved:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent;
{
    NSUInteger i = [self indexForCellAtPoint:theEvent.locationInWindow];

    if (i < self.numberOfCells) {
        id<NNHUDCollectionViewDelegate> delegate = self.delegate;
        
        Check(self.selectedIndex == i);
        self.selectedIndex = i;
        
        if ([delegate respondsToSelector:@selector(HUDView:activateCellAtIndex:)]) {
            [delegate HUDView:self activateCellAtIndex:i];
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

#pragma mark - Custom-indexed Subscripting

- (id)objectAtIndexedSubscript:(NSUInteger)idx;
{
    return [self cellForIndex:idx];
}

#pragma mark - Internal

- (void)setSize:(NSSize)size;
{
    self.frame = (NSRect){
        .size = size,
        .origin.x = self.frame.origin.x + ((self.frame.size.width - size.width) / 2.0),
        .origin.y = self.frame.origin.y + ((self.frame.size.height - size.height) / 2.0)
    };
}

- (CGFloat)computeCellSize;
{
    CGFloat cellSize = self.maxCellSize;
    CGFloat maxTheoreticalWindowWidth = nnTotalWidth(cellSize, self.numberOfCells);
    CGFloat requiredPaddings = nnTotalPadding(self.numberOfCells);
    
    if (maxTheoreticalWindowWidth > self.maxWidth) {
        cellSize = floor((self.maxWidth - requiredPaddings) / self.numberOfCells);
    }

    return cellSize;
}

- (NSSize)computeCollectionViewSize;
{
    CGFloat cellSize = [self computeCellSize];
    CGFloat maxTheoreticalWindowWidth = nnTotalWidth(cellSize, self.numberOfCells);
    
    if (self.numberOfCells == 0) {
        CGFloat min = MIN(kNNWindowToThumbInset + self.maxCellSize + kNNWindowToThumbInset, self.maxWidth);
        return (NSSize){
            .height = min,
            .width = min
        };
    }

    return (NSSize){
        .width = MIN(self.maxWidth, maxTheoreticalWindowWidth),
        .height = kNNWindowToThumbInset + cellSize + kNNWindowToThumbInset
    };
}

- (NSRect)computeFrameForCellAtIndex:(NSUInteger)index;
{
    return nnThumbRect([self computeCellSize], index);
}

- (NSUInteger)indexForCellAtPoint:(NSPoint)point;
{
    unsigned i;
    for (i = 0; i < self.numberOfCells; ++i) {
        NSRect frame = [self convertRect:[self computeFrameForCellAtIndex:i] toView:nil];
        
        if (NSPointInRect(point, frame)) {
            break;
        }
    }
    
    return i < [self.cells count] ? i : NSNotFound;
}

@end
