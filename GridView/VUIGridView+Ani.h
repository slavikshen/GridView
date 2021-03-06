//
//  VUIGridView+Ani.h
//  GridView
//
//  Created by Shen Slavik on 10/24/12.
//  Copyright (c) 2012 Voyager Apps. All rights reserved.
//

#ifdef ENABLE_GRIDVIEW_ANIMATION_CHANGE

#import "VUIGridView.h"

@interface VUIGridView (Ani)

- (void)_setNeedAnimChange;

- (void)_animateChangeAfterIndex:(NSUInteger)start;
- (void)_animateReloadAtIndex:(NSUInteger)index;

@end


#endif
