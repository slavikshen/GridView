//
//  PullRefreshView.h
//  PullRefresh
//
//  Created by Shen Slavik on 11/25/12.
//  Copyright (c) 2012 Shen Slavik. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VUIGVPullRefreshView : UIView

@property(nonatomic,assign) CGFloat tailLength;
@property(nonatomic,copy) NSString* title;
@property(nonatomic,retain) UIColor* tint;

@property(nonatomic,assign) BOOL activeAnimation;

@end
