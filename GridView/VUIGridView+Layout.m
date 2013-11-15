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
    if (cell.index == self.selectedIndex || cell.index == _selectedIndex)
        return;
    SEL csass = sel_registerName("cellSwitchAnimationStopped");
    if ([self.delegate respondsToSelector:csass])
        if (!self.delegate.cellSwitchAnimationStopped)
            return;
    NSUInteger index = cell.index;
    if( _delegateWillResponseDeselect && NSNotFound != _selectedIndex ) {
        [self.delegate gridView:self didDeselectCellAtIndexPath:_selectedIndex];
    }
    if (!IS_PHONE) {
        SEL iacs = sel_registerName("isActionCell:");
        if ( [self.delegate respondsToSelector:iacs])
            if ([self.delegate isActionCell:index]) {
                [self.delegate gridView:self didSelectCellAtIndexPath:index];
                return;
            }
    }

    self.selectedIndex = index;
    VUIGridCellView* prevCell = [self cellAtIndex:_selectedIndex];
    [prevCell setSelected:NO];
    _selectedIndex = index;
    [cell setSelected:YES];
    
	if( _delegateWillResponseSelect ) {
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
    [cell setSelected:(index == _selectedIndex)];

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

    UIEdgeInsets insets = self.contentInsets;

    UIScrollView* scrollView = self.scrollView;
	CGRect bounds = scrollView.bounds;
    
    CGFloat W = bounds.size.width -(insets.left+insets.right);
    
    CGFloat cW = _cellSize.width;
    CGFloat cH = _cellSize.height;
    CGFloat cPW = _cellSpacing.width;
    CGFloat cPH = _cellSpacing.height;
    
    NSInteger col = _numberOfColumnInPage;
    
    NSInteger cWPW = cW+cPW;
    NSInteger cHPH = cH+cPH;
    NSInteger leftIndent = floorf((W-((col-1)*cWPW+cW))/2) +insets.left;
    NSInteger topIndent = insets.top;
    
    NSSet* visibleCells = [[NSSet alloc] initWithSet:_visibleCells copyItems:NO];
	for( VUIGridCellView* c in visibleCells ) {
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
    [visibleCells release];    
    
    CGFloat y = bounds.origin.y;
    if( y > _cellSpacing.height ) {
        CGFloat alpha = ABS(y/GRIDVIEW_SHADOW_HEIGHT*3);
        if( alpha > 1 ) { alpha = 1; }
        _topShadowLayer.opacity = alpha;
    } else {
        _topShadowLayer.opacity = 0;
    }
}

- (void)_layoutCellsInHorizontalModeFromIndex:(NSUInteger)index {

    UIEdgeInsets insets = self.contentInsets;

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
    NSInteger topIndent = cPH+insets.top;
    
    NSSet* visibleCells = [[NSSet alloc] initWithSet:_visibleCells copyItems:NO];
	for( VUIGridCellView* c in visibleCells ) {
    	NSUInteger i = c.index;
        if( i != NSNotFound && i >= index ) {
        	// don't layout the deleted cells
            NSUInteger cellCol = i / row;
            NSUInteger cellRow = i % row;
            
            NSUInteger pageIndex = i/numberOfCellInPage;
            
            NSInteger leftIndent = W*pageIndex+asideSpacing/2 +insets.left;
            
            NSInteger x = leftIndent+(cellCol-pageIndex*_numberOfColumnInPage)*cWPW;
            NSInteger y = topIndent+cellRow*cHPH;
            
            CGRect newFrame = CGRectMake(x, y, cW, cH);
            
            CGRect oldFrame = c.frame;
            
            if( IS_DIFFERENT_FRAME(newFrame, oldFrame)) {
                c.frame = newFrame;
            }
        }
    }
    [visibleCells release];
}

- (void)_layoutCellsFromIndex:(NSUInteger)index {
    if( self.mode ) {
        [self _layoutCellsInHorizontalModeFromIndex:index];
    } else {
        [self _layoutCellsInVerticalModeFromIndex:index];
    }
}

- (CGRect)_frameForCellInVerticalModeAtIndex:(NSUInteger)index {

    UIEdgeInsets insets = self.contentInsets;
    
    UIScrollView* scrollView = self.scrollView;
	CGRect bounds = scrollView.bounds;
    
    CGFloat W = bounds.size.width -(insets.left+insets.right);
    
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
    

    x += insets.left;
    y += insets.top;
    
    CGRect frame = CGRectMake(x, y, cW, cH);

	return frame;
    
}

- (CGRect)_frameForCellInHorizontalModeAtIndex:(NSUInteger)index {

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
    
    NSInteger leftIndent = W*pageIndex+asideSpacing/2;
    NSInteger topIndent = 0;
    // don't layout the deleted cells
    NSUInteger cellCol = index / row;
    NSUInteger cellRow = index % row;
    
    NSInteger x = leftIndent+(cellCol-pageIndex*_numberOfColumnInPage)*cWPW;
    NSInteger y = topIndent+cellRow*cHPH;
    
    UIEdgeInsets insets = self.contentInsets;
    x += insets.left;
    y += insets.top;
    
    CGRect frame = CGRectMake(x, y, cW, cH);
    
	return frame;
    
}

- (CGRect)_frameForCellAtIndex:(NSUInteger)index {
    if( self.mode ) {
        return [self _frameForCellInHorizontalModeAtIndex:index];
    } else {
        return [self _frameForCellInVerticalModeAtIndex:index];
    }
}

- (void)_resetContentSizeInVerticalMode {

	UIScrollView* scrollView = self.scrollView;
	CGRect bounds = scrollView.bounds;
    
    UIEdgeInsets insets = self.contentInsets;
    
    CGFloat W = bounds.size.width - (insets.left + insets.right);
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
    
//    CGFloat h = numberOfRows*(cH+cPH)+cPH;
    CGFloat h = numberOfRows*(cH+cPH)+(insets.top+insets.bottom);
    
    CGSize contentSize = CGSizeMake(W, h);
    
    scrollView.contentSize = contentSize;
    
    _numberOfColumn = col;
    _numberOfColumnInPage = col;
    
    _numberOfRow = numberOfRows;
    _numberOfRowInPage = row;
    
    _numberOfCellInPage = _numberOfColumnInPage*_numberOfRowInPage;
}

- (void)_resetContentSizeInHorizontalMode {
    
    UIScrollView* scrollView = self.scrollView;
	CGRect bounds = scrollView.bounds;
    
    UIEdgeInsets insets = self.contentInsets;
    
    CGFloat W = bounds.size.width;
    CGFloat H = bounds.size.height - (insets.top + insets.bottom);
    
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
    
    CGFloat contentWidth = numberOfPage*W+(insets.left+insets.right);
    
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
        [self _resetContentSizeInHorizontalMode];
    } else {
        [self _resetContentSizeInVerticalMode];
    }
    
    id<VUIGVPullRrefrehViewProtocol> more = self.moreView;
    if( more ) {
    
        UIView* moreView = (UIView*)more;
        
        UIScrollView* scrollView = self.scrollView;
        
        CGSize contentSize = scrollView.contentSize;
        CGRect frame = moreView.frame;
        frame.origin.y = contentSize.height;
        frame.origin.x = floorf((contentSize.width-frame.size.width)/2);
        
        moreView.frame = frame;
    }
    
    [self _updateBackgoundViewFrame];
}

