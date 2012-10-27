//
//  VUIGridView+Private.h
//  TVGallery
//
//  Created by Shen Slavik on 10/25/12.
//  Copyright (c) 2012 Voyager Apps. All rights reserved.
//

#import "VUIGridView.h"

@interface VUIGridView (Private)

- (void)_requestUpdateCellContent:(VUIGridCellView*)cell;
- (void)_cancelUpdateCellContent:(VUIGridCellView*)cell;

@end

