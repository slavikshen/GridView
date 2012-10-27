//
//  VUIGridCellView.m
//  Youplay
//
//  Created by Slavik Shen on 12/13/11.
//  Copyright (c) 2011 apollobrowser.com. All rights reserved.
//

#import "VUIGridCellView.h"
#import "VUIGridCellView+Private.h"

#ifdef VUI_DEBUG_VUIGRIDVIEW
#    define VUILog(...) NSLog(__VA_ARGS__)
#else
#    define VUILog(...) /* */
#endif

@interface VUIGridCellView()
@property(nonatomic,readwrite,copy) NSString* cellIdentity;
@property(nonatomic,readwrite,assign) NSUInteger index;
@property(nonatomic,readwrite,assign) BOOL isRecycled;
@end

@implementation VUIGridCellView

- (void)setup {
	
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

@end

@implementation VUIGridCellView (Private)

- (void)_setIndex:(NSUInteger)index {
	self.index = index;
}

- (void)_setIsRecycled:(BOOL)flag {
	self.isRecycled = flag;
}

@end
