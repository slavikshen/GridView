//
//  VUIGridCellView.h
//  Youplay
//
//  Created by Slavik Shen on 12/13/11.
//  Copyright (c) 2011 apollobrowser.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

typedef enum {

	VUIGridCellContentState_Dirty,
    VUIGridCellContentState_Draft,
    VUIGridCellContentState_Perfect
    
} VUIGridCellContentState;

typedef struct {
    NSUInteger column;
    NSUInteger row;
    
} VUIGridCellMeta;

@interface VUIGridCellView : UIControl {

}

@property(nonatomic,readonly,copy) NSString* cellIdentity;

// if the index is NSNotFound, then it will be removed when check visibility
// don't change the index by yourself
@property(nonatomic,readonly,assign) NSUInteger index;

@property(nonatomic,assign) VUIGridCellMeta meta;

@property(nonatomic,assign) VUIGridCellContentState cellContentState;

@property(nonatomic,readonly,assign) BOOL isRecycled;

@property(nonatomic,assign) VUIGridCellContentState contentState;

- (id)initWithIdentity:(NSString*) cellIdentity;

// call when the cell is pushed into recycle pool
- (void)queuedIntoPool;

- (void)setup;

@end
