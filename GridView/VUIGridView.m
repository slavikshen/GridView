//
//  VUIGridView.m
//  Youplay
//
//  Created by Slavik Shen on 12/13/11.
//  Copyright (c) 2011 apollobrowser.com. All rights reserved.
//

#import "VUIGridView.h"
#import "VUIGridView+Layout.h"
#import "VUIGridView+Private.h"
#import "VUIGridView+Ani.h"
#import "VUIGridView+ScrollViewDelegate.h"
#import "VUIGridCellView+Private.h"
#import "VUIGridViewUpdateCellContentOperation.h"

#import "VUIGridViewScrollView.h"

#import <QuartzCore/QuartzCore.h>

#ifdef VUI_DEBUG_VUIGRIDVIEW
#    define VUILog(...) NSLog(__VA_ARGS__)
#else
#    define VUILog(...) /* */
#endif

#define MAX_GRID_VIEW_POOL_SIZE 32

@interface VUIGridView()

@property(nonatomic,readwrite,assign) UIScrollView* scrollView;

@property(nonatomic,readwrite,assign) NSRange visibleRange;

@property(nonatomic,retain) NSOperationQueue* updateCellContentQueue;

@property(nonatomic,readwrite,assign) VUIGridViewPullRefreshIndicatorState pullRefreshIndicatorState;
@property(nonatomic,readwrite,assign) VUIGridViewMoreIndicatorState moreIndicatorState;


@end

@implementation VUIGridView {

    NSMutableDictionary* _pullRefreshIndicatorTexts;
    NSMutableDictionary* _moreIndicatorTexts;

}

@synthesize numberOfCell = _numberOfCell;
@synthesize numberOfColumn = _numberOfColumn;
@synthesize numberOfRow = _numberOfRow;
@synthesize selectedIndex =  _selectedIndex;

- (void)_hideTopShadowLayer {
    _topShadowLayer.opacity = 0;
}

- (void)_prepareTopShadowLayer {
    if (!self.showTopShadow) {
        return;
    }
    if( nil == _topShadowLayer ) {
        // create shadow
        CAGradientLayer *newShadow = [[CAGradientLayer alloc] init];
        CGRect newShadowFrame =
        CGRectMake(0, 0, self.bounds.size.width, GRIDVIEW_SHADOW_HEIGHT);
        newShadow.frame = newShadowFrame;
        newShadow.colors = @[
            (id)[UIColor colorWithWhite:0 alpha:0.3f].CGColor,
            (id)[UIColor colorWithWhite:0 alpha:0].CGColor,
        ];
        newShadow.zPosition = 1;
        _topShadowLayer = newShadow;
        
        [self.layer addSublayer:_topShadowLayer];
    }
}

- (void)setup {
    
    _topShadowLayer = YES;
    
    _numberOfColumn = 1;
    _numberOfRow = 1;
    _numberOfColumnInPage = 1;
    _numberOfRowInPage = 1;
    _numberOfCellInPage = 1;
    
    _selectedIndex = NSNotFound;

	_visibleCells = [[NSMutableSet alloc] initWithCapacity:MAX_GRID_VIEW_POOL_SIZE];
	_recycledCells = [[NSMutableSet alloc] initWithCapacity:MAX_GRID_VIEW_POOL_SIZE];

    VUIGridViewScrollView* scrollView = [[VUIGridViewScrollView alloc] initWithFrame:self.bounds];
    scrollView.gridView = self;
//    scrollView.delegate = self;
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrollView.alwaysBounceVertical = YES;
    scrollView.bounces = YES;
    scrollView.bouncesZoom = NO;
    scrollView.clipsToBounds = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.scrollsToTop = YES;
    scrollView.delaysContentTouches = YES;
    scrollView.canCancelContentTouches = YES;
    scrollView.backgroundColor = [UIColor clearColor];
    scrollView.autoresizesSubviews = NO;
    [self addSubview:scrollView];
    self.scrollView	= scrollView;
    
    [scrollView release];
    
    // default cell size
 	_cellSize = VUIGRIDVIEW_DEFAULT_CELL_SIZE;
   	_cellSpacing = VUIGRIDVIEW_DEFAULT_CELL_SPACING;
    
    [self _prepareTopShadowLayer];

}
#if TARGET_OS_IPHONE
- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
    if( self ) {
 		[self setup];   
    }
    return self;
}
#endif

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
    if( self ) {
    	[self setup];
    }
    return self;
}

