//
//  MoreView.m
//  Youplay
//
//  Created by Shen Slavik on 11/26/12.
//  Copyright (c) 2012 apollobrowser.com. All rights reserved.
//

#import "VUIGVMoreView.h"

@interface VUIGVMoreView()

@property(nonatomic,assign) UIActivityIndicatorView* activityView;

@end

@implementation VUIGVMoreView {

    CATextLayer* _text;
    
}

@dynamic title;

- (void)setTitle:(NSString *)title {
    _text.string = title;
}

- (NSString*)title {
    return _text.string;
}

- (void)setActiveAnimation:(BOOL)flag {

    if( _activeAnimation != flag ) {
    
        _activeAnimation = flag;
        
        if( _activeAnimation ) {
            [_activityView startAnimating];
        } else {
            [_activityView stopAnimating];
        }

    }

}

- (void)_layoutSubviews {

    CGRect bounds = self.bounds;
    CGSize size = bounds.size;
    CGFloat H = size.height;

    CGSize aSize = _activityView.frame.size;
    CGFloat x = floorf((H - aSize.width)/2);
    CGFloat y = floorf((H - aSize.height)/2);
    CGRect aFrame = CGRectMake(x, y, aSize.width, aSize.height);
    _activityView.frame = aFrame;
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    CGRect frame = bounds;
    frame.origin.x += H;
    frame.origin.y = y;
    frame.size.width -= H;
    _text.frame = frame;
    
    [CATransaction commit];

}


- (void)_setup {

    self.backgroundColor = [UIColor clearColor];

    UIActivityIndicatorView* aView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    aView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
//    aView.hidesWhenStopped = YES;
    
    [self addSubview:aView];
    self.activityView = aView;
    [aView release];
    
    _text = [CATextLayer layer];
    _text.alignmentMode = kCAAlignmentJustified;
    _text.wrapped = YES;
    _text.fontSize = 18;
    _text.foregroundColor = [[UIColor darkGrayColor] CGColor];
    _text.contentsScale = [UIScreen mainScreen].scale;
    
    [self.layer addSublayer:_text];
    
    [self _layoutSubviews];

}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    [self _setup];
    return self;
}

- (void)setFrame:(CGRect)frame {

    CGSize prevSize = self.frame.size;
    [super setFrame:frame];
    CGSize size = self.frame.size;
    
    if( IS_SIZE_CHANGED(prevSize, size) ) {
        [self _layoutSubviews];
    }

}

@end
