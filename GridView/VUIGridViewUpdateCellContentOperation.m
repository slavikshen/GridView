//
//  VUIGridViewUpdateCellContentOperation.m
//  TVGallery
//
//  Created by Shen Slavik on 10/25/12.
//  Copyright (c) 2012 Voyager Apps. All rights reserved.
//

#import "VUIGridViewUpdateCellContentOperation.h"
#import "VUIGridView.h"
#import "VUIGridCellView.h"

@implementation VUIGridViewUpdateCellContentOperation

- (void)dealloc {
	self.cell = nil;
    self.gridView = nil;
    [super dealloc];
}

- (void)cancel {
	[super cancel];
	self.cell = nil;
    self.gridView = nil;
}

- (void)main {
	if( ![self isCancelled] ) {
    	NSUInteger index = _cell.index;
        [_gridView retain];
        id dataSource = _gridView.dataSource;
        [dataSource gridView:_gridView upgradeCellAtIndex:index];
        [_gridView release];
    }
}

@end
