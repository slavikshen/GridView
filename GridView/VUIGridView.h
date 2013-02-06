//
//  VUIGridView.h
//  Youplay
//
//  Created by Slavik Shen on 12/13/11.
//  Copyright (c) 2011 apollobrowser.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "VUIGridCellView.h"
#import "VUIGVPullRrefrehViewProtocol.h"
#import "VUIGVMoreView.h"

#define SRELEASE(x) { [x release]; x = nil; }
#define IS_PIXEL_COORDINATE_CHANGED(a,b) (ABS(a-b)>1)
#define IS_SIZE_CHANGED(p,n) (ABS(p.width-n.width)>1||ABS(p.height-n.height)>1)
#define IS_POSITION_CHANGED(p,n) (ABS(p.x-n.x)>1||ABS(p.y-n.y)>1)

#define IS_DIFFERENT_FRAME(p,n) (IS_SIZE_CHANGED(p.size,n.size)||IS_POSITION_CHANGED(p.origin,n.origin))

#define VUIGRIDVIEW_CELL_ANI_DURATION (0.5f)

#define VUIGRIDVIEW_DEFAULT_CELL_SIZE CGSizeMake(320, 240)
#define VUIGRIDVIEW_DEFAULT_CELL_SPACING CGSizeMake(1, 20)

#define GRIDVIEW_SHADOW_HEIGHT 2

#define _L(x) (NSLocalizedString(x,@""))
#define _F(fmt,...) ([NSString stringWithFormat:fmt, ##__VA_ARGS__] )

#define IS_SIZE_CHANGED(p,n) (ABS(p.width-n.width)>1||ABS(p.height-n.height)>1)
#define SRELEASE(x) { [x release]; x = nil; }

//#define PULL_REFRESH_VIEW_HEIGHT_IPHONE 44
//#define PULL_REFRESH_VIEW_HEIGHT_IPAD   64
//#define PULL_REFRESH_VIEW_HEIGHT ( IS_PHONE ? PULL_REFRESH_VIEW_HEIGHT_IPHONE : PULL_REFRESH_VIEW_HEIGHT_IPAD )
//#define PULL_REFRESH_VIEW_WIDTH 320
//
//#define MORE_VIEW_HEIGHT_IPHONE 44
//#define MORE_VIEW_HEIGHT_IPAD   64
//#define MORE_VIEW_HEIGHT ( IS_PHONE ? MORE_VIEW_HEIGHT_IPHONE : MORE_VIEW_HEIGHT_IPAD )
//#define MORE_VIEW_WIDTH 320

#if TARGET_OS_IPHONE
#define MAX_PULL_REFRESH_TAIL_LENGTH_FOR_RECOGNIZING 36
#else
#define MAX_PULL_REFRESH_TAIL_LENGTH_FOR_RECOGNIZING 18
#endif
typedef enum {

    VUIGridViewMode_Vertical,
    VUIGridViewMode_Horizontal,

} VUIGridViewMode;

typedef enum {

    VUIGridViewPullRefreshState_Idle,
    VUIGridViewPullRefreshState_Dragging,
    VUIGridViewPullRefreshState_Recognized,
    VUIGridViewPullRefreshState_Refreshing

} VUIGridViewPullRefreshIndicatorState;

typedef enum {

    VUIGridViewMoreState_Idle,
    VUIGridViewMoreState_Refreshing

} VUIGridViewMoreIndicatorState;

@class VUIGridView;

@protocol VUIGridViewDataSource <NSObject>

- (NSInteger)numberOfCellOfGridView:(VUIGridView*)gridView;
- (CGSize)cellSizeOfGridView:(VUIGridView*)gridView;
- (CGSize)cellSpacingOfGridView:(VUIGridView*)gridView;

// sync create and set cell
- (VUIGridCellView*)gridView:(VUIGridView*)gridView cellAtIndex:(NSUInteger)index;

@optional
// async create and set cell
- (void)gridView:(VUIGridView*)gridView upgradeCellAtIndex:(NSUInteger)index;

@end

@protocol VUIGridViewDelegate <NSObject, UIScrollViewDelegate>

@optional
- (void)gridView:(VUIGridView *)gridView didDeselectCellAtIndexPath:(NSUInteger)index;
- (void)gridView:(VUIGridView *)gridView didSelectCellAtIndexPath:(NSUInteger)index;
- (void)gridView:(VUIGridView *)gridView didShowCellAtIndex:(NSUInteger)index;
- (void)gridView:(VUIGridView *)gridView didHideCellAtIndex:(NSUInteger)index;