- (void)dealloc {

    SRELEASE(_pullRefreshView);
    SRELEASE(_emptyView);
    SRELEASE(_backgroundView);
    SRELEASE(_topShadowLayer);
    
    if( _updateCellContentQueue ) {
        [_updateCellContentQueue cancelAllOperations];
        self.updateCellContentQueue = nil;
    }
    
    for( VUIGridCellView* v in _visibleCells ) {
        // make sure that all cell is cleaned
        // there might be some async operation to clean
        [self _cleanUpCellForRecycle:v];
    }
    
	SRELEASE(_visibleCells);
    SRELEASE(_recycledCells);
    
    ((VUIGridViewScrollView*)_scrollView).gridView = nil;
	_scrollView.delegate = nil;
    [super dealloc];
}

- (void)removeFromSuperview {
	[UIApplication cancelPreviousPerformRequestsWithTarget:self];
    [super removeFromSuperview];
}

- (id)dequeueGridCellViewFromPool:(NSString*)cellID {
	VUIGridCellView* cell = nil;
    for( VUIGridCellView* c in _recycledCells ) {
		if( [c.cellIdentity isEqualToString:cellID] ) {
        	cell = c;
            break;
        }
    }
    if( cell ) {
    	[[cell retain] autorelease];
        [_recycledCells removeObject:cell];
        [cell _setIsRecycled:NO];
    }
    return cell;
}

- (void)setBackgroundView:(UIView *)backgroundView {

    if( _backgroundView ) {
        [_backgroundView removeFromSuperview];
        [_backgroundView release];
    }
    _backgroundView = [backgroundView retain];
    if( _backgroundView ) {
        [_scrollView insertSubview:_backgroundView atIndex:0];
        _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        CGSize contentSize = _scrollView.contentSize;
        CGRect bgFrame = CGRectMake(0, 0, contentSize.width, contentSize.height);
        _backgroundView.frame = bgFrame;
    }
}


- (void)setMode:(VUIGridViewMode)mode {
    if( mode != _mode ) {
        _mode = mode;
        UIScrollView* scrollView = _scrollView;
        if( VUIGridViewMode_Horizontal == _mode ) {
            scrollView.pagingEnabled = YES;
            scrollView.alwaysBounceVertical = NO;
            [self _hideTopShadowLayer];
        } else {
            scrollView.pagingEnabled = NO;
            scrollView.alwaysBounceVertical = YES;
        }
        
        if( _numberOfCell ) {
            [self _resetContentSize];
            [self _setNeedCheckVisibility];
        }
    }
}

- (void)setDataSource:(id<VUIGridViewDataSource>)dataSource {
	if( _dataSource != dataSource ) {

    	_dataSource = dataSource;
        
        if( _dataSource ) {
            _dataSourceWillUpgradeContent = [_dataSource respondsToSelector:@selector(gridView:upgradeCellAtIndex:)];
            
            if( _dataSourceWillUpgradeContent ) {
                if( nil == _updateCellContentQueue ) {
                    NSOperationQueue* queue = [NSOperationQueue new];
                    self.updateCellContentQueue = queue;
                    [queue release];
                }
            } else {
                if( _updateCellContentQueue ) {
                    [_updateCellContentQueue cancelAllOperations];
                    self.updateCellContentQueue = nil;
                }
            }

            [self _doReloadData:NO];
        } else {
            if( _visibleCells.count ) {
                NSSet* visibles = [NSSet setWithSet:_visibleCells];
                for( VUIGridCellView* c in visibles ) {
                    [self _cleanUpCellForRecycle:c];
                }
                [_visibleCells removeAllObjects];
                [_recycledCells removeAllObjects];
            }
        }
    }
}

