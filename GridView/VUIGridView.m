//
//  VUIGridView.m
//  Youplay
//
//  Created by Slavik Shen on 12/13/11.
//  Copyright (c) 2011 apollobrowser.com. All rights reserved.
//

#import "VUIGridView.h"
#import "VUIGridView+Layout.h"
#import "VUIGridView+ScrollViewDelegate.h"
#import "VUIGridView+Private.h"
#import "VUIGridView+Ani.h"

#import "VUIGridCellView+Private.h"
#import "VUIGridViewUpdateCellContentOperation.h"

#ifdef VUI_DEBUG_VUIGRIDVIEW
#    define VUILog(...) NSLog(__VA_ARGS__)
#else
#    define VUILog(...) /* */
#endif

#define MAX_GRID_VIEW_POOL_SIZE 32

@interface VUIGridView()

@property(nonatomic,readwrite,assign) CGSize cellSize;
@property(nonatomic,readwrite,assign) CGSize cellSpacing;

@property(nonatomic,readwrite,assign) UILabel* emtpyHintLabel;

@property(nonatomic,readwrite,assign) UIScrollView* scrollView;

@property(nonatomic,readwrite,assign) NSRange visibleRange;

@property(nonatomic,retain) NSOperationQueue* updateCellContentQueue;

@end

@implementation VUIGridView

@synthesize numberOfCells = _numberOfCells;
@synthesize numberOfColumns = _numberOfColumns;
@synthesize numberOfRows = _numberOfRows;

- (void)setup {


	_visibleCells = [[NSMutableSet alloc] initWithCapacity:MAX_GRID_VIEW_POOL_SIZE];
	_recycledCells = [[NSMutableSet alloc] initWithCapacity:MAX_GRID_VIEW_POOL_SIZE];

    CGRect scrollViewFrame = self.bounds;
    UIScrollView* scrollView = [[UIScrollView alloc] initWithFrame:scrollViewFrame];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrollView.delegate = self;
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
 	self.cellSize = VUIGRIDVIEW_DEFAULT_CELL_SIZE;
   	self.cellSpacing = VUIGRIDVIEW_DEFAULT_CELL_SPACING;

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
    if( _updateCellContentQueue ) {
        [_updateCellContentQueue cancelAllOperations];
        self.updateCellContentQueue = nil;
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
        
        _delegateWillResponseClick = [_delegate respondsToSelector:@selector(gridView:didSelectCellAtIndexPath:)];
    }
}

-(void)setCellSize:(CGSize)cellSize andSpacing:(CGSize)cellSpacing animate:(BOOL)animated {

	BOOL changed = NO;
    
	if( IS_SIZE_CHANGED(_cellSize, cellSize) ) {
		_cellSize = cellSize;
		changed = YES;
    }
    if( IS_SIZE_CHANGED(_cellSpacing, cellSpacing) ) {
		_cellSpacing = cellSpacing;
        changed = YES;
    }

    if( changed && _dataSource && _numberOfCells ) {
	    [self _resetContentSize];
        [self _setNeedCheckVisibility];
    }
}

- (void)beginUpdates {
	VUILog(@"VUIGridView begins updates");
	_updating = YES;
}

- (void)endUpdates {
	VUILog(@"VUIGridView ends updates");    
	_updating = NO;
    if( _dataSource ) {
		[self _setNeedCheckVisibility];
    } else {
    	 // clear all unnecessary
		[self _removeAllVisibleCells];
        [_recycledCells removeAllObjects];
        _numberOfColumns = 1;
        _numberOfRows = 0;
        _numberOfCells = 0;
        _scrollView.contentSize = _scrollView.bounds.size;
    }
}

- (void)reloadData {
	[UIApplication cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadData) object:nil];
    
    if( _dataSource ) {
        _numberOfCells = [_dataSource numberOfCellOfGridView:self];
	    [self _resetContentSize];
		// clear all cells and check visibility again
        [self _removeAllVisibleCells];
        [self _setNeedCheckVisibility];
    } else {
        // clear all unnecessary
		[self _removeAllVisibleCells];
        [_recycledCells removeAllObjects];
        _numberOfColumns = 1;
        _numberOfRows = 0;
        _numberOfCells = 0;
        _scrollView.contentSize = _scrollView.bounds.size;
    }
}

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
        
        [_scrollView addSubview:cell];
        [_visibleCells addObject:cell];
    }
    
    if( animated ) {
    	[self _animateChangeAfterIndex:newCellIndex];
    } else {
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

    if( animated ) {
    	[self _animateChangeAfterIndex:newCellIndex];
    } else {
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
    if( found ) {
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