// if the delegate implemented gridViewDidRequestRefresh:, then there will be a pull refresh indicator in the gridview
- (void)gridViewDidRequestRefresh:(VUIGridView *)gridView;
- (id<VUIGVPullRrefrehViewProtocol>)pullRefreshViewForGridView:(VUIGridView*)gridView;

// if the delegate implemented gridViewDidRequestMore:, then there will be a more indicator in the gridview
- (void)gridViewDidRequestMore:(VUIGridView *)gridView;
- (id<VUIGVPullRrefrehViewProtocol>)moreViewForGridView:(VUIGridView*)gridView;

- (BOOL)isThereMoreDataForGridView:(VUIGridView *)gridView;


@end


@interface VUIGridView : UIView {

@protected
	NSMutableSet* _visibleCells;
	NSMutableSet* _recycledCells;
    
    NSUInteger _numberOfCell;
    NSUInteger _numberOfColumn;
    NSUInteger _numberOfRow;
    NSUInteger _numberOfColumnInPage;
    NSUInteger _numberOfRowInPage;
    NSUInteger _numberOfCellInPage;
    
    BOOL _delegateWillResponseSelect;
    BOOL _delegateWillResponseDeselect;
    BOOL _delegateWillResponseRefresh;
    BOOL _delegateWillResponseMore;
    
	BOOL _dataSourceWillUpgradeContent;

    
    #ifdef ENABLE_GRIDVIEW_ANIMATION_CHANGE
    
    BOOL _needAnimateChange;
   
    #endif
    
    CGSize _cellSize;
    CGSize _cellSpacing;
    
    BOOL _updating;
    
    CAGradientLayer* _topShadowLayer;
    
    NSUInteger _selectedIndex;

}

@property(nonatomic,assign) VUIGridViewMode mode;

@property(nonatomic,assign) IBOutlet id<VUIGridViewDataSource> dataSource;
@property(nonatomic,assign) IBOutlet id<VUIGridViewDelegate> delegate;

@property(nonatomic,readonly,assign) UILabel* emtpyHintLabel;

@property(nonatomic,readonly,assign) UIScrollView* scrollView;

@property(nonatomic,readonly,assign) NSUInteger numberOfCell;
@property(nonatomic,readonly,assign) NSUInteger numberOfColumn;
@property(nonatomic,readonly,assign) NSUInteger numberOfRow;

@property(nonatomic,assign) NSUInteger selectedIndex;

@property(nonatomic,readonly,assign) VUIGridViewPullRefreshIndicatorState pullRefreshIndicatorState;
@property(nonatomic,readonly,assign) VUIGridViewMoreIndicatorState moreIndicatorState;

@property(nonatomic,retain) id<VUIGVPullRrefrehViewProtocol> pullRefreshView;
@property(nonatomic,retain) id<VUIGVPullRrefrehViewProtocol> moreView;

@property(nonatomic,assign) BOOL showTopShadow;

@property(nonatomic,retain) UIView* backgroundView;
@property(nonatomic,retain) UIView* emptyView;

- (void)setup;

- (void)reloadData;
- (void)beginUpdate;
- (void)endUpdate;

- (void)insertCellAtIndex:(NSUInteger)index animated:(BOOL)animated;
- (void)removeCellAtIndex:(NSUInteger)index animated:(BOOL)animated;
- (void)reloadCellAtIndex:(NSUInteger)index animated:(BOOL)animated;

- (void)insertCellsAtIndexes:(NSIndexSet*)indexes animated:(BOOL)animated;
- (void)removeCellsAtIndexex:(NSIndexSet*)indexes animated:(BOOL)animated;
- (void)reloadCellsAtIndexes:(NSIndexSet*)indexes animated:(BOOL)animated;

- (id)dequeueGridCellViewFromPool:(NSString*)cellID;

- (id)cellAtIndex:(NSUInteger)index;

- (void)setRefreshIndicatorState:(VUIGridViewPullRefreshIndicatorState)state animated:(BOOL)animated;
- (void)setMoreIndicatorState:(VUIGridViewMoreIndicatorState)state animated:(BOOL)animated;

- (NSString*)textForPullRefreshIndicatorState:(VUIGridViewPullRefreshIndicatorState)state;
- (NSString*)textForMoreIndicatorState:(VUIGridViewMoreIndicatorState)state;
- (void)setText:(NSString*)text forPullRefreshIndicatorState:(VUIGridViewPullRefreshIndicatorState)state;
- (void)setText:(NSString*)text forMoreIndicatorState:(VUIGridViewMoreIndicatorState)state;


@end