- (void)setDelegate:(id<VUIGridViewDelegate>)delegate {
	if( _delegate != delegate ) {
    	
        _delegate = delegate;

        SRELEASE(_pullRefreshIndicatorTexts);
        SRELEASE(_moreIndicatorTexts);
        
        if( _delegate ) {
        
            _delegateWillResponseSelect = [_delegate respondsToSelector:@selector(gridView:didSelectCellAtIndexPath:)];
            _delegateWillResponseDeselect = [_delegate respondsToSelector:@selector(gridView:didDeselectCellAtIndexPath:)];
            _delegateWillResponseRefresh = [_delegate respondsToSelector:@selector(gridViewDidRequestRefresh:)];
            _delegateWillResponseMore = [_delegate respondsToSelector:@selector(gridViewDidRequestMore:)];
            
            if( _delegateWillResponseRefresh ) {
                
                NSDictionary* defs = @{
                    @(VUIGridViewPullRefreshState_Idle): _L(@"Pull to refresh"),
                    @(VUIGridViewPullRefreshState_Dragging): _L(@"Pull to refresh"),
                    @(VUIGridViewPullRefreshState_Recognized): _L(@"Release to start refresh"),
                    @(VUIGridViewPullRefreshState_Refreshing): _L(@"Refreshing")
                };
                _pullRefreshIndicatorTexts = [[NSMutableDictionary alloc] initWithDictionary:defs];
            } else {
                if( _pullRefreshView ) {
                    [(UIView*)_pullRefreshView removeFromSuperview];
                    self.pullRefreshView = nil;
                };
            }
            
            if( _delegateWillResponseMore ) {
                NSDictionary* defs = @{
                    @(VUIGridViewMoreState_Idle): _L(@"More"),
                    @(VUIGridViewMoreState_Refreshing): _L(@"Loading")
                };
                _moreIndicatorTexts = [[NSMutableDictionary alloc] initWithDictionary:defs];
                
                //TODO: create more indicator if necessary
                
                if( nil == _moreView ) {
                
                    
                    
                    id<VUIGVPullRrefrehViewProtocol> more = [_delegate moreViewForGridView:self];
                    NSAssert( [more isKindOfClass:[UIView class]], @"moreViewForGridView must return an instance of UIView" );
                    
                    UIView* moreView = (UIView*)more;
                    moreView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
                    
                    CGRect frame = _scrollView.frame;
                    CGSize preferredSize = [moreView sizeThatFits:frame.size];
                    CGSize contentSize = _scrollView.contentSize;
                    
                    CGRect moreFrame = CGRectMake(floorf((frame.size.width-preferredSize.width)/2), contentSize.height, preferredSize.width, preferredSize.height);
                    moreView.frame = moreFrame;
                    [_scrollView  addSubview:moreView];
                    
                    self.moreView = more;
                    
                    UIEdgeInsets inset = _scrollView.contentInset;
                    inset.bottom = preferredSize.height;
                    _scrollView.contentInset = inset;
                }
                
                _moreView.title = [self textForMoreIndicatorState:VUIGridViewMoreState_Idle];
                
            } else {
                if( _moreView ) {
                    [(UIView*)_moreView removeFromSuperview];
                    self.moreView = nil;
                    
                    UIEdgeInsets inset = _scrollView.contentInset;
                    inset.bottom = 0;
                    _scrollView.contentInset = inset;
                }
            }
        
        } else {
        
            _delegateWillResponseSelect = NO;
            _delegateWillResponseDeselect = NO;
            _delegateWillResponseRefresh = NO;
            _delegateWillResponseMore = NO;
            
            if( _pullRefreshView ) {
                [(UIView*)_pullRefreshView removeFromSuperview];
                self.pullRefreshView = nil;
            };
            if( _moreView ) {
                [(UIView*)_moreView removeFromSuperview];
                self.moreView = nil;
                
                UIEdgeInsets inset = _scrollView.contentInset;
                inset.bottom = 0;
                _scrollView.contentInset = inset;
            }
        
        }
    }
}

