//
//  VUIGridViewUpdateCellContentOperation.h
//  TVGallery
//
//  Created by Shen Slavik on 10/25/12.
//  Copyright (c) 2012 Voyager Apps. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VUIGridCellView;
@class VUIGridView;

@interface VUIGridViewUpdateCellContentOperation : NSOperation

@property(nonatomic,retain) VUIGridCellView* cell;
@property(nonatomic,assign) VUIGridView* gridView;

@end
