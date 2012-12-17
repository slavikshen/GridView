//
//  VUIGridCellView.m
//  Youplay
//
//  Created by Slavik Shen on 12/13/11.
//  Copyright (c) 2011 apollobrowser.com. All rights reserved.
//

#import "VUIGridCellView.h"
#import "VUIGridCellView+Private.h"
#import "VUIGridCellHightlightView.h"

#ifdef VUI_DEBUG_VUIGRIDVIEW
#    define VUILog(...) NSLog(__VA_ARGS__)
#else
#    define VUILog(...) /* */
#endif

@interface VUIGridCellView()

@property(nonatomic,readwrite,copy) NSString* cellIdentity;
@property(nonatomic,readwrite,assign) NSUInteger index;
@property(nonatomic,readwrite,assign) BOOL isRecycled;
@property(nonatomic,assign) VUIGridCellHightlightView* hightlightView;

@end

@implementation VUIGridCellView {

#ifdef VUIGRIDVIEW_SHOW_CELL_INDEX
    CALayer* _indexBgLayer;
    CATextLayer* _cellIndexTextLayer;
#endif

}

- (void)setup {

#ifdef VUIGRIDVIEW_SHOW_CELL_INDEX

    _indexBgLayer = [CALayer layer];
    _indexBgLayer.backgroundColor = [UIColor redColor].CGColor;
    _indexBgLayer.frame = CGRectMake(0, 0, 32, 32);
    
    _cellIndexTextLayer = [CATextLayer layer];
    _cellIndexTextLayer.foregroundColor = [UIColor whiteColor].CGColor;
    _cellIndexTextLayer.fontSize = 14;
    _cellIndexTextLayer.frame = _indexBgLayer.bounds;
    
    [_indexBgLayer addSublayer:_cellIndexTextLayer];
    
    _indexBgLayer.zPosition = 1;
    [self.layer addSublayer:_indexBgLayer];
    
#endif
    
}

- (void)dealloc {
	SRELEASE(_cellIdentity);
    [super dealloc];
}

-(CGSize)sizeThatFits:(CGSize)size {
	return CGSizeMake(240,180);
}

- (id)initWithIdentity:(NSString*)cellIdentity {
	self = [self initWithFrame:CGRectZero];
    if( self ) {
    	[self sizeToFit];
    	self.cellIdentity = cellIdentity;
        [self setup];
    }
    return self;
}

- (void)queuedIntoPool {

}

- (void)setHightlightStyle:(VUIGridCellHighlightStyle)hightlightStyle {
    _hightlightStyle = hightlightStyle;
    _hightlightView.style = hightlightStyle;
}

- (void)setHighlighted:(BOOL)highlighted {

    if( self.highlighted != highlighted ) {
        [super setHighlighted:highlighted];
        if( highlighted ) {
            if( _hightlightStyle ) {
                if( nil == _hightlightView ) {
                    VUIGridCellHightlightView* highlightView = [[VUIGridCellHightlightView alloc] initWithFrame:self.bounds];
                    highlightView.autoresizingMask = UIViewAutoresizingFlexibleSize;
                    highlightView.style = _hightlightStyle;
                    [self insertSubview:highlightView atIndex:0];
                    self.hightlightView = highlightView;
                    [highlightView release];
                } else {
                    _hightlightView.hidden = NO;
                }
            }
        } else {
            _hightlightView.hidden = YES;
        }
    }

}

@end

@implementation VUIGridCellView (Private)

- (void)_setIndex:(NSUInteger)index {
	self.index = index;
    
#ifdef VUIGRIDVIEW_SHOW_CELL_INDEX
    _cellIndexTextLayer.string = [NSString stringWithFormat:@"%d", index];
#endif
    
    
}

- (void)_setIsRecycled:(BOOL)flag {
	self.isRecycled = flag;
}

@end
