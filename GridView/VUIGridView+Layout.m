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

    NSUInteger max = ( self.mode ? _numberOfRowInPage : _numberOfColumnInPage );
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
    
//    VUILog(@"_setNeedCheckVisibility");
//    if( _needCheckVisibility ) {
//    	// a request is already sent
//        // just wait
//        VUILog(@"just wait the previous request");
//    	return;
//    }
//    
//    _needCheckVisibility = YES;
//    [self performSelectorOnMainThread:@selector(_checkVisibilityNow) withObject:nil waitUntilDone:NO];
    [self.scrollView setNeedsLayout];
}

- (void)_layoutCellsInVerticalModeFromIndex:(NSUInteger)index {

    UIScrollView* scrollView = self.scrollView;
	CGRect bounds = scrollView.bounds;
    
    CGFloat W = bounds.size.width;
    
    CGFloat cW = _cellSize.width;
    CGFloat cH = _cellSize.height;
    CGFloat cPW = _cellSpacing.width;
    CGFloat cPH = _cellSpacing.height;
    
    NSInteger col = _numberOfColumnInPage;
    
    NSInteger cWPW = cW+cPW;
    NSInteger cHPH = cH+cPH;
    NSInteger leftIndent = floorf((W-((col-1)*cWPW+cW))/2);
    NSInteger topIndent = cPH;
    
	for( VUIGridCellView* c in _visibleCells ) {
    	NSUInteger i = c.index;
        if( NSNotFound != i && i >= index ) {
            NSUInteger cellCol = i % col;
            NSUInteger cellRow = i / col;
            
            NSInteger x = leftIndent+cellCol*cWPW;
            NSInteger y = topIndent+cellRow*cHPH;
            
            CGRect newFrame = CGRectMake(x, y, cW, cH);
            
            CGRect oldFrame = c.frame;
            
            if( IS_DIFFERENT_FRAME(newFrame, oldFrame)) {
                c.frame = newFrame;
            }
        }
    }
}

- (void)_layoutCellsInHorizentalModeFromIndex:(NSUInteger)index {

    UIScrollView* scrollView = self.scrollView;
	CGRect bounds = scrollView.bounds;
    
    CGFloat W = bounds.size.width;
    
    CGFloat cW = _cellSize.width;
    CGFloat cH = _cellSize.height;
    CGFloat cPW = _cellSpacing.width;
    CGFloat cPH = _cellSpacing.height;
    
    NSUInteger col = _numberOfColumnInPage;
    NSUInteger row = _numberOfRowInPage;
    NSUInteger numberOfCellInPage = _numberOfCellInPage;
    
    NSInteger cWPW = cW+cPW;
    NSInteger cHPH = cH+cPH;
        
    NSInteger asideSpacing = (W-((col-1)*cWPW+cW));
    NSInteger topIndent = cPH;
    
	for( VUIGridCellView* c in _visibleCells ) {
    	NSUInteger i = c.index;
        if( i != NSNotFound && i >= index ) {
        	// don't layout the deleted cells
            NSUInteger cellCol = i / row;
            NSUInteger cellRow = i % row;
            
            NSUInteger pageIndex = i/numberOfCellInPage;
            NSInteger leftIndent = asideSpacing*(pageIndex+1)-asideSpacing/2;
            
            NSInteger x = leftIndent+cellCol*cWPW;
            NSInteger y = topIndent+cellRow*cHPH;
            
            CGRect newFrame = CGRectMake(x, y, cW, cH);
            
            CGRect oldFrame = c.frame;
            
            if( IS_DIFFERENT_FRAME(newFrame, oldFrame)) {
                c.frame = newFrame;
            }
        }
    }
}

- (void)_layoutCellsFromIndex:(NSUInteger)index {
    if( self.mode ) {
        [self _layoutCellsInHorizentalModeFromIndex:index];
    } else {
        [self _layoutCellsInVerticalModeFromIndex:index];
    }
}

