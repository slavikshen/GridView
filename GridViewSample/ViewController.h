//
//  ViewController.h
//  GridView
//
//  Created by Shen Slavik on 10/23/12.
//  Copyright (c) 2012 Voyager Apps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VUIGridView.h"

@interface ViewController : UIViewController<VUIGridViewDataSource,VUIGridViewDelegate>

@property(nonatomic,retain) IBOutlet VUIGridView* gridView;

- (IBAction)testReloadData;
- (IBAction)testInsertAtHead;
- (IBAction)testInsertAtMid;
- (IBAction)testInsertAtTail;
- (IBAction)testRmAtHead;
- (IBAction)testRmAtMid;
- (IBAction)testRmAtTail;

- (IBAction)reloadHead;
- (IBAction)reloadMid;

- (IBAction)switchMode;



@end
