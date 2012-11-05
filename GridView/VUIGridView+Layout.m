//
//  VUIGridView+Layout.m
//  Youplay
//
//  Created by Slavik Shen on 12/14/11.
//  Copyright (c) 2011 apollobrowser.com. All rights reserved.
//

#import "VUIGridView+Layout.h"
#import "VUIGridView+Private.h"
#import "VUIGridCellView+Private.h"

#ifdef VUI_DEBUG_VUIGRIDVIEW
#    define VUILog(...) NSLog(__VA_ARGS__)
#else
#    define VUILog(...) /* */
#endif

@implementation VUIGridView (Layout)

- (void)_popRecycledCellsIfNecessary {

	NSUInteger max = _numberOfColumns > 1 ? _numberOfColumns : 2;
    while( _recycledCells.count > max ) {
		// pop any object
        [_recycledCells removeObject:[_recycledCells anyObject]];
    }
    
}

- (void)_clickCell:(VUIGridCellView*)cell {
	if( _delegateWillResponseClick ) {
        NSUInteger index = cell.index;
        if( NSNotFound != index ) {
            VUILog(@"click cell at index %d", index);
            [self.delegate gridView:self didSelectCellAtIndexPath:index];
        }
    }
}

- (void)_cleanUpCellForRecycle:(VUIGridCellView*)c {
	[c removeTarget:self action:@selector(_clickCell:) forControlEvents:UIControlEventTouchUpInside];
    c.contentState  = VUIGridCellContentState_Dirty;
    c.hidden = NO;
    [c queuedIntoPool];
    [c _setIsRecycled:YES];
    if( _dataSourceWillUpgradeContent ) {
    	[self _cancelUpdateCellContent:c];
    }
}

- (void)_prepareCellForUse:(VUIGridCellView*)c {
	[c addTarget:self action:@selector(_clickCell:) forControlEvents:UIControlEventTouchUpInside];
}

- (VUIGridCellView*)_getMeACellOfIndex:(NSUInteger)index {
	id dataSource = self.dataSource;
	VUIGridCellView* cell = [dataSource gridView:self cellAtIndex:index];
    // make sure that the index is right
    [self _prepareCellForUse:cell];
    [cell _setIndex:index];
    
    if( _dataSourceWillUpgradeContent && VUIGridCellContentState_Draft == cell.contentState ) {
		[self _requestUpdateCellContent:cell];
    }
    
    return cell;
}

- (void)_setNeedCheckVisibility {
    
    VUILog(@"_setNeedCheckVisibility");
    if( _needCheckVisibility ) {
    	// a request is already sent
        // just wait
        VUILog(@"just wait the previous request");
    	return;
    }
    
    _needCheckVisibility = YES;
    [self performSelectorOnMainThread:@selector(_checkVisibilityNow) withObject:nil waitUntilDone:NO];
//    [self.scrollView setNeedsLayout];
}

- (void)_layoutCells {

    UIScrollView* scrollView = self.scrollView;
	CGRect bounds = scrollView.bounds;
    
    CGFloat W = bounds.size.width;
    
    CGSize cellSize = self.cellSize;
    CGSize spacing = self.cellSpacing;
    
    CGFloat cW = cellSize.width;
    CGFloat cH = cellSize.height;
    CGFloat cPW = spacing.width;
    CGFloat cPH = spacing.height;
    
    NSInteger col = _numberOfColumns;
    
    CGFloat cWPW = cW+cPW;
    CGFloat cHPH = cH+cPH;
    CGFloat leftIndent = (W-((col-1)*cWPW+cW))/2;
    CGFloat topIndent = cPH;
    
	for( VUIGridCellView* c in _visibleCells ) {
        
    	NSUInteger i = c.index;
        
        if( i != NSNotFound ) {
        	// don't layout the deleted cells
            NSUInteger cellCol = i % col;
            NSUInteger cellRow = i / col;
            
            CGFloat x = leftIndent+cellCol*cWPW;
            CGFloat y = topIndent+cellRow*cHPH;
            
            CGRect newFrame = CGRectMake(x, y, cW, cH);
            
            CGRect oldFrame = c.frame;
            
            if( IS_DIFFERENT_FRAME(newFrame, oldFrame)) {
                c.frame = newFrame;
            }
        }
    }
    
}