- (void)setRefreshIndicatorState:(VUIGridViewPullRefreshIndicatorState)state animated:(BOOL)animated {

    if( state != _pullRefreshIndicatorState ) {
    
        _pullRefreshIndicatorState = state;
        
        UIScrollView* scrollView = _scrollView;
        id<VUIGVPullRrefrehViewProtocol> refresh = _pullRefreshView;
        UIView* refreshView = (UIView*)refresh;
        
        NSString* text = [self textForPullRefreshIndicatorState:_pullRefreshIndicatorState];
        
        CGFloat topInset = 0;
        BOOL activeAni = NO;
        
//        id<VUIGridViewDelegate> delegate = self.delegate;
        
        if( VUIGridViewPullRefreshState_Refreshing == state ||
            VUIGridViewPullRefreshState_Recognized == state
        ) {
            if( nil == refresh ) {
                refresh = [self _loadPullRefreshView];
                refreshView = (UIView*)refresh;
            }
            CGRect frame = scrollView.frame;
            CGSize preferredSize = [refreshView sizeThatFits:frame.size];
            topInset = preferredSize.height;
        }
        if( VUIGridViewPullRefreshState_Refreshing == state ) {
//            VUIGridView* s = self;
//            dispatch_async(dispatch_get_main_queue(), ^() {
//                [delegate gridViewDidRequestRefresh:s];
//            });
            activeAni = YES;
        }

        CGFloat currentTopInset = scrollView.contentInset.top;
        if( topInset != currentTopInset ) {

            UIEdgeInsets inset = scrollView.contentInset;
            inset.top = topInset;

            [refresh setTitle:text];
            
//            if( VUIGridViewPullRefreshState_Idle == state ) {
//                CGFloat y = scrollView.contentOffset.y;
//                if( y != 0 ) {
//                    [scrollView setContentOffset:CGPointMake(0, 0) animated:animated];
//                }
//            }
            
            if( animated ) {
                [UIView animateWithDuration:0.3f animations:^() {
                    [scrollView setContentInset:inset];
                    if( VUIGridViewPullRefreshState_Idle == state || VUIGridViewPullRefreshState_Refreshing == state ) {
                        [scrollView setContentOffset:CGPointMake(0, -inset.top) animated:YES];
                    }                    
                }];
            } else {
                [scrollView setContentInset:inset];
                if( VUIGridViewPullRefreshState_Idle == state || VUIGridViewPullRefreshState_Refreshing == state ) {
                    [scrollView setContentOffset:CGPointMake(0, -inset.top) animated:YES];
                }
            }
        } else {
           [refresh setTitle:text];
        }

        if( activeAni != [refresh activeAnimation] ) {
            [refresh setActiveAnimation:activeAni];
        }
    
    }

}

- (void)setMoreIndicatorState:(VUIGridViewMoreIndicatorState)state animated:(BOOL)animated {

    if( state != _moreIndicatorState ) {
    
        _moreIndicatorState = state;
        
        NSString* text = [self textForMoreIndicatorState:_moreIndicatorState];
        _moreView.title = text;

        BOOL activeAni = NO;
        
        if( VUIGridViewMoreState_Refreshing == state ) {
            activeAni = YES;
        }
        
        UIView* moreView = (UIView*)_moreView;
        moreView.hidden = ![_delegate isThereMoreDataForGridView:self];
        
        _moreView.activeAnimation = activeAni;
    }
    

}


- (NSString*)textForPullRefreshIndicatorState:(VUIGridViewPullRefreshIndicatorState)state {
    
    NSNumber* key = @(state);
    NSString* text = [_pullRefreshIndicatorTexts objectForKey:key];
    
    return text;
    
}

- (NSString*)textForMoreIndicatorState:(VUIGridViewMoreIndicatorState)state {

    NSNumber* key = @(state);
    NSString* text = [_moreIndicatorTexts objectForKey:key];
    
    return text;

}

