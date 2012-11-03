//
//  VUIGridView.h
//  Youplay
//
//  Created by Slavik Shen on 12/13/11.
//  Copyright (c) 2011 apollobrowser.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VUIGridCellView.h"

#define VUIGRIDVIEW_CELL_ANI_DURATION (0.5f)

#define VUIGRIDVIEW_DEFAULT_CELL_SIZE CGSizeMake(320, 240)
#define VUIGRIDVIEW_DEFAULT_CELL_SPACING CGSizeMake(1, 20)

@class VUIGridView;

@protocol VUIGridViewDataSource <NSObject>

- (NSInteger)numberOfCellOfGridView:(VUIGridView*)gridView;

@optional

// sync create and set cell
- (VUIGridCellView*)gridView:(VUIGridView*)gridView cellAtIndex:(NSUInteger)index;

// async create and set cell
- (void)gridView:(VUIGridView*)gridView upgradeCellAtIndex:(NSUInteger)index;

@end

@protocol VUIGridViewDelegate <NSObject, UIScrollViewDelegate>

@optional
- (void)gridView:(VUIGridView *)gridView didSelectCellAtIndexPath:(NSUInteger)index;
- (void)gridView:(VUIGridView *)gridView didShowCellAtIndex:(NSUInteger)index;
- (void)gridView:(VUIGridView *)gridView didHideCellAtIndex:(NSUInteger)index;

@end


@interface VUIGridView : UIView {

@protected
	NSMutableSet* _visibleCells;
	NSMutableSet* _recycledCells;
    
    BOOL _needCheckVisibility;
    BOOL _updating;
    
    NSUInteger _numberOfCells;
    NSUInteger _numberOfColumns;
    NSUInteger _numberOfRows;
    
    BOOL _delegateWillResponseClick;
	BOOL _dataSourceWillUpgradeContent;
    
    CALayer* _aniLayer;
    
    BOOL _needAnimateChange;
    NSUInteger _changeStartIndex;
    
}

@property(nonatomic,readonly,assign) CGSize cellSize;
@property(nonatomic,readonly,assign) CGSize cellSpacing;

@property(nonatomic,assign) IBOutlet id<VUIGridViewDataSource> dataSource;
@property(nonatomic,assign) IBOutlet id<VUIGridViewDelegate> delegate;

@property(nonatomic,readonly,assign) UILabel* emtpyHintLabel;

@property(nonatomic,readonly,assign) UIScrollView* scrollView;

@property(nonatomic,readonly,assign) NSUInteger numberOfCells;
@property(nonatomic,readonly,assign) NSUInteger numberOfColumns;
@property(nonatomic,readonly,assign) NSUInteger numberOfRows;

- (void)setup;

- (void)reloadData;
- (void)beginUpdates;
- (void)endUpdates;

- (void)setCellSize:(CGSize)cellSize andSpacing:(CGSize)cellSpacing animate:(BOOL)animated;

- (void)insertCellAtIndex:(NSUInteger)index animated:(BOOL)animated;
- (void)removeCellAtIndex:(NSUInteger)index animated:(BOOL)animated;
- (void)reloadCellAtIndex:(NSUInteger)index animated:(BOOL)animated;

- (id)dequeueGridCellViewFromPool:(NSString*)cellID;

- (id)cellAtIndex:(NSUInteger)index;

@end