- (CGRect)_frameForCellInVerticalModeAtIndex:(NSUInteger)index {

    UIScrollView* scrollView = self.scrollView;
	CGRect bounds = scrollView.bounds;
    
    CGFloat W = bounds.size.width;
    
    CGFloat cW = _cellSize.width;
    CGFloat cH = _cellSize.height;
    CGFloat cPW = _cellSpacing.width;
    CGFloat cPH = _cellSpacing.height;
    
    NSInteger col = _numberOfColumnInPage;
    
    NSInteger cWPW = cW+cPW;
    NSInteger cHPH = cH+cPH;
    NSInteger leftIndent = (W-((col-1)*cWPW+cW))/2;
    NSInteger topIndent = cPH;
    
    NSUInteger cellCol = index % col;
    NSUInteger cellRow = index / col;
    
    NSInteger x = leftIndent+cellCol*cWPW;
    NSInteger y = topIndent+cellRow*cHPH;
    
    CGRect frame = CGRectMake(x, y, cW, cH);

	return frame;
    
}

- (CGRect)_frameForCellInHorizentalModeAtIndex:(NSUInteger)index {

    UIScrollView* scrollView = self.scrollView;
	CGRect bounds = scrollView.bounds;
    
    CGFloat W = bounds.size.width;
    
    CGFloat cW = _cellSize.width;
    CGFloat cH = _cellSize.height;
    CGFloat cPW = _cellSpacing.width;
    CGFloat cPH = _cellSpacing.height;
    
    NSUInteger col = _numberOfColumnInPage;
    NSUInteger row = _numberOfRowInPage;
    NSUInteger numberOfCellInPage = _numberOfCellInPage;
    
    NSInteger cWPW = cW+cPW;
    NSInteger cHPH = cH+cPH;
    
    NSUInteger pageIndex = index/numberOfCellInPage;
    
    NSInteger asideSpacing = (W-((col-1)*cWPW+cW));
    
    NSInteger leftIndent = asideSpacing*(pageIndex+1)-asideSpacing/2;
    NSInteger topIndent = cPH;

    // don't layout the deleted cells
    NSUInteger cellCol = index / row;
    NSUInteger cellRow = index % row;
    
    NSInteger x = leftIndent+cellCol*cWPW;
    NSInteger y = topIndent+cellRow*cHPH;
    
    CGRect frame = CGRectMake(x, y, cW, cH);
    
	return frame;
    
}

- (CGRect)_frameForCellAtIndex:(NSUInteger)index {
    if( self.mode ) {
        return [self _frameForCellInHorizentalModeAtIndex:index];
    } else {
        return [self _frameForCellInVerticalModeAtIndex:index];
    }
}

- (void)_resetContentSizeInVerticalMode {

	UIScrollView* scrollView = self.scrollView;
	CGRect bounds = scrollView.bounds;
    
    CGFloat W = bounds.size.width;
    CGFloat H = bounds.size.height;
    
    CGFloat cW = _cellSize.width;
    CGFloat cH = _cellSize.height;
    CGFloat cPW = _cellSpacing.width;
    CGFloat cPH = _cellSpacing.height;
    
    NSUInteger col = 1;
    NSUInteger row = 1;
    
    if( W > cW ) {
    	col = ceilf((W-cW)/(cW+cPW));
    }
    if( H > cH ) {
        row = ceilf(H/(cH+cPH));
    }
    
    NSUInteger numberOfCells = _numberOfCell;
    NSUInteger numberOfRows = numberOfCells/col + ( numberOfCells%col ? 1 : 0 );
    
    CGFloat h = numberOfRows*(cH+cPH)+cPH;
    
    CGSize contentSize = CGSizeMake(W, h);
    
    scrollView.contentSize = contentSize;
    
    _numberOfColumn = col;
    _numberOfColumnInPage = col;
    
    _numberOfRow = numberOfRows;
    _numberOfRowInPage = row;
    
    _numberOfCellInPage = _numberOfColumnInPage*_numberOfRowInPage;
}

- (void)_resetContentSizeInHorizentalMode {
    
    UIScrollView* scrollView = self.scrollView;
	CGRect bounds = scrollView.bounds;
    
    CGFloat W = bounds.size.width;
    CGFloat H = bounds.size.height;
    
    CGFloat cW = _cellSize.width;
    CGFloat cH = _cellSize.height;
    CGFloat cPW = _cellSpacing.width;
    CGFloat cPH = _cellSpacing.height;
    
    NSUInteger col = 1;
    NSUInteger row = 1;
    
    if( W > cW ) {
    	col = ceilf((W-cW)/(cW+cPW));
    }
    if( H > cH ) {
        row = ceilf(H/(cH+cPH));
    }
    
    NSUInteger numberOfCells = _numberOfCell;
    NSUInteger numberOfCellInPage = col*row;
    NSUInteger numberOfPage = numberOfCells/numberOfCellInPage + ( numberOfCells%numberOfCellInPage ? 1 : 0 );
    
    CGFloat contentWidth = numberOfPage*W;
    
    CGSize contentSize = CGSizeMake(contentWidth, H);
    
    scrollView.contentSize = contentSize;
    
    _numberOfColumn = col*numberOfPage;
    _numberOfColumnInPage = col;
    
    _numberOfRow = row;
    _numberOfRowInPage = row;
    
    _numberOfCellInPage = _numberOfColumnInPage*_numberOfRowInPage;
}