- (void)setText:(NSString*)text forPullRefreshIndicatorState:(VUIGridViewPullRefreshIndicatorState)state {

    NSNumber* key = @(state);
    [_pullRefreshIndicatorTexts setObject:text forKey:key];
    
}

- (void)setText:(NSString*)text forMoreIndicatorState:(VUIGridViewMoreIndicatorState)state {

    NSNumber* key = @(state);
    [_moreIndicatorTexts setObject:text forKey:key];

}

- (void)reloadData {
	[self _doReloadData:NO];
}

- (void)_doReloadData:(BOOL)sync {

	[UIApplication cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadData) object:nil];
    
    if( _dataSource ) {
        _numberOfCell = [_dataSource numberOfCellOfGridView:self];
	    [self _resetContentSize];
		// clear all cells and check visibility again
        for( VUIGridCellView* cell in _visibleCells ) {
            [cell _setIndex:NSNotFound];
        }
        if( sync ) {
            [self _doCheckVisibility];
        } else {
            [self _setNeedCheckVisibility];
        }
    } else {
        // clear all unnecessary
		[self _removeAllVisibleCells];
        [_recycledCells removeAllObjects];
        _numberOfColumn = 1;
        _numberOfRow = 0;
        _numberOfCell = 0;
        _scrollView.contentSize = _scrollView.bounds.size;
    }

}


#ifdef ENABLE_GRIDVIEW_ANIMATION_CHANGE

- (void)insertCellAtIndex:(NSUInteger)index animated:(BOOL)animated {
	VUILog(@"VUIGridView insert cell at index %d", index);
        
    _numberOfCells = [_dataSource numberOfCellOfGridView:self];
    [self _resetContentSize];
    
	NSRange visibleRange = [self _calculateVisibleRange];
	NSUInteger start = visibleRange.location;
    NSUInteger end = start + visibleRange.length;
    
    if( index >= end ) {
    	// do nothing, since it is not visible at all
    	return;
    }
    
    NSUInteger newCellIndex = index;
    
	if( index < start ) {
    	// the insert position is beyon the visible area
        // make sure that the first visible cell is in the _visibleCells;
        newCellIndex = start;
    }
    
    BOOL found = NO;
    // change the index of all visible cells after the index
    for( VUIGridCellView* c in _visibleCells ) {
        NSUInteger i = c.index;
        if( NSNotFound != i && i >= index ) {
        	i++;
            [c _setIndex:i];
            if( c.hidden ) {
                c.frame = [self _frameForCellAtIndex:i];
            }
        }
        if( i == newCellIndex ) {
        	found = YES;
        }
    }
    
    if( !found ) {
        // create a new cell and insert it
        VUIGridCellView* cell = [self _getMeACellOfIndex:newCellIndex];
        CGRect frame = [self _frameForCellAtIndex:newCellIndex];
        cell.frame = frame;
        if( animated && newCellIndex == index ) {
            cell.hidden = YES;
        }
        
        [_scrollView addSubview:cell];
        [_visibleCells addObject:cell];
    }
    
    if( !_needCheckVisibility && !_scrollView.dragging && !_scrollView.decelerating ) {
        if( animated ) {
            if( _changeStartIndex > newCellIndex )  {
                _changeStartIndex = newCellIndex;
            }
            [self _setNeedAnimChange];
        } else {
            [self _setNeedCheckVisibility];
        }
    }
}

