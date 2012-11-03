//
//  VUIGridViewScrollView.h
//  GridViewSample
//
//  Created by Shen Slavik on 11/2/12.
//  Copyright (c) 2012 Voyager Apps. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VUIGridView;

@interface VUIGridViewScrollView : UIScrollView

- (id)initWithGridView:(VUIGridView*)gridView;

@property(nonatomic,readonly,assign) VUIGridView* gridView;

@end
