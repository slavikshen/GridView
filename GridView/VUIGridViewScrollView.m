//
//  VUIGridViewScrollView.m
//  GridViewSample
//
//  Created by Shen Slavik on 11/2/12.
//  Copyright (c) 2012 Voyager Apps. All rights reserved.
//

#import "VUIGridViewScrollView.h"
#import "VUIGridView.h"
#import "VUIGridView+Layout.h"

@interface VUIGridViewScrollView()

@property(nonatomic,readwrite,assign) VUIGridView* gridView;

@end

@implementation VUIGridViewScrollView

- (id)initWithGridView:(VUIGridView*)gridView {
    self = [super initWithFrame:gridView.bounds];
	if( self ) {
    	self.gridView = gridView;
    }
    return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	[_gridView _checkVisibilityWhenScrollViewLayout];
}

- (void)setFrame:(CGRect)frame {
	
    CGSize prevSize = self.frame.size;
    [super setFrame:frame];
    CGSize size = self.frame.size;
    
    if( IS_SIZE_CHANGED(prevSize, size) ) {
    	[_gridView _resetContentSize];
    }
}

@end
