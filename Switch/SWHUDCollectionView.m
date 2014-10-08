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

#import "NSLayoutConstraint+SWConstraintHelpers.h"
#import "SWHUDView.h"
#import "SWSelectionBoxView.h"


@interface SWHUDCollectionView ()

// dataSource information.
@property (nonatomic, assign, readwrite) CGFloat maxCellSize;
@property (nonatomic, assign, readwrite) NSUInteger numberOfCells;
@property (nonatomic, strong, readonly) NSMutableArray *cells;

// Persistent views.
@property (nonatomic, strong, readonly) SWHUDView *hud;
@property (nonatomic, strong, readonly) SWSelectionBoxView *selectionBox;

// Constraint tracking.
@property (nonatomic, strong, readwrite) NSArray *selectionBoxConstraints;
@property (nonatomic, strong, readwrite) NSArray *collectionConstraints;

// Internal state.
@property (nonatomic, assign, readwrite) BOOL reloading;
@property (nonatomic, assign, readwrite) NSUInteger selectedIndex;

@end


@implementation SWHUDCollectionView

#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    
    _cells = [NSMutableArray new];
    _hud = [[SWHUDView alloc] initWithFrame:CGRectZero];
    _selectionBox = [[SWSelectionBoxView alloc] initWithFrame:CGRectZero];
    _selectedIndex = NSNotFound;

    return self;
}

#pragma mark - NSResponder

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

#pragma mark - NSView

+ (BOOL)requiresConstraintBasedLayout;
{
    return YES;
}

- (void)viewWillMoveToSuperview:(NSView *)newSuperview;
{
    if (![self.subviews containsObject:self.hud]) {
        self.hud.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.hud];
    }

    // Force layout and subview insertion of the selection box if necessary.
    [self selectCellAtIndex:self.selectedIndex];
}

- (void)updateConstraints;
{
    if (!self.collectionConstraints) {
        [self _updateConstraintsForCollection];
    }

    if (!self.selectionBoxConstraints) {
        [self _updateConstraintsForSelectionBox];
    }
    [super updateConstraints];
}

#pragma mark - SWHUDCollectionView

- (void)setDataSource:(id<SWHUDCollectionViewDataSource>)dataSource;
{
    Assert([NSThread isMainThread]);
    _dataSource = dataSource;
    
    [self reloadData];
}

- (NSView *)cellForIndex:(NSUInteger)index;
{
    Assert([NSThread isMainThread]);

    // Flush pending reloadData
    [self _reloadDataIfNeeded];

    if (index < [self.cells count]) {
        return [self.cells objectAtIndex:index];
    }
    return nil;
}

- (void)selectCellAtIndex:(NSUInteger)index;
{
    Assert([NSThread isMainThread]);
    Check(self.selectionBox);
    
    self.selectedIndex = index;
    
    if (self.selectedIndex < self.numberOfCells) {
        [self _constraintsForSelectionBoxNeedUpdate];
    } else if ([self.hud.subviews containsObject:self.selectionBox]) {
        [self.selectionBox removeFromSuperview];
    }
}

- (void)deselectCell;
{
    [self selectCellAtIndex:NSNotFound];
}

- (void)reloadData;
{
    Assert([NSThread isMainThread]);

    if (!self.reloading) {
        self.reloading = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _reloadDataIfNeeded];
        });
    }
}

#pragma mark - Internal

