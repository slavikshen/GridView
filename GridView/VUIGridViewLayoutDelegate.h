//
//  VUIGridViewLayout.h
//  GridViewSample
//
//  Created by Shen Slavik on 11/5/12.
//  Copyright (c) 2012 Voyager Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol VUIGridViewLayoutDelegate <NSObject>

- (CGSize)contentSize;
- (CGRect)frameOfCellAtIndex:(NSUInteger)index;
- (NSRange)visibleRangeInBounds:(CGRect)bounds;

@end
