//
//  VUIGridViewSrollView.m
//  Youplay
//
//  Created by Shen Slavik on 11/6/12.
//  Copyright (c) 2012 apollobrowser.com. All rights reserved.
//

#import "VUIGridViewScrollView.h"
#import "VUIGridView+Layout.h"

@implementation VUIGridViewScrollView {
    BOOL _sizeDidChanged;
    CGPoint _prevOffset;
}

- (void)_setup {

    _sizeDidChanged = NO;
    _prevOffset = CGPointMake(-1,-1);

}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    [self _setup];
    return self;
}

- (id)initWithFrame:(CGRect)frame {

    self = [super initWithFrame:frame];
    [self _setup];
    return self;

}

- (void)setNeedsLayout {
    [super setNeedsLayout];
    _sizeDidChanged = YES;
}

//- (void)setFrame:(CGRect)frame {
//
//    CGSize prevSize = self.frame.size;
//    [super setFrame:frame];
//    CGSize size = self.frame.size;
//    
//    if( IS_SIZE_CHANGED(prevSize, size) ) {
//        _sizeDidChanged = YES;
//    }
//
//}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    BOOL didScroll = _sizeDidChanged;
    _sizeDidChanged = NO;
    
    if( !didScroll ) {
        CGPoint offset = self.contentOffset;
        didScroll = IS_POSITION_CHANGED(_prevOffset,offset);
        _prevOffset = offset;
    }
    
    if( didScroll ) {
        [_gridView _scrollViewDidScrolled];
    }

}

@end