- (NSUInteger)_indexForCellAtPoint:(NSPoint)point;
{
    for (NSUInteger i = 0; i < self.numberOfCells; ++i) {
        NSPoint relativePoint = [self convertPoint:point toView:self.cells[i]];
        CGRect cellFrame = CLASS_CAST(NSView, self.cells[i]).bounds;
        
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
    
    [self _constraintsForCollectionNeedUpdate];
    [self _constraintsForSelectionBoxNeedUpdate];
}

- (void)_constraintsForCollectionNeedUpdate;
{
    if (self.collectionConstraints) {
        [self removeConstraints:self.collectionConstraints];
        self.collectionConstraints = nil;
    }
    [self setNeedsUpdateConstraints:YES];
}

- (void)_updateConstraintsForCollection;
{
    if (!Check(!self.collectionConstraints.count)) {
        [self removeConstraints:self.collectionConstraints];
        self.collectionConstraints = nil;
    }

    NSMutableArray *constraints = [NSMutableArray new];

    NSDictionary *views = @{
        @"hud" : self.hud,
        @"collection" : self,
    };

    NSDictionary *metrics = @{
        @"hudPadding" : @(kNNScreenToWindowInset),
        @"cellPadding" : @(kNNWindowToThumbInset),
        @"maxThumbSize" : @(self.maxCellSize),
        @"emptyHUDSize" : @(self.maxCellSize + (kNNWindowToThumbInset * 2.0)),
        @"windowWidth" : @(self.frame.size.width),
        @"windowHeight" : @(self.frame.size.height),
    };

    // Maintain the size of the frame in case there are too many objects in the collection and Auto Layout attempts to enlarge it.
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[collection(windowWidth)]" options:NSLayoutFormatAlignAllCenterY metrics:metrics views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[collection(windowHeight)]" options:NSLayoutFormatAlignAllCenterY metrics:metrics views:views]];
    
    // Center the HUD inside its container view.
    [constraints addObjectsFromArray:[NSLayoutConstraint sw_constraintsCenteringView:self.hud toView:self]];

    // Establish flexible minimum HUD size, for when there are no cells to display.
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[hud(>=emptyHUDSize@500)]" options:NSLayoutFormatAlignAllCenterY metrics:metrics views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[hud(>=emptyHUDSize@500)]" options:NSLayoutFormatAlignAllCenterY metrics:metrics views:views]];

    // Ensure that the hud always has a minimum padding within its container view.
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=hudPadding)-[hud]-(>=hudPadding)-|" options:NSLayoutFormatAlignAllCenterY metrics:metrics views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=hudPadding)-[hud]-(>=hudPadding)-|" options:NSLayoutFormatAlignAllCenterY metrics:metrics views:views]];

    for (NSUInteger i = 0; i < self.numberOfCells; i++) {
        NSView *prevCell = i != 0 ? self.cells[i - 1] : nil;
        NSView *cell = self.cells[i];
        NSView *nextCell = i < (self.numberOfCells - 1) ? self.cells[i + 1] : nil;

        NSDictionary *cellViews = @{
            @"prevCell" : prevCell ?: [NSNull null],
            @"cell": cell,
            @"nextCell" : nextCell ?: [NSNull null],
            @"hud" : self.hud,
        };

        if (!prevCell) {
            // First cell in the collection establishes the size that all of the others follow. Max size, with lower priority so it will be compromised if layout pressure exists due to too many cells.
            [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"[cell(maxThumbSize@750)]" options:NSLayoutFormatAlignAllCenterY metrics:metrics views:cellViews]];

            // First cell in the collection must have RHS padding to its superview (the hud).
            [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(cellPadding)-[cell]" options:NSLayoutFormatAlignAllCenterY metrics:metrics views:cellViews]];
        } else {
            // Non-first cells set their width (and thus their size due to the aspect ratio constraint) to be equal to the first cell's width.
            [constraints addObject:[NSLayoutConstraint constraintWithItem:cell attribute:NSLayoutAttributeWidth
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.cells[0] attribute:NSLayoutAttributeWidth
                                                            multiplier:1.f constant:0.f]];

            // Middle cells in the collection must have LHS padding to their neighbouring cell.
            [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[prevCell]-(cellPadding)-[cell]" options:NSLayoutFormatAlignAllCenterY metrics:metrics views:cellViews]];
        }

        // Cells have a fixed aspect ratio (square).
        [constraints addObject:[NSLayoutConstraint constraintWithItem:cell attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:cell attribute:NSLayoutAttributeWidth
                                                        multiplier:1.f constant:0.f]];

        // Cell must have top/bottom padding to its superview (the hud).
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(cellPadding)-[cell]-(cellPadding)-|" options:NSLayoutFormatAlignAllCenterY metrics:metrics views:cellViews]];

        if (!nextCell) {
            // Last cell in the collection must have LHS padding to its superview (the hud).
            [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[cell]-(cellPadding)-|" options:NSLayoutFormatAlignAllCenterY metrics:metrics views:cellViews]];
        }
    }

    self.collectionConstraints = [constraints copy];
    [self addConstraints:self.collectionConstraints];
}

- (void)_constraintsForSelectionBoxNeedUpdate;
{
    if (self.selectionBoxConstraints) {
        [self removeConstraints:self.selectionBoxConstraints];
        self.selectionBoxConstraints = nil;
    }
    [self setNeedsUpdateConstraints:YES];
}

- (void)_updateConstraintsForSelectionBox;
{
    if (!Check(!self.selectionBoxConstraints.count)) {
        [self removeConstraints:self.selectionBoxConstraints];
        self.selectionBoxConstraints = nil;
    }

    NSMutableArray *constraints = [NSMutableArray new];

    if (self.selectedIndex < self.numberOfCells) {
        Check(self.selectionBox);
        
        // Selection box (re)insertion into the view hierarchy happens during layout-time to prevent the box appearing to jump between its old location (pre-deselection) and its new location.
        if (![self.hud.subviews containsObject:self.selectionBox]) {
            [self.hud addSubview:self.selectionBox positioned:NSWindowBelow relativeTo:nil];
        }

        NSView *selectedView = self.cells[self.selectedIndex];

        // Constraint: selection box must be centered over selection thumb
        [constraints addObjectsFromArray:[NSLayoutConstraint sw_constraintsCenteringView:self.selectionBox toView:selectedView]];

        // Selection box height and width must be thumb [height|width] + const
        [constraints addObject:[NSLayoutConstraint constraintWithItem:self.selectionBox attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:selectedView attribute:NSLayoutAttributeWidth
                                                        multiplier:1.f constant:(kNNWindowToThumbInset + kNNItemBorderWidth)]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:self.selectionBox attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:selectedView attribute:NSLayoutAttributeHeight
                                                        multiplier:1.f constant:(kNNWindowToThumbInset + kNNItemBorderWidth)]];
    }

    self.selectionBoxConstraints = [constraints copy];
    [self addConstraints:self.selectionBoxConstraints];
}

@end
