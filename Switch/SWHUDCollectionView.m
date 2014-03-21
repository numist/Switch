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

#import <ReactiveCocoa/EXTScope.h>

#import "SWHUDView.h"
#import "SWSelectionBoxView.h"


@interface SWHUDCollectionView ()

@property (nonatomic, assign) CGFloat maxCellSize;
@property (nonatomic, assign, readwrite) NSUInteger numberOfCells;

@property (nonatomic, strong, readonly) NSMutableArray *cells;
@property (nonatomic, strong, readonly) SWHUDView *hud;
@property (nonatomic, strong, readwrite) SWSelectionBoxView *selectionBox;

@property (nonatomic, copy, readwrite) NSArray *currentConstraints;

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

+ (BOOL)requiresConstraintBasedLayout;
{
    return YES;
}

- (void)viewWillMoveToSuperview:(NSView *)newSuperview;
{
    if (!self.hud) {
        _hud = [[SWHUDView alloc] initWithFrame:NSZeroRect];
        [self addSubview:self.hud];
        
        self.hud.translatesAutoresizingMaskIntoConstraints = NO;
    }
}

- (void)updateConstraints;
{
    if (!Check(!self.constraints.count)) {
        [self removeConstraints:self.constraints];
    }

    [super updateConstraints];
    if (self.currentConstraints) {
        return;
    }
    
    NSDictionary *views = @{
        @"hud" : self.hud,
        @"collection" : self,
    };
    
    NSDictionary *metrics = @{
        @"hudPadding" : @(kNNScreenToWindowInset),
        @"cellPadding" : @(kNNWindowToThumbInset),
        @"maxThumbSize" : @(kNNMaxWindowThumbnailSize),
        @"emptyHUDSize" : @(kNNMaxWindowThumbnailSize + (kNNWindowToThumbInset * 2.0)),
        @"windowWidth" : @(self.frame.size.width),
        @"windowHeight" : @(self.frame.size.height),
    };
    
    // Maintain the size of the frame.
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[collection(windowWidth)]" options:NSLayoutFormatAlignAllCenterY metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[collection(windowHeight)]" options:NSLayoutFormatAlignAllCenterY metrics:metrics views:views]];

    // Center the HUD inside its container view.
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.hud attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.f constant:0.f]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.hud attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.f constant:0.f]];
    
    // Ensure that the hud always has a minimum padding within its container view.
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=hudPadding)-[hud]-(>=hudPadding)-|" options:NSLayoutFormatAlignAllCenterY metrics:metrics views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=hudPadding)-[hud]-(>=hudPadding)-|" options:NSLayoutFormatAlignAllCenterY metrics:metrics views:views]];
    
    for (NSUInteger i = 0; i < self.numberOfCells; i++) {
        NSView *prevCell = i != 0 ? self.cells[i - 1] : nil;
        NSView *cell = self.cells[i];
        NSView *nextCell = i < (self.numberOfCells - 1) ? self.cells[i + 1] : nil;
        
        NSDictionary *cellConstraintViews = @{
            @"prevCell" : prevCell ?: [NSNull null],
            @"cell": cell,
            @"nextCell" : nextCell ?: [NSNull null],
            @"hud" : self.hud,
        };
        
        // Cells have a fixed aspect ratio (square).
        [self addConstraint:[NSLayoutConstraint constraintWithItem:cell attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:cell attribute:NSLayoutAttributeWidth
                                                        multiplier:1.f constant:0.f]];
        
        if (prevCell) {
            // Non-first cells set their width (and thus their size due to the aspect ratio constraint) to be equal to the first cell's width.
            [self addConstraint:[NSLayoutConstraint constraintWithItem:cell attribute:NSLayoutAttributeWidth
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.cells[0] attribute:NSLayoutAttributeWidth
                                                            multiplier:1.f constant:0.f]];
            
            // Middle cells in the collection must have LHS padding to their neighbouring cell.
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[prevCell]-(cellPadding)-[cell]" options:NSLayoutFormatAlignAllCenterY metrics:metrics views:cellConstraintViews]];
        } else {
            // First cell in the collection establishes the size that all of the others follow. Max size, with lower priority so it will be compromised if layout pressure exists due to too many cells.
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[cell(maxThumbSize@777)]" options:NSLayoutFormatAlignAllCenterY metrics:metrics views:cellConstraintViews]];
            
            // First cell in the collection must have RHS padding to its superview (the hud).
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(cellPadding)-[cell]" options:NSLayoutFormatAlignAllCenterY metrics:metrics views:cellConstraintViews]];
        }
        
        // Cell must have top/bottom padding to its superview (the hud).
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(cellPadding)-[cell]-(cellPadding)-|" options:NSLayoutFormatAlignAllCenterY metrics:metrics views:cellConstraintViews]];
        
        if (!nextCell) {
            // Last cell in the collection must have LHS padding to its superview (the hud).
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[cell]-(cellPadding)-|" options:NSLayoutFormatAlignAllCenterY metrics:metrics views:cellConstraintViews]];

        }

        if (i == self.selectedIndex) {
            // Constraint: selection box must be centered over selection thumb
            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.selectionBox attribute:NSLayoutAttributeCenterX
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:cell attribute:NSLayoutAttributeCenterX
                                                            multiplier:1.f constant:0.f]];
            
            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.selectionBox attribute:NSLayoutAttributeCenterY
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:cell attribute:NSLayoutAttributeCenterY
                                                            multiplier:1.f constant:0.f]];
            
            // Selection box height and width must be thumb [height|width] + const
            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.selectionBox attribute:NSLayoutAttributeWidth
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:cell attribute:NSLayoutAttributeWidth
                                                            multiplier:1.f constant:(kNNWindowToThumbInset + kNNItemBorderWidth)]];
            
            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.selectionBox attribute:NSLayoutAttributeHeight
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:cell attribute:NSLayoutAttributeHeight
                                                            multiplier:1.f constant:(kNNWindowToThumbInset + kNNItemBorderWidth)]];
        }
    }
    
    if (self.numberOfCells == 0) {
        // Empty HUD is square.
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.hud attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.hud attribute:NSLayoutAttributeWidth
                                                        multiplier:1.f constant:0.f]];
        
        // Empty HUD has the size of the HUD as if it contained one item.
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[hud(emptyHUDSize)]" options:NSLayoutFormatAlignAllCenterY metrics:metrics views:views]];
    }

    self.currentConstraints = self.constraints;
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
    
    self.currentConstraints = nil;
    [self removeConstraints:self.constraints];
    [self setNeedsUpdateConstraints:YES];
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

