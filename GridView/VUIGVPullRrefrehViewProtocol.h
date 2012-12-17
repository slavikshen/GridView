//
//  VUIGVPullRrefrehView.h
//  Youplay
//
//  Created by Shen Slavik on 12/12/12.
//  Copyright (c) 2012 apollobrowser.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol VUIGVPullRrefrehViewProtocol <NSObject>

- (void)setTitle:(NSString*)title;
- (NSString*)title;

- (BOOL)activeAnimation;
- (void)setActiveAnimation:(BOOL)flag;

@end
