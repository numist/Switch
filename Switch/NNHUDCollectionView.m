//
//  NNHUDCollectionView.m
//  Switch
//
//  Created by Scott Perry on 05/28/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNHUDCollectionView.h"

#import "constants.h"
#import "NNSelectionBoxView.h"


@interface NNHUDCollectionView ()

@property (nonatomic, assign) NSUInteger numberOfCells;
@property (nonatomic, strong) NSMutableArray *cells;

@property (nonatomic, strong) NNSelectionBoxView *selectionBox;

@end


@implementation NNHUDCollectionView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    
    return self;
}

//- (void)drawRect:(NSRect)dirtyRect
//{
//    // Drawing code here.
//}

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

    return [self.cells objectAtIndex:index];
}

- (NSUInteger)indexForCell:(NSView *)cell;
{
    NSAssert([[NSThread currentThread] isMainThread], @"UI on main thread only!");

    return [self.cells indexOfObject:cell];
}

- (NSUInteger)indexForCellAtPoint:(NSPoint)point;
{
    NSAssert([[NSThread currentThread] isMainThread], @"UI on main thread only!");
    abort();

    return NSNotFound;
}

- (NSUInteger)indexForSelectedRow;
{
    NSAssert([[NSThread currentThread] isMainThread], @"UI on main thread only!");
    abort();

    return NSNotFound;
}

- (void)selectCellAtIndex:(NSUInteger)index;
{
    NSAssert([[NSThread currentThread] isMainThread], @"UI on main thread only!");
    
    NSParameterAssert(index < self.numberOfCells);

    NNSelectionBoxView *selectionBox;
    
    if (!self.selectionBox) {
        selectionBox = [[NNSelectionBoxView alloc] initWithFrame:NSZeroRect];
        [self addSubview:selectionBox positioned:NSWindowBelow relativeTo:nil];
        self.selectionBox = selectionBox;
    } else {
        selectionBox = self.selectionBox;
    }
    
    self.selectionBox.frame = nnItemRect((self.frame.size.height - kNNWindowToThumbInset * 2.0), index);
    [self.selectionBox setNeedsDisplay:YES];
}

- (void)deselectCell;
{
    [self.selectionBox removeFromSuperview];
    self.selectionBox = nil;
}

- (void)beginUpdates;
{
    NSAssert([[NSThread currentThread] isMainThread], @"UI on main thread only!");
    NSLog(@"Maybe don't call this yet");
}

- (void)endUpdates;
{
    NSAssert([[NSThread currentThread] isMainThread], @"UI on main thread only!");
    [self reloadData];
}

- (void)insertCellsAtIndexes:(NSArray *)indexes withAnimation:(BOOL)animate;
{
    NSAssert([[NSThread currentThread] isMainThread], @"UI on main thread only!");

}

- (void)deleteCellsAtIndexes:(NSArray *)indexes withAnimation:(BOOL)animate;
{
    NSAssert([[NSThread currentThread] isMainThread], @"UI on main thread only!");

}

- (void)moveCellAtIndex:(NSUInteger)index toIndex:(NSUInteger)newIndex;
{
    NSAssert([[NSThread currentThread] isMainThread], @"UI on main thread only!");

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
            
            // TODO(numist): Compute cell size and resize self as necessary.
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
                [self addSubview:self.selectionBox positioned:NSWindowBelow relativeTo:nil];
            }
            
            [self setNeedsDisplay:YES];
        });
    }
}

#pragma mark - Internal

- (void)setSize:(NSSize)size;
{
    NSRect frame = self.frame;
    frame.origin.x += (frame.size.width - size.width) / 2.0;
    frame.origin.y += (frame.size.height - size.height) / 2.0;
    frame.size = size;
    self.frame = frame;
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
    NSSize newSize;
    
    if (self.numberOfCells == 0) {
        newSize.height = MIN(self.maxCellSize, self.maxWidth);
        newSize.width = newSize.height;
        return newSize;
    }
    
    newSize.width = MIN(self.maxWidth, maxTheoreticalWindowWidth);
    newSize.height = kNNWindowToThumbInset + cellSize + kNNWindowToThumbInset;
    return newSize;
}

- (NSRect)computeFrameForCellAtIndex:(NSUInteger)index;
{
    return nnThumbRect([self computeCellSize], index);
}

@end
