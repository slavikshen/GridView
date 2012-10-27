//
//  VUICoverView.m
//  Youplay
//
//  Created by Slavik Shen on 12/19/11.
//  Copyright (c) 2011 apollobrowser.com. All rights reserved.
//

#import "VUICoverView.h"

#ifdef VUI_DEBUG_VUIGRIDVIEW
#    define VUILog(...) NSLog(__VA_ARGS__)
#else
#    define VUILog(...) /* */
#endif

@implementation VUICoverView

- (void)setup {
	[super setup];
    UIScrollView* scrollView = self.scrollView;
    scrollView.alwaysBounceVertical = NO;
    scrollView.alwaysBounceHorizontal = YES;
    scrollView.bounces = YES;
    scrollView.scrollsToTop = NO;
    scrollView.backgroundColor = [UIColor clearColor];
}

- (void)_resetContentSize {

	UIScrollView* scrollView = self.scrollView;
	CGRect bounds = scrollView.bounds;

	CGFloat W = bounds.size.width;
    CGFloat H = bounds.size.height;
    
    CGSize cellSize = self.cellSize;
    CGSize spacing = self.cellSpacing;
    
    CGFloat cW = cellSize.width;
    CGFloat cPW = spacing.width;

    NSUInteger numberOfCells = self.numberOfCells;
    NSUInteger col = numberOfCells;
	NSUInteger numberOfRows = 1;
    
    CGSize contentSize = CGSizeMake(W, H);
    if( col ) {
        contentSize.width = (cW+cPW)*(col-1)+cW;
    }
    
    scrollView.contentSize = contentSize;
    
    _numberOfColumns = col;
    _numberOfRows = numberOfRows;
    
}

- (NSRange)_calculateVisibleRange {

	UIScrollView* scrollView = self.scrollView;
	CGRect bounds = scrollView.bounds;
    
    CGFloat L = bounds.origin.x;
    if( L < 0 ) {
    	L = 0;
    }
    CGFloat W = bounds.size.width;
    
    CGSize cellSize  = self.cellSize;
    CGSize cellSpacing = self.cellSpacing;
    
    CGFloat cW = cellSize.width;
	CGFloat cPW = cellSpacing.width;
    
    CGFloat cWPW = cW+cPW;
    
    NSInteger firstCol = floorf(L/cWPW);
    NSInteger end = ceilf((L+W)/cWPW);
    
    NSUInteger maxCount = self.numberOfCells;
    end = MIN(end, maxCount);
    
    NSRange range = NSMakeRange(firstCol, end-firstCol);
    
    return range;
    
}

- (void)_layoutCells {

    UIScrollView* scrollView = self.scrollView;
	CGRect bounds = scrollView.bounds;
    
    CGFloat H = bounds.size.height;
    
    CGSize cellSize = self.cellSize;
    CGSize spacing = self.cellSpacing;
    
    CGFloat cW = cellSize.width;
    CGFloat cH = cellSize.height;
    CGFloat cPW = spacing.width;
    
    CGFloat cWPW = cW+cPW;
    
    CGFloat topIndent = floorf((H-cH)/2);
    
	for( VUIGridCellView* c in _visibleCells ) {
        
    	NSUInteger cellCol = c.index;
        
        CGFloat x = cellCol*cWPW;
        CGFloat y = topIndent;
        
		CGRect newFrame = CGRectMake(x, y, cW, cH);
        
        CGRect oldFrame = c.frame;
        
        if( IS_DIFFERENT_FRAME(newFrame, oldFrame)) {
        	c.frame = newFrame;
        }
    }
    
}

- (CGRect)_frameForCellAtIndex:(NSUInteger)index {

    UIScrollView* scrollView = self.scrollView;
	CGRect bounds = scrollView.bounds;
    
    CGFloat H = bounds.size.height;
    
    CGSize cellSize = self.cellSize;
    CGSize spacing = self.cellSpacing;
    
    CGFloat cW = cellSize.width;
    CGFloat cH = cellSize.height;
    CGFloat cPW = spacing.width;
    
    CGFloat cWPW = cW+cPW;
    
    CGFloat topIndent = floorf((H-cH)/2);
    
	NSUInteger cellCol = index;
    
    CGFloat x = cellCol*cWPW;
    CGFloat y = topIndent;
        
	CGRect frame = CGRectMake(x, y, cW, cH);
    
    return frame;
}


@end