- (void)_layoutCellsFromIndex:(NSUInteger)index {

    UIScrollView* scrollView = self.scrollView;
	CGRect bounds = scrollView.bounds;
    
    CGFloat W = bounds.size.width;
    
    CGSize cellSize = self.cellSize;
    CGSize spacing = self.cellSpacing;
    
    CGFloat cW = cellSize.width;
    CGFloat cH = cellSize.height;
    CGFloat cPW = spacing.width;
    CGFloat cPH = spacing.height;
    
    NSInteger col = _numberOfColumns;
    
    CGFloat cWPW = cW+cPW;
    CGFloat cHPH = cH+cPH;
    CGFloat leftIndent = (W-((col-1)*cWPW+cW))/2;
    CGFloat topIndent = cPH;
    
	for( VUIGridCellView* c in _visibleCells ) {
    	NSUInteger i = c.index;
        if( i >= index ) {
            NSUInteger cellCol = i % col;
            NSUInteger cellRow = i / col;
            
            CGFloat x = leftIndent+cellCol*cWPW;
            CGFloat y = topIndent+cellRow*cHPH;
            
            CGRect newFrame = CGRectMake(x, y, cW, cH);
            
            CGRect oldFrame = c.frame;
            
            if( IS_DIFFERENT_FRAME(newFrame, oldFrame)) {
                c.frame = newFrame;
            }
        }
    }
}

- (CGRect)_frameForCellAtIndex:(NSUInteger)index {

    UIScrollView* scrollView = self.scrollView;
	CGRect bounds = scrollView.bounds;
    
    CGFloat W = bounds.size.width;
    
    CGSize cellSize = self.cellSize;
    CGSize spacing = self.cellSpacing;
    
    CGFloat cW = cellSize.width;
    CGFloat cH = cellSize.height;
    CGFloat cPW = spacing.width;
    CGFloat cPH = spacing.height;
    
    NSInteger col = _numberOfColumns;
    
    CGFloat cWPW = cW+cPW;
    CGFloat cHPH = cH+cPH;
    CGFloat leftIndent = (W-((col-1)*cWPW+cW))/2;
    CGFloat topIndent = cPH;
    
    NSUInteger cellCol = index % col;
    NSUInteger cellRow = index / col;
    
    CGFloat x = leftIndent+cellCol*cWPW;
    CGFloat y = topIndent+cellRow*cHPH;
    
    CGRect frame = CGRectMake(x, y, cW, cH);

	return frame;
    
}

- (void)_resetContentSize {

	UIScrollView* scrollView = self.scrollView;
	CGRect bounds = scrollView.bounds;
    
    CGFloat W = bounds.size.width;
    
    CGSize cellSize = self.cellSize;
    CGSize spacing = self.cellSpacing;
    
    CGFloat cW = cellSize.width;
    CGFloat cH = cellSize.height;
    CGFloat cPW = spacing.width;
    CGFloat cPH = spacing.height;
    
    NSInteger col = 1;
    
    if( W > cW ) {
    	col = ceilf((W-cW)/(cW+cPW));
    }
    
    NSUInteger numberOfCells = self.numberOfCells;
    NSUInteger numberOfRows = numberOfCells/col + ( numberOfCells%col ? 1 : 0 );
    
    CGFloat h = numberOfRows*(cH+cPH)+cPH;
    
    CGSize contentSize = CGSizeMake(W, h);
    
    scrollView.contentSize = contentSize;
    
    _numberOfColumns = col;
    _numberOfRows = numberOfRows;
    
}


- (void)_removeAllVisibleCells {

    if( 0 == _visibleCells.count ) {
    	return;
    }
    
	// remove all cells in visible cells
	NSSet* set = [[NSSet alloc] initWithSet:_visibleCells];
    [_visibleCells removeAllObjects];
    
    for( VUIGridCellView* c in set ) {
    	[self _cleanUpCellForRecycle:c];
        [c removeFromSuperview];
    }

    [_recycledCells unionSet:set];
    [set release];
}

