//
//  VUITextCellView.m
//  GridView
//
//  Created by Shen Slavik on 10/23/12.
//  Copyright (c) 2012 Voyager Apps. All rights reserved.
//

#import "VUITextCellView.h"

@interface VUITextCellView()
@property(nonatomic,readwrite,assign) UILabel* label;
@end

@implementation VUITextCellView


- (void)setup {

	CGRect bounds = self.bounds;
    
    self.backgroundColor = [UIColor grayColor];

	CGRect textFrame = bounds;
    textFrame.origin.x += 2;
    textFrame.origin.y += 2;
    textFrame.size.width -= 4;
    textFrame.size.height -= 4;
    
	UILabel* label = [[UILabel alloc] initWithFrame:textFrame];
    label.backgroundColor = [UIColor whiteColor];
    label.textColor = [UIColor blackColor];
    label.autoresizingMask = UIViewAutoresizingFlexibleSize;
    label.textAlignment = NSTextAlignmentCenter;
    
    [self addSubview:label];
    
    self.label = label;
    
    [label release];

}

- (void)setSelected:(BOOL)selected {
	[super setSelected:selected];
	UIColor* bgColor = selected ?
    	[UIColor yellowColor] :
    	[UIColor whiteColor];
    
    _label.backgroundColor = bgColor;
}

@end
