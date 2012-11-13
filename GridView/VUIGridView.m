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

@property(nonatomic,readwrite,assign) UILabel* emtpyHintLabel;

@property(nonatomic,readwrite,assign) UIScrollView* scrollView;

@property(nonatomic,readwrite,assign) NSRange visibleRange;

@property(nonatomic,retain) NSOperationQueue* updateCellContentQueue;

@end

@implementation VUIGridView

@synthesize numberOfCell = _numberOfCell;
@synthesize numberOfColumn = _numberOfColumn;
@synthesize numberOfRow = _numberOfRow;
@synthesize selectedIndex =  _selectedIndex;

- (void)_hideTopShadowLayer {
    _topShadowLayer.opacity = 0;
}

- (void)_prepareTopShadowLayer {
    
    if( nil == _topShadowLayer ) {
        // create shadow
        CAGradientLayer *newShadow = [[CAGradientLayer alloc] init];
        CGRect newShadowFrame =
        CGRectMake(0, 0, self.bounds.size.width, GRIDVIEW_SHADOW_HEIGHT);
        newShadow.frame = newShadowFrame;
        CGColorRef darkColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.5f].CGColor;
        CGColorRef lightColor = [_scrollView.backgroundColor colorWithAlphaComponent:0.0].CGColor;
        newShadow.colors = [NSArray arrayWithObjects:
                            (id)(darkColor),
                            (id)(lightColor),
                            nil];
        newShadow.zPosition = 1;
        _topShadowLayer = newShadow;
        
        [self.layer addSublayer:_topShadowLayer];
    }
}

- (void)setup {
    
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

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
    if( self ) {
 		[self setup];   
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
    if( self ) {
    	[self setup];
    }
    return self;
}

- (void)dealloc {
    [_topShadowLayer release];
    _topShadowLayer = nil;
    
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
        
        [UIApplication cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadData) object:nil];
        [self performSelector:@selector(reloadData) withObject:nil afterDelay:0.1f];
    }
}

- (void)setDelegate:(id<VUIGridViewDelegate>)delegate {
	if( _delegate != delegate ) {
    	_delegate = delegate;
        
        _delegateWillResponseSelect = [_delegate respondsToSelector:@selector(gridView:didSelectCellAtIndexPath:)];
        _delegateWillResponseDeselect = [_delegate respondsToSelector:@selector(gridView:didDeselectCellAtIndexPath:)];
    }
}

- (void)reloadData {
	[UIApplication cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadData) object:nil];
    
    if( _dataSource ) {
        _numberOfCell = [_dataSource numberOfCellOfGridView:self];
	    [self _resetContentSize];
		// clear all cells and check visibility again
        [self _removeAllVisibleCells];
        [self _setNeedCheckVisibility];
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
//        	if( i == index ) {
//	        	[c _setIndex:NSNotFound];
//            } else if( i > index ) {
//            	[c _setIndex:i-1];
//            }
        }
    }
    
	// refresh content size now
    _numberOfCell = [_dataSource numberOfCellOfGridView:self];
    [self _resetContentSize];
  
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

@end
