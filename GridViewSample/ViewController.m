//
//  ViewController.m
//  GridView
//
//  Created by Shen Slavik on 10/23/12.
//  Copyright (c) 2012 Voyager Apps. All rights reserved.
//

#import "ViewController.h"
#import "VUITextCellView.h"

@interface ViewController ()

@property(nonatomic,retain) NSMutableArray* list;

@end

@implementation ViewController

- (void)generateTestSample {
	
    NSMutableArray* list = [NSMutableArray arrayWithCapacity:26];
    
//    for( char i = 'A'; i <= 'Z'; i++ ) {
//    	NSString* s = [NSString stringWithFormat:@"%c", i];
//        [list addObject:s];
//    }
//
//    for( char i = 'a'; i <= 'z'; i++ ) {
//    	NSString* s = [NSString stringWithFormat:@"%c", i];
//        [list addObject:s];
//    }
//    
//    for( char i = '0'; i <= '9'; i++ ) {
//    	NSString* s = [NSString stringWithFormat:@"%c", i];
//        [list addObject:s];
//    }

    for( char i = '0'; i <= '4'; i++ ) {
    	NSString* s = [NSString stringWithFormat:@"%c", i];
        [list addObject:s];
    }
    
    self.list = list;
}

- (NSInteger)numberOfCellOfGridView:(VUIGridView *)gridView {
	return _list.count;
}

- (VUIGridCellView*)gridView:(VUIGridView *)gridView cellAtIndex:(NSUInteger)index {
	static NSString *CELL_ID = @"cell";
	VUITextCellView* cell = (VUITextCellView*)[gridView dequeueGridCellViewFromPool:CELL_ID];
    if( nil == cell ) {
    	cell = [[[VUITextCellView alloc] initWithIdentity:CELL_ID] autorelease];
    }
    
    cell.label.text = [_list objectAtIndex:index];
    
    return cell;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	CGSize cellSize = ( IS_PHONE ? CGSizeMake(64, 64) : CGSizeMake(128, 128) );
    CGSize spacing = CGSizeMake(10, 10);
    [_gridView setCellSize:cellSize andSpacing:spacing animate:NO];
	[self generateTestSample];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)gridView:(VUIGridView *)gridView didSelectCellAtIndexPath:(NSUInteger)index {
	
    VUIGridCellView* cell = [gridView cellAtIndex:index];
    cell.selected = !cell.selected;
    
}

- (IBAction)testReloadData {
    [self generateTestSample];
	[_gridView reloadData];
}

- (IBAction)testInsertAtHead {
	
	static NSUInteger i = 0;
    
    for( NSUInteger x = 0; x < 2; x++ ) {
        NSString* text = [NSString stringWithFormat:@"H%d", i++];
        [_list insertObject:text atIndex:0];
        [_gridView insertCellAtIndex:0 animated:YES];
    }
    
}

- (IBAction)testInsertAtMid {

	static NSUInteger i = 0;

    NSUInteger index = _list.count/2;
    
    for( NSUInteger x = 0; x < 2; x++ ) {
        NSString* text = [NSString stringWithFormat:@"M%d", i++];
        [_list insertObject:text atIndex:index];
        [_gridView insertCellAtIndex:index animated:YES];
    }
    
}

- (IBAction)testInsertAtTail {

	static NSUInteger i = 0;
    
    NSUInteger count = _list.count;
    
    for( NSUInteger x = 0; x < 2; x++ ) {
        NSString* text = [NSString stringWithFormat:@"T%d", i++];
        [_list insertObject:text atIndex:count];
        [_gridView insertCellAtIndex:count animated:YES];
    }
    
}

- (IBAction)testRmAtHead {
	[_list removeObjectAtIndex:0];
    [_gridView removeCellAtIndex:0 animated:YES];
}

- (IBAction)testRmAtMid {
	NSUInteger index = _list.count/2;
    [_list removeObjectAtIndex:index];
    [_gridView removeCellAtIndex:index animated:YES];
}

- (IBAction)testRmAtTail {
	NSUInteger index = _list.count-1;
    [_list removeObjectAtIndex:index];
    [_gridView removeCellAtIndex:index animated:YES];
}

- (IBAction)reloadHead {
	NSString* text = [_list objectAtIndex:0];
    if( [text hasPrefix:@"R"] ) {
		text = [text substringFromIndex:1];
    } else {
    	text = [NSString stringWithFormat:@"R%@", text];
    }
	[_list replaceObjectAtIndex:0 withObject:text];
	[_gridView reloadCellAtIndex:0 animated:YES];
}

- (IBAction)reloadMid {
	NSUInteger index = _list.count/2;
    NSString* text = [_list objectAtIndex:index];
    if( [text hasPrefix:@"R"] ) {
		text = [text substringFromIndex:1];
    } else {
    	text = [NSString stringWithFormat:@"R%@", text];
    }
	[_list replaceObjectAtIndex:index withObject:text];
    [_gridView reloadCellAtIndex:index animated:YES];
}


@end