- (NSRange)_calculateVisibleRange {

	UIScrollView* scrollView = self.scrollView;
	CGRect bounds = scrollView.bounds;

    CGFloat y = bounds.origin.y;
    if( y < 0 ) {
    	// the user has drag the content too low
        // just show from the first row
    	y = 0;
    }
    
    CGFloat H = bounds.size.height;
    
    CGSize cellSize = self.cellSize;
    CGSize spacing = self.cellSpacing;
    
    CGFloat cH = cellSize.height;
    CGFloat cPH = spacing.height;
    
    NSInteger col = _numberOfColumns;
    
	CGFloat rowHeight = cH + cPH;
    
    NSInteger row = floorf(y/rowHeight);
    
    NSInteger start = col*row;

	NSInteger displayRow = ceilf(H/rowHeight);
   	if( (row+displayRow)*rowHeight < y+H ) {
    	displayRow++;
    }
    
    NSUInteger count = col*displayRow;
    
    NSUInteger end = start+count;
    
    NSUInteger maxCount = self.numberOfCells;
    end = MIN(end, maxCount);
    
    NSRange range = NSMakeRange(start, end-start);
    
    return range;
}

- (void)_doCheckVisibility {

	VUILog(@"_doCheckVisibility");
    
	// calculate the visible range
    NSRange visibleRange = [self _calculateVisibleRange];
    
    NSUInteger start = visibleRange.location;
    NSUInteger end = start + visibleRange.length;
    
    VUILog(@"Visible range: %@", NSStringFromRange(visibleRange));

	// remove all cells marked as deleted
    // remove all cells out of the range
    // recycle them
    
    NSMutableSet* removedCells = nil;
    NSMutableSet* insertedCells = nil;
    
    for( VUIGridCellView* c in _visibleCells ) {
    	NSUInteger index = c.index;
    	if( NSNotFound == index ||
        	index < start ||
           	index >= end
          ) {
          	#ifdef VUI_DEBUG_VUIGRIDVIEW
            if( NSNotFound == index ) {
          		NSLog(@"Remove deleted cell");
            } else {
            	NSLog(@"Remove cell of index %d", index );
            }
            #endif
	    	// the cell will be removed
            if( nil == removedCells ) {
            	removedCells = [[NSMutableSet alloc] initWithCapacity:32];
            }
            [removedCells addObject:c];
            [self _cleanUpCellForRecycle:c];
            [c removeFromSuperview];
        } else if( c.hidden ) {
            // reset the cell animation state
            c.hidden = NO;
        }
    }
    
    if( removedCells ) {
	    [_visibleCells minusSet:removedCells];
    	[_recycledCells unionSet:removedCells];
    }

	UIScrollView* scrollView = self.scrollView;
	// insert the missing cells
    for( NSUInteger i = start; i < end; i++ ) {
    	// check if the index exists in the visible cells
		VUIGridCellView* cell = nil;
        for( VUIGridCellView* c in _visibleCells ) {
        	if( c.index == i ) {
            	cell = c;
            	break;
            }
        }
        if( nil == cell ) {
        	VUILog(@"add cell of index %d", i);
        	// create cell and insert it
            cell = [self _getMeACellOfIndex:i];
            if( nil == insertedCells ) {
            	insertedCells =  [[NSMutableSet alloc] initWithCapacity:32];
            }
            [insertedCells addObject:cell];
            [scrollView addSubview:cell];
        }
    }
    
    if( insertedCells ) {
    	[_visibleCells unionSet:insertedCells];
    }
    
    [self _popRecycledCellsIfNecessary];
        
    [removedCells release];
    [insertedCells release];
    
    [self _layoutCells];

}

- (void)_checkVisibilityNow {

	if( !_needCheckVisibility ) {
    	// everything is done
    	return;
    }
	_needCheckVisibility = NO;
    
#ifdef ENABLE_GRIDVIEW_ANIMATION_CHANGE
    _needAnimateChange = NO;
#endif
    _changeStartIndex = NSNotFound;
    
   	[self _doCheckVisibility];
}

- (void)layoutSubviews {

	[super layoutSubviews];

	if( _numberOfCells ) {
		[self _resetContentSize];
	    [self _layoutCells];
    }
}

@end