- (void)removeCellAtIndex:(NSUInteger)index animated:(BOOL)animated {
    
    // calculate the old visible range first
    NSRange visibleRange = [self _calculateVisibleRange];
	NSUInteger start = visibleRange.location;
    NSUInteger end = start + visibleRange.length;
    
    if( index >= end ) {
    	// do nothing, since it is not visible at all
    	return;
    }
    
    NSUInteger newCellIndex = index;
    
	if( index < start ) {
    	// the insert position is beyon the visible area
        // make sure that the first visible cell is in the _visibleCells;
        newCellIndex = start;
    }
    
	VUILog(@"VUIGridView remove cell at index %d", index);
    // change the index of all visible cells after the index
    for( VUIGridCellView* c in _visibleCells ) {
    	NSUInteger i = c.index;
        if( NSNotFound != i ) {
        	if( i == index ) {
	        	[c _setIndex:NSNotFound];
            } else if( i > index ) {
            	[c _setIndex:i-1];
            }
        }
    }

	// refresh content size now
     _numberOfCells = [_dataSource numberOfCellOfGridView:self];
    [self _resetContentSize];
    
    if( end > _numberOfCells ) {
    	end = _numberOfCells;
    }
    
    for( NSUInteger i = newCellIndex; i < end; i++ ) {
    	BOOL found = NO;
        for( VUIGridCellView* c in _visibleCells ) {
        	if( i == c.index ) {
            	found = YES;
                break;
            }
        }
        if( !found ) {
            // create a new cell and insert it
            VUIGridCellView* cell = [self _getMeACellOfIndex:i];
            NSUInteger prevIndex = i+1;
            CGRect frame = [self _frameForCellAtIndex:prevIndex];
            cell.frame = frame;            
            [_scrollView addSubview:cell];
            [_visibleCells addObject:cell];
        }
    }

    if( !_needCheckVisibility && !_scrollView.dragging && !_scrollView.decelerating ) {
        if( animated ) {
            if( _changeStartIndex > newCellIndex )  {
                _changeStartIndex = newCellIndex;
            }
            [self _setNeedAnimChange];
        } else {
            [self _setNeedCheckVisibility];
        }
    }
}

- (void)reloadCellAtIndex:(NSUInteger)index animated:(BOOL)animated {

	VUILog(@"VUIGridView reload cell at index %d", index);
    // replace a cell by replacing the existing one
    // mark the exisiting cell as deleted;
    BOOL found = NO;
    for( VUIGridCellView* c in _visibleCells ) {
        NSUInteger i = c.index;
        if( NSNotFound != i && i == index ) {
            [c _setIndex:NSNotFound];
            found = YES;
            break;
        }
    }
    if( found && !_needCheckVisibility ) {
    	if( animated ) {
        	
            // create a new cell and insert it
            VUIGridCellView* cell = [self _getMeACellOfIndex:index];
            CGRect frame = [self _frameForCellAtIndex:index];
            cell.frame = frame;            
            [_scrollView addSubview:cell];
            [_visibleCells addObject:cell];
            [self _animateReloadAtIndex:index];
        } else {
	        [self _setNeedCheckVisibility];
        }
    }

}

#else

- (void)beginUpdate {
    _updating = YES;
}

- (void)endUpdate {
    _updating = NO;
    if( !_scrollView.dragging && !_scrollView.decelerating ) {
        [self _setNeedCheckVisibility];
    }
}


- (void)insertCellAtIndex:(NSUInteger)index animated:(BOOL)animated {
	VUILog(@"VUIGridView insert cell at index %d", index);
    
    _numberOfCell = [_dataSource numberOfCellOfGridView:self];
    [self _resetContentSize];
    
	NSRange visibleRange = [self _calculateVisibleRange];
	NSUInteger start = visibleRange.location;
    NSUInteger end = start + visibleRange.length;
    
    if( index >= end ) {
    	// do nothing, since it is not visible at all
    	return;
    }
    // change the index of all visible cells after the index
    for( VUIGridCellView* c in _visibleCells ) {
        NSUInteger i = c.index;
        if( NSNotFound != i && i >= index ) {
            [c _setIndex: NSNotFound];
        }
    }
    // insert cell of the index
//    VUIGridCellView* cell = [self _getMeACellOfIndex:index];
//    cell.frame = [self _frameForCellAtIndex:index];
//    [_visibleCells addObject:cell];
//    [_scrollView addSubview:cell];    
    
    if( !_updating && !_scrollView.dragging && !_scrollView.decelerating ) {
        [self _setNeedCheckVisibility];
    }
}

