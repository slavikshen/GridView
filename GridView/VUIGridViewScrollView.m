//
//  VUIGridViewSrollView.m
//  Youplay
//
//  Created by Shen Slavik on 11/6/12.
//  Copyright (c) 2012 apollobrowser.com. All rights reserved.
//

#import "VUIGridViewScrollView.h"
#import "VUIGridView+Layout.h"

@implementation VUIGridViewScrollView

- (void)layoutSubviews {
    [super layoutSubviews];
    [_gridView _doCheckVisibility];
}

@end