- (NSUInteger)_indexForCellAtPoint:(NSPoint)point;
{
    for (NSUInteger i = 0; i < self.numberOfCells; ++i) {
        NSPoint relativePoint = [self convertPoint:point toView:self.cells[i]];
        NSRect cellFrame = CLASS_CAST(NSView, self.cells[i]).bounds;
        
        if (NSPointInRect(relativePoint, cellFrame)) {
            return i;
        }
    }
    
    return NSNotFound;
}

- (void)_reloadDataIfNeeded;
{
    if (!self.reloading) { return; }
    
    @weakify(self);
    dispatch_block_t cleanupData = ^{
        @strongify(self);
        self.numberOfCells = 0;
        [self.cells makeObjectsPerformSelector:NNTypedSelector(NSView, removeFromSuperview)];
        [self.cells removeAllObjects];
    };
    
    self.reloading = NO;
    
    __strong __typeof__(self.dataSource) dataSource = self.dataSource;
    
    if (!self.maxCellSize) {
        self.maxCellSize = [dataSource HUDCollectionViewMaximumCellSize:self];
        // dataSource side effect may have called reloadData, in which case it's not safe to continue anymore.
        BailWithBlockUnless(!self.reloading, cleanupData);
    }
    
    cleanupData();
    
    self.numberOfCells = [dataSource HUDCollectionViewNumberOfCells:self];
    // dataSource side effect may have called reloadData, in which case it's not safe to continue anymore.
    BailWithBlockUnless(!self.reloading, cleanupData);
    
    for (NSUInteger i = 0; i < self.numberOfCells; i++) {
        NSView *cell = [dataSource HUDCollectionView:self viewForCellAtIndex:i];
        // dataSource side effect may have called reloadData, in which case it's not safe to continue anymore.
        BailWithBlockUnless(!self.reloading, cleanupData);
        
        [self.cells insertObject:cell atIndex:i];
        [self.hud addSubview:cell];
    }
    
    if (self.selectionBox) {
        [self.hud addSubview:self.selectionBox positioned:NSWindowBelow relativeTo:nil];
    }
    
    self.currentConstraints = nil;
    [self removeConstraints:self.constraints];
    [self setNeedsUpdateConstraints:YES];
}

@end