- (void)removeCellAtIndex:(NSUInteger)index animated:(BOOL)animated {
    
    // calculate the old visible range first
    NSRange visibleRange = [self _calculateVisibleRange];
	NSUInteger start = visibleRange.location;
    NSUInteger end = start + visibleRange.length;
    
  	// refresh content size now
    _numberOfCell = [_dataSource numberOfCellOfGridView:self];
    [self _resetContentSize];
    
    if( index >= end ) {
    	// do nothing, since it is not visible at all
    	return;
    }
    
	VUILog(@"VUIGridView remove cell at index %d", index);
    // change the index of all visible cells after the index
    for( VUIGridCellView* c in _visibleCells ) {
    	NSUInteger i = c.index;
        if( NSNotFound != i ) {
            if( i >= index ) {
                [c _setIndex:NSNotFound];
            }
        }
    }
  
    if( !_updating && !_scrollView.dragging && !_scrollView.decelerating ) {
        [self _setNeedCheckVisibility];
    }
}

- (void)reloadCellAtIndex:(NSUInteger)index animated:(BOOL)animated {
    
	VUILog(@"VUIGridView reload cell at index %d", index);
    // replace a cell by replacing the existing one
    // mark the exisiting cell as deleted;
    BOOL found = NO;
    for( VUIGridCellView* c in _visibleCells ) {
        NSUInteger i = c.index;
        if( NSNotFound != i && i == index ) {
            [c _setIndex:NSNotFound];
            found = YES;
            break;
        }
    }
    if( !_updating && found ) {
        if( !_scrollView.dragging && !_scrollView.decelerating ) {
            [self _setNeedCheckVisibility];
        }
    }
}

- (void)insertCellsAtIndexes:(NSIndexSet*)indexes animated:(BOOL)animated {

	VUILog(@"VUIGridView insert cell at indexes %@", indexes);
        
    _numberOfCell = [_dataSource numberOfCellOfGridView:self];
    [self _resetContentSize];
    
    NSUInteger first = indexes.firstIndex;
    
	NSRange visibleRange = [self _calculateVisibleRange];
	NSUInteger start = visibleRange.location;
    NSUInteger end = start + visibleRange.length;

    if( first >= end ) {
    	// do nothing, since it is not visible at all
    	return;
    }
    // change the index of all visible cells after the index
    for( VUIGridCellView* c in _visibleCells ) {
        NSUInteger i = c.index;
        if( NSNotFound != i && i >= first ) {
            [c _setIndex: NSNotFound];
        }
    }
    
    if( !_updating && !_scrollView.dragging && !_scrollView.decelerating ) {
        [self _setNeedCheckVisibility];
    }
}

- (void)removeCellsAtIndexex:(NSIndexSet*)indexes animated:(BOOL)animated {

	VUILog(@"VUIGridView remove cells at index %@", indexes);
    
 	// refresh content size now
    _numberOfCell = [_dataSource numberOfCellOfGridView:self];
    [self _resetContentSize];
    
    NSUInteger first = indexes.firstIndex;
    
    // calculate the old visible range first
    NSRange visibleRange = [self _calculateVisibleRange];
	NSUInteger start = visibleRange.location;
    NSUInteger end = start + visibleRange.length;
    
    if( first >= end ) {
    	// do nothing, since it is not visible at all
    	return;
    }
    
    // change the index of all visible cells after the index
    for( VUIGridCellView* c in _visibleCells ) {
    	NSUInteger i = c.index;
        if( NSNotFound != i ) {
            if( i >= first ) {
                [c _setIndex:NSNotFound];
            }
        }
    }
  
    if( !_updating && !_scrollView.dragging && !_scrollView.decelerating ) {
        [self _setNeedCheckVisibility];
    }

}