- (void)_updateBackgoundViewFrame {
    
    UIView* bgView = self.backgroundView;
    if( bgView ) {

        UIScrollView* scrollView = self.scrollView;
        CGSize contentSize = scrollView.contentSize;
        
        CGFloat cw = contentSize.width;
        CGFloat ch = contentSize.height;
        CGSize bsize = scrollView.bounds.size;
        CGFloat bw = bsize.width;
        CGFloat bh = bsize.height;
        
        CGFloat bgW = MAX(cw,bw);
        CGFloat bgH = MAX(ch,bh);
                    
        CGRect bgFrame = CGRectMake(0,0, bgW, bgH);
        
        self.backgroundView.frame = bgFrame;
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

- (NSRange)_calculateVisibleRangeInHorizontalMode {

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
        return [self _calculateVisibleRangeInHorizontalMode];
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
    
    NSSet* visibleCells = [[NSSet alloc] initWithSet:_visibleCells copyItems:NO];
    for( VUIGridCellView* c in visibleCells ) {
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
        
        [visibleCells release];
        visibleCells = [[NSSet alloc] initWithSet:_visibleCells copyItems:NO];
        
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
    
    [visibleCells release];
    
    if( insertedCells ) {
    	[_visibleCells unionSet:insertedCells];
    }
    
    [self _popRecycledCellsIfNecessary];
        
    [removedCells release];
    [insertedCells release];
    
    UIView* emptyView = self.emptyView;
    
    if( _visibleCells.count ) {
        if( emptyView.superview ) {
            [emptyView removeFromSuperview];
        }
        [self _layoutCellsFromIndex:0];
    } else {
        if( nil == emptyView.superview ) {
            // show emptyView
            emptyView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
            emptyView.frame = self.bounds;
            [self addSubview:emptyView];
        }
    }
}

- (void)layoutSubviews {
	if( _numberOfCell ) {
		[self _resetContentSize];
    }
	[super layoutSubviews];
}

- (void)layoutSublayersOfLayer:(CALayer *)layer {
    [super layoutSublayersOfLayer:layer];
    if( layer == _topShadowLayer.superlayer ) {
        CGRect frame = CGRectMake(0, 0, layer.bounds.size.width, GRIDVIEW_SHADOW_HEIGHT);
        CGRect oldFrame = _topShadowLayer.frame;
        if( IS_DIFFERENT_FRAME(frame, oldFrame) ) {
            _topShadowLayer.frame = frame;
        }
    }
}

- (id<VUIGVPullRrefrehViewProtocol>)_loadPullRefreshView {
    id delegate = self.delegate;
    id<VUIGVPullRrefrehViewProtocol> refresh = [delegate pullRefreshViewForGridView:self];
    NSAssert([refresh isKindOfClass:[UIView class]],@"pullRefreshViewForGridView must return an instance of UIView");

    self.pullRefreshView = refresh;
    
    NSString* text = [self textForPullRefreshIndicatorState:self.pullRefreshIndicatorState];
    [refresh setTitle:text];
    
    UIView* refreshView = (UIView*)refresh;
    UIScrollView* scrollView = self.scrollView;
    
    CGRect bounds = scrollView.bounds;

    CGSize preferredSize = [refreshView sizeThatFits:bounds.size];
    CGFloat pW = preferredSize.width;
    CGFloat pH = preferredSize.height;
        
    CGRect frame = CGRectMake(floorf((bounds.size.width-pW)/2), -pH, pW, pH);
    
    UIView* bgView = self.backgroundView;
    if( bgView ) {
        [scrollView insertSubview:refreshView aboveSubview:bgView];
    } else {
        [scrollView insertSubview:refreshView atIndex:0];
    }
    
    refreshView.frame = frame;
    
    return refresh;
}

- (void)_checkPullRefreshView {

    id<VUIGVPullRrefrehViewProtocol> refresh = self.pullRefreshView;
    UIView* refreshView = (UIView*)refresh;

    UIScrollView* scrollView = self.scrollView;
    CGRect bounds = scrollView.bounds;
    CGFloat y = bounds.origin.y;
    
    if( y < 0 && nil == refresh ) {
        refresh = [self _loadPullRefreshView];
        refreshView = (UIView*)refresh;
    }
        
    CGRect frame = refreshView.frame;
    
    CGSize preferredSize = [refreshView sizeThatFits:bounds.size];
    CGFloat pW = preferredSize.width;
    CGFloat pH = preferredSize.height;
    
    VUIGridViewPullRefreshIndicatorState state = self.pullRefreshIndicatorState;
    
    CGRect newFrame = CGRectMake(floorf((bounds.size.width-pW)/2), -pH, pW, pH);
    
    if( y < -pH ) {
        
        newFrame.origin.y = y;
        newFrame.size.height = -y;
        
        refreshView.frame = frame;
        CGFloat dragDisance = -(y+pH);

        if( scrollView.dragging ) { 
            // user is dragging
            if( dragDisance > MAX_PULL_REFRESH_TAIL_LENGTH_FOR_RECOGNIZING && state < VUIGridViewPullRefreshState_Recognized ) {
                [self _setRefreshIndicatorState:VUIGridViewPullRefreshState_Recognized];
            } else if( state < VUIGridViewPullRefreshState_Dragging ) {
                [self _setRefreshIndicatorState:VUIGridViewPullRefreshState_Dragging];
            }
        }
        
    } else {
    
        if( VUIGridViewPullRefreshState_Recognized == state ) {
            [self _setRefreshIndicatorState:VUIGridViewPullRefreshState_Refreshing];
        }
        
    }

    if( IS_DIFFERENT_FRAME( frame, newFrame) ) {
        refreshView.frame = newFrame;
    }
    
}

- (void)_checkMoreView {

    id<VUIGVPullRrefrehViewProtocol> more = self.moreView;
    if( more ) {
        
        UIView* moreView = (UIView*)more;
    
        UIScrollView* scrollView = self.scrollView;
        
        BOOL hidden = ![self.delegate isThereMoreDataForGridView:self];
        if( hidden != moreView.hidden ) {
            moreView.hidden = hidden;
        }

        if( !hidden ) {
            CGRect bounds = scrollView.bounds;
            CGFloat b = bounds.origin.y + bounds.size.height;
            
            if( b >= scrollView.contentSize.height ) {
                [self _setMoreIndicatorState:VUIGridViewMoreState_Refreshing];
            }
        }
    }

}

- (void)_scrollViewDidScrolled {

    if( _delegateWillResponseRefresh ) {
        [self _checkPullRefreshView];
    }
    if( _delegateWillResponseMore ) {
        [self _checkMoreView];
    }
    
    [self _doCheckVisibility];

}

@end
