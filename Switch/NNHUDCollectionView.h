//
//  NNHUDCollectionView.h
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

#import "NNHUDView.h"


@protocol NNHUDCollectionViewDataSource;
@protocol NNHUDCollectionViewDelegate;


@interface NNHUDCollectionView : NNHUDView

@property (nonatomic, weak) id<NNHUDCollectionViewDataSource> dataSource;
@property (nonatomic, weak) id<NNHUDCollectionViewDelegate> delegate;

@property (nonatomic, assign) CGFloat maxCellSize;
@property (nonatomic, assign) CGFloat maxWidth;

@property (nonatomic, readonly) NSUInteger selectedIndex;

- (NSUInteger)numberOfCells;

- (NSView *)cellForIndex:(NSUInteger)index;
- (NSUInteger)indexForCell:(NSView *)cell;

- (NSUInteger)indexForSelectedRow;
- (void)selectCellAtIndex:(NSUInteger)index;
- (void)deselectCell;

- (void)beginUpdates;
- (void)endUpdates;
- (void)insertCellsAtIndexes:(NSArray *)indexes withAnimation:(BOOL)animate;
- (void)deleteCellsAtIndexes:(NSArray *)indexes withAnimation:(BOOL)animate;
- (void)moveCellAtIndex:(NSUInteger)index toIndex:(NSUInteger)newIndex;

- (void)reloadData;

- (id)objectAtIndexedSubscript:(NSUInteger)idx;

@end


@protocol NNHUDCollectionViewDataSource <NSObject>

- (NSView *)HUDView:(NNHUDCollectionView *)view viewForCellAtIndex:(NSUInteger)index;
- (NSUInteger)HUDViewNumberOfCells:(NNHUDCollectionView *)view;

@end


@protocol NNHUDCollectionViewDelegate <NSObject>

@optional
- (void)HUDView:(NNHUDCollectionView *)view willSelectCellAtIndex:(NSUInteger)index;
- (void)HUDView:(NNHUDCollectionView *)view didSelectCellAtIndex:(NSUInteger)index;
- (void)HUDView:(NNHUDCollectionView *)view activateCellAtIndex:(NSUInteger)index;

@end