- (void)reloadCellsAtIndexes:(NSIndexSet*)indexes animated:(BOOL)animated {

    VUILog(@"VUIGridView reload cell at index %@", indexes);
    NSUInteger first = indexes.firstIndex;
    NSUInteger last = indexes.lastIndex;
    
    // replace a cell by replacing the existing one
    // mark the exisiting cell as deleted;
    BOOL found = NO;
    for( VUIGridCellView* c in _visibleCells ) {
        NSUInteger i = c.index;
        if( i >= first && i <= last ) {
            [c _setIndex:NSNotFound];
            found = YES;
        }
    }
    if( !_updating && found ) {
        if( !_scrollView.dragging && !_scrollView.decelerating ) {
            [self _setNeedCheckVisibility];
        }
    }
    
}

#endif


- (id)cellAtIndex:(NSUInteger)index {
	VUIGridCellView* cell = nil;
    
    for( VUIGridCellView* c in _visibleCells ) {
    	if( c.index == index ) {
        	cell = c;
            break;
        }
    }
    
    return cell;
}


@end

@implementation VUIGridView (Private)

- (void)_requestUpdateCellContent:(VUIGridCellView*)cell {
	VUIGridViewUpdateCellContentOperation* op = [VUIGridViewUpdateCellContentOperation new];
    op.cell = cell;
    op.gridView = self;
    [_updateCellContentQueue addOperation:op];
    [op release];
}

- (void)_cancelUpdateCellContent:(VUIGridCellView*)cell {
	VUIGridViewUpdateCellContentOperation* prevOp = nil;
	for( VUIGridViewUpdateCellContentOperation* op in _updateCellContentQueue.operations ) {
    	if( op.cell == cell ) {
        	prevOp = op;
            break;
        }
    }
    if( prevOp ) {
		[prevOp cancel];
    }
}


- (void)_setRefreshIndicatorState:(VUIGridViewPullRefreshIndicatorState)state {
    if( state != _pullRefreshIndicatorState ) {
    
        _pullRefreshIndicatorState = state;
        
        UIScrollView* scrollView = _scrollView;
        id<VUIGridViewDelegate> delegate = _delegate;
        
        id<VUIGVPullRrefrehViewProtocol> refresh = _pullRefreshView;
        
        NSString* text = [self textForPullRefreshIndicatorState:_pullRefreshIndicatorState];
        [refresh setTitle:text];
        
        CGFloat topInset = 0;
        BOOL activeAni = NO;
        
        if( VUIGridViewPullRefreshState_Refreshing == state ) {
            VUIGridView* s = self;
            
            UIView* refreshView = (UIView*)refresh;
            CGRect frame = scrollView.frame;
            CGSize preferredSize = [refreshView sizeThatFits:frame.size];
            topInset = preferredSize.height;

            dispatch_async(dispatch_get_main_queue(), ^() {
                [delegate gridViewDidRequestRefresh:s];
            });
            activeAni = YES;
        }
        
        if( topInset != scrollView.contentInset.top ) {
            UIEdgeInsets inset = scrollView.contentInset;
            inset.top = topInset;
            [scrollView setContentInset:inset];
#if TARGET_OS_IPHONE
            if( VUIGridViewPullRefreshState_Idle == state || VUIGridViewPullRefreshState_Refreshing == state ) {
                [scrollView setContentOffset:CGPointMake(0, -inset.top) animated:YES];
            }
#endif
        }
        if( activeAni != [refresh activeAnimation] ) {
            [refresh setActiveAnimation:activeAni];
        }
    
    }
    
}

- (void)_setMoreIndicatorState:(VUIGridViewMoreIndicatorState)state {

    if( state != _moreIndicatorState ) {
    
        _moreIndicatorState = state;
        
        NSString* text = [self textForMoreIndicatorState:_moreIndicatorState];
        _moreView.title = text;

        BOOL activeAni = NO;
        
        if( VUIGridViewMoreState_Refreshing == state ) {
            activeAni = YES;
            
            dispatch_async(dispatch_get_main_queue(), ^() {
                [_delegate gridViewDidRequestMore:self];
            });
        }
        
        _moreView.activeAnimation = activeAni;
    }

}

@end
