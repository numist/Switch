//
//  NNHUDCollectionView.h
//  Switch
//
//  Created by Scott Perry on 05/28/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNHUDView.h"


@protocol NNHUDCollectionViewDataSource;
@protocol NNHUDCollectionViewDelegate;


@interface NNHUDCollectionView : NNHUDView

@property (nonatomic, weak) id<NNHUDCollectionViewDataSource> dataSource;
@property (nonatomic, weak) id<NNHUDCollectionViewDelegate> delegate;

@property (nonatomic, assign) CGFloat maxCellSize;
@property (nonatomic, assign) CGFloat maxWidth;

- (NSUInteger)numberOfCells;

- (NSView *)cellForIndex:(NSUInteger)index;
- (NSUInteger)indexForCell:(NSView *)cell;
- (NSUInteger)indexForCellAtPoint:(NSPoint)point;

- (NSUInteger)indexForSelectedRow;
- (void)selectCellAtIndex:(NSUInteger)index;
- (void)deselectCell;

- (void)beginUpdates;
- (void)endUpdates;
- (void)insertCellsAtIndexes:(NSArray *)indexes withAnimation:(BOOL)animate;
- (void)deleteCellsAtIndexes:(NSArray *)indexes withAnimation:(BOOL)animate;
- (void)moveCellAtIndex:(NSUInteger)index toIndex:(NSUInteger)newIndex;

- (void)reloadData;

@end


@protocol NNHUDCollectionViewDataSource <NSObject>

- (NSView *)HUDView:(NNHUDCollectionView *)view viewForCellAtIndex:(NSUInteger)index;
- (NSUInteger)HUDViewNumberOfCells:(NNHUDCollectionView *)view;

@end


@protocol NNHUDCollectionViewDelegate <NSObject>

@optional
- (void)HUDView:(NNHUDCollectionView *)view willSelectCellAtIndex:(NSUInteger)index;
- (void)HUDView:(NNHUDCollectionView *)view didSelectCellAtIndex:(NSUInteger)index;

@end
