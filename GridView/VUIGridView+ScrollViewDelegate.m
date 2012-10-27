//
//  VUIGridView+ScrollViewDelegate.m
//  Youplay
//
//  Created by Slavik Shen on 12/15/11.
//  Copyright (c) 2011 apollobrowser.com. All rights reserved.
//

#import "VUIGridView+ScrollViewDelegate.h"
#import "VUIGridView+Layout.h"

#ifdef VUI_DEBUG_VUIGRIDVIEW
#    define VUILog(...) NSLog(__VA_ARGS__)
#else
#    define VUILog(...) /* */
#endif

@implementation VUIGridView (ScrollViewDelegate)


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	VUILog(@"VUIGridView scrollview did scroll");
	if( scrollView == self.scrollView && self.dataSource ) {
		[self _setNeedCheckVisibility];
	}

	id delegate = self.delegate;
	if( [delegate respondsToSelector:@selector(scrollViewDidScroll:)] ) {
		[delegate scrollViewDidScroll:scrollView];
	}
}
                                             // any offset changes
- (void)scrollViewDidZoom:(UIScrollView *)scrollView {

	id delegate = self.delegate;
	if( [delegate respondsToSelector:@selector(scrollViewDidZoom:)] ) {
		[delegate scrollViewDidZoom:scrollView];
	}
}

// called on start of dragging (may require some time and or distance to move)
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {

	id delegate = self.delegate;
	if( [delegate respondsToSelector:@selector(scrollViewWillBeginDragging:)] ) {
		[delegate scrollViewWillBeginDragging:scrollView];
	}
}

// called on finger up if the user dragged. velocity is in points/second. targetContentOffset may be changed to adjust where the scroll view comes to rest. not called when pagingEnabled is YES
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
		
    id delegate = self.delegate;
	if( [delegate respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)] ) {
		[delegate scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
	}
}

// called on finger up if the user dragged. decelerate is true if it will continue moving afterwards
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
		
    id delegate = self.delegate;
	if( [delegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)] ) {
		[delegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
	}
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
	
    id delegate = self.delegate;
	if( [delegate respondsToSelector:@selector(scrollViewWillBeginDecelerating:)] ) {
		[delegate scrollViewWillBeginDecelerating:scrollView];
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {

	id delegate = self.delegate;
	if( [delegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)] ) {
		[delegate scrollViewDidEndDecelerating:scrollView];
	}
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {

	id delegate = self.delegate;
	if( [delegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)] ) {
		[delegate scrollViewDidEndScrollingAnimation:scrollView];
	}
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {

	id delegate = self.delegate;
	if( [delegate respondsToSelector:@selector(viewForZoomingInScrollView:)] ) {
		return [delegate viewForZoomingInScrollView:scrollView];
	}
	return nil;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
	
    id delegate = self.delegate;
	if( [delegate respondsToSelector:@selector(scrollViewWillBeginZooming:withView:)] ) {
		[delegate scrollViewWillBeginZooming:scrollView withView:view];
	}
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
	
    id delegate = self.delegate;
	if( [delegate respondsToSelector:@selector(scrollViewDidEndZooming:withView:atScale:)] ) {
		[delegate scrollViewDidEndZooming:scrollView withView:view atScale:scale];
	}
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {

	id delegate = self.delegate;
	if( [delegate respondsToSelector:@selector(scrollViewShouldScrollToTop:)] ) {
		return [delegate scrollViewShouldScrollToTop:scrollView];
	}
	return YES;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
	
    id delegate = self.delegate;
	if( scrollView == self.scrollView && self.dataSource ) {
		[self _setNeedCheckVisibility];
    }

	if( [delegate respondsToSelector:@selector(scrollViewDidScrollToTop:)] ) {
		[delegate respondsToSelector:@selector(scrollViewDidScrollToTop:)];
	}
}

@end