- (void)_resetContentSize {

    id dataSource = self.dataSource;
    _cellSize = [dataSource cellSizeOfGridView:self];
    _cellSpacing = [dataSource cellSpacingOfGridView:self];

    if( self.mode ) {
        [self _resetContentSizeInHorizentalMode];
    } else {
        [self _resetContentSizeInVerticalMode];
    }
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

- (NSRange)_calculateVisibleRangeInVerticalMode {
    
	UIScrollView* scrollView = self.scrollView;
	CGRect bounds = scrollView.bounds;
    
    CGFloat y = bounds.origin.y;
    if( y < 0 ) {
    	// the user has drag the content too low
        // just show from the first row
    	y = 0;
    }
    
    CGFloat H = bounds.size.height;
    
    CGFloat cH = _cellSize.height;
    CGFloat cPH = _cellSpacing.height;
    
    NSInteger col = _numberOfColumnInPage;
    
	CGFloat rowHeight = cH + cPH;
    
    NSInteger row = floorf(y/rowHeight);
    
    NSInteger start = col*row;
    
	NSInteger displayRow = _numberOfRowInPage; // ceilf(H/rowHeight);
   	if( (row+displayRow)*rowHeight < y+H ) {
    	displayRow++;
    }
    
    NSUInteger count = col*displayRow;
    
    NSUInteger end = start+count;
    
    NSUInteger maxCount = _numberOfCell;
    end = MIN(end, maxCount);
    
    NSRange range = NSMakeRange(start, end-start);
    
    return range;

}

- (NSRange)_calculateVisibleRangeInHorizentalMode {

    UIScrollView* scrollView = self.scrollView;
	CGRect bounds = scrollView.bounds;
    
    CGFloat x = bounds.origin.x;
    if( x < 0 ) {
    	// the user has drag the content too low
        // just show from the first row
    	x = 0;
    }
    
    CGFloat W = bounds.size.width;
    
    NSInteger cW = _cellSize.width;
    NSInteger cPW = _cellSpacing.width;
    NSInteger cWPW = cW+cPW;
    
    NSUInteger col = _numberOfColumnInPage;
    NSUInteger row = _numberOfRowInPage;
    NSUInteger numberOfCellInPage = _numberOfCellInPage;
    NSUInteger numberOfCell = _numberOfCell;
    
    NSInteger D = (W-((col-1)*cWPW+cW));
    NSInteger D_2 = D/2;

    NSUInteger startPage = floorf(x/W);
    NSInteger a = x-W*startPage;
    
    NSInteger cellStartX = a - D_2;
    NSInteger startColOffset = cellStartX/cWPW;
    NSInteger start = numberOfCellInPage*startPage+startColOffset*row;
    NSInteger end = start+numberOfCellInPage;

    if( end <= _numberOfCell ) {
        NSInteger nextPageHeadW = a - D_2;
        if( nextPageHeadW > 0 ) {
            // the end postion is in the next page
            NSInteger numberOfColInPage2 = nextPageHeadW/cWPW+(nextPageHeadW%cWPW?1:0);
            end += numberOfColInPage2*row;
        }
    }
    
    if( end > numberOfCell ) {
        end = numberOfCell;
    }
    
    NSRange range = NSMakeRange(start, end-start);
    return range;
    
}

- (NSRange)_calculateVisibleRange {

    if( self.mode ) {
        return [self _calculateVisibleRangeInHorizentalMode];
    } else {
        return [self _calculateVisibleRangeInVerticalMode];
    }
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
    
    [self _layoutCellsFromIndex:0];
}

- (void)layoutSubviews {
	if( _numberOfCell ) {
		[self _resetContentSize];
    }
	[super layoutSubviews];
}

@end
