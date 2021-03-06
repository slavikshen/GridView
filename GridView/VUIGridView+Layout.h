//
//  VUIGridView+Layout.h
//  Youplay
//
//  Created by Slavik Shen on 12/14/11.
//  Copyright (c) 2011 apollobrowser.com. All rights reserved.
//

#import "VUIGridView.h"

@interface VUIGridView (Layout)

- (void)_resetContentSize;

- (void)_cleanUpCellForRecycle:(VUIGridCellView*)c;
- (void)_prepareCellForUse:(VUIGridCellView*)c;

- (void)_setNeedCheckVisibility;

- (void)_removeAllVisibleCells;

- (VUIGridCellView*)_getMeACellOfIndex:(NSUInteger)index;

- (NSRange)_calculateVisibleRange;
- (CGRect)_frameForCellAtIndex:(NSUInteger)index;

- (void)_doCheckVisibility;

- (void)_scrollViewDidScrolled;

- (void)_updateBackgoundViewFrame;

- (id<VUIGVPullRrefrehViewProtocol>)_loadPullRefreshView;

@end
