//
//  VUIGridView+Ani.m
//  GridView
//
//  Created by Shen Slavik on 10/24/12.
//  Copyright (c) 2012 Voyager Apps. All rights reserved.
//

#ifdef ENABLE_GRIDVIEW_ANIMATION_CHANGE

#import "VUIGridView+Ani.h"
#import "VUIGridView+Layout.h"

#import <QuartzCore/QuartzCore.h>

#define CLIP_ANI_DURATION (0.5f)

@interface VUIGridView (AniPrivate)

- (void)animationAllStoppedInLayer:(CALayer*)layer;

@end

@interface IndexedLayer : CALayer

@property(nonatomic,assign) NSUInteger cellIndex;

@end

@implementation IndexedLayer

@end

@interface CellAniLayer : CALayer

@property(nonatomic,assign) NSUInteger aniCount;
@property(nonatomic,assign) VUIGridView* gridView;

@end

@implementation CellAniLayer

- (void)animationDidStart:(CAAnimation *)theAnimation {

	_aniCount++;

}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {

	_aniCount--;
    
    if( 0 == _aniCount ) {
    	[_gridView animationAllStoppedInLayer:self];
    }

}

- (CALayer *)hitTest:(CGPoint)thePoint {
    return nil;
}

@end

@implementation VUIGridView (Ani)

- (void)_setNeedAnimChange {
    if( _needAnimateChange ) {
        return;
    }
    _needAnimateChange = YES;
    [self performSelectorOnMainThread:@selector(_animateChangeNow) withObject:nil waitUntilDone:NO];
}

- (void) _animateChangeNow {
    

    NSUInteger index = _changeStartIndex;

    _needAnimateChange = NO;
    _changeStartIndex = NSNotFound;
    
    @autoreleasepool {
        [self _animateChangeAfterIndex:index];
    }
    

    
}

- (IndexedLayer*)_layerForCell:(VUIGridCellView*)cell offset:(CGPoint)offset {
    
    CGFloat scale = self.window.screen.scale;
    CALayer* rootLayer = cell.layer;
    
    // snapshot the root
    CGSize originalSize = cell.frame.size;
	UIGraphicsBeginImageContextWithOptions(originalSize,NO,scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [rootLayer renderInContext:ctx];

#ifdef SHOW_RED_DOT_ON_DUMP_LAYER
    CGContextSetFillColorWithColor(ctx, [[UIColor redColor] CGColor]);
	CGContextFillRect(ctx, CGRectMake(0, 0, 5, 5));
#endif
    
	CGImageRef resultingImage = CGBitmapContextCreateImage(ctx);
	UIGraphicsEndImageContext();
    
	IndexedLayer* layer = [IndexedLayer layer];
    layer.contentsScale = scale;
    layer.cellIndex = cell.index;
    layer.anchorPoint = CGPointZero;
    layer.doubleSided = NO;
    
    CGRect frame = cell.frame;
    frame.origin.x -= offset.x;
    frame.origin.y -= offset.y;
    layer.frame = frame;

    layer.contents = (id)resultingImage;
    CGImageRelease(resultingImage);
    
    return layer;
}

- (CABasicAnimation*)_moveCellLayer:(CALayer*)l toPositionWithAni:(CGPoint)pos delegate:(id)delegate  {
    CABasicAnimation *posAni = [CABasicAnimation animationWithKeyPath:@"position"];
    posAni.duration = CLIP_ANI_DURATION;
    posAni.fromValue = [l valueForKey:@"position"];
    posAni.toValue = [NSValue valueWithCGPoint:pos];
    posAni.removedOnCompletion = NO;
    posAni.fillMode = kCAFillModeForwards;
    posAni.delegate = delegate;
    l.position = pos;
    
    return posAni;
}

- (CABasicAnimation*)_changeOpacityOfCellLayer:(CALayer*)l to:(CGFloat)opacity delegate:(id)delegate  {
    CABasicAnimation *alphaAni = [CABasicAnimation animationWithKeyPath:@"opacity"];
    alphaAni.duration = CLIP_ANI_DURATION;
    alphaAni.fromValue = [l valueForKey:@"opacity"];
    alphaAni.toValue = [NSNumber numberWithFloat:opacity];
    alphaAni.delegate = delegate;
    alphaAni.removedOnCompletion = NO;
    alphaAni.fillMode = kCAFillModeForwards;
    l.opacity = opacity;
    
    return alphaAni;
}

- (void)_animateChangeAfterIndex:(NSUInteger)start {

	CALayer* scrollViewLayer = self.scrollView.layer;
    CellAniLayer* aniLayer = [CellAniLayer layer];

    CGRect bounds = scrollViewLayer.bounds;
    CGPoint baseOffset = bounds.origin;

    aniLayer.frame = bounds;
    aniLayer.gridView = self;

	NSMutableArray* layers = [[NSMutableArray alloc] initWithCapacity:_visibleCells.count*2];
	NSMutableArray* newLineLayers =  [[NSMutableArray alloc] initWithCapacity:_visibleCells.count/_numberOfColumns];
    
    CFTimeInterval moveBeginTime = 0;
    CFTimeInterval insertBeginTime = CLIP_ANI_DURATION;

	// create layers for cell at current position
    for( VUIGridCellView* c in _visibleCells ) {
    	// create layer for each cell
        NSUInteger cellIndex = c.index;
        if( NSNotFound == cellIndex || cellIndex >= start ) {
//            DLog(@"Dump layer for cell at index %d", cellIndex);
            c.hidden = NO;
            IndexedLayer* layer = [self _layerForCell:c offset:baseOffset];
            // insert the layer
            NSUInteger i = 0;
            NSUInteger count = layers.count;
            NSUInteger insertPos = NSNotFound;
            while( i < count ) {
                IndexedLayer* l = [layers objectAtIndex:i];
                if( cellIndex > l.cellIndex ) {
                    i++;
                } else {
                    insertPos = i;
                    break;
                }
            }
            if( NSNotFound == insertPos ) {
                insertPos = count;
            }
            [layers insertObject:layer atIndex:insertPos];
//            DLog(@"dump layer of cell index %d at frame %@", cellIndex, NSStringFromCGRect(layer.frame));
            // hide dumped cell
            c.hidden = YES;
        }
        if( NSNotFound == cellIndex && moveBeginTime == 0 ) {
            moveBeginTime = CLIP_ANI_DURATION;
            insertBeginTime = moveBeginTime + CLIP_ANI_DURATION;
        }
    }

    
//    DLog(@"*****before layout******");
//    for( VUIGridCellView* c in _visibleCells ) {
//        CGRect destFrame = c.frame;
//        destFrame.origin.x -= baseOffset.x;
//        destFrame.origin.y -= baseOffset.y;
//        DLog(@"cell of index %d is at frame %@", c.index, NSStringFromCGRect(destFrame) );
//    }
    
    // calculate new positions
    [self _layoutCells];

//    DLog(@"*******after layout*******");
//    for( VUIGridCellView* c in _visibleCells ) {
//        CGRect destFrame = c.frame;
//        destFrame.origin.x -= baseOffset.x;
//        destFrame.origin.y -= baseOffset.y;
//        DLog(@"cell of index %d is at frame %@", c.index, NSStringFromCGRect(destFrame) );
//    }
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    [scrollViewLayer addSublayer:aniLayer];

    
  	NSMutableSet* removedCells = nil;
    
	// create dump layer for cells at new line
    for( VUIGridCellView* c in _visibleCells ) {
    	// create layer for each cell
        CGRect destFrame = c.frame;
        
        destFrame.origin.x -= baseOffset.x;
        destFrame.origin.y -= baseOffset.y;
        
        NSUInteger cellIndex = c.index;

        for( IndexedLayer* l in layers ) {
            NSUInteger lindex = l.cellIndex;
            
        	if( lindex == cellIndex ) {
//                DLog(@"Check layer of cell index %d", cellIndex);
       	        [aniLayer addSublayer:l];
               	CGRect originFrame = l.frame;
                CGFloat originY = originFrame.origin.y;
                CGFloat destY = destFrame.origin.y;
                if( IS_PIXEL_COORDINATE_CHANGED(originY, destY) ) {
//                    DLog(@"Move to new line");
                	// not at the same row now
                    // dump a layer to the new row
                    IndexedLayer* newLayer = [[IndexedLayer alloc] init];
                    newLayer.cellIndex = l.cellIndex;
                    newLayer.anchorPoint = CGPointZero;
                    newLayer.contentsScale = l.contentsScale;
                    newLayer.contents = l.contents;
                    newLayer.anchorPoint = CGPointMake(0,0);
                    
                    CGRect frame = destFrame;
                    CGFloat cw = _numberOfColumns*(self.cellSize.width+self.cellSpacing.width)*(destY < originY?1:-1);
                    frame.origin.x += cw;
                    newLayer.frame = frame;
                    
//                    DLog(@"Add cell layer for new line at frame %@", NSStringFromCGRect(frame));

                	[newLineLayers addObject:newLayer];
                    
                    [aniLayer addSublayer:newLayer];
                    
                    [newLayer release];
                } else if( !IS_DIFFERENT_FRAME(originFrame, destFrame) ) {
//                	DLog(@"Set opacity of the new cell to 0 at %@", NSStringFromCGRect(destFrame));
					if( cellIndex != NSNotFound ) {
                    	// this is a new cell
                        // hide it at first
//                        DLog(@"hide new cell");
                		l.opacity = 0;
                    }
                } else {
//                	DLog(@"Just move cell");
                }
                break;
            } else if( lindex > cellIndex ) {
                // no need to scan
                break;
            }
        }
        
        if( cellIndex == NSNotFound ) {
        	 // the cell is deleted, not used any more
            if( nil == removedCells ) {
               	removedCells = [[NSMutableSet alloc] initWithCapacity:_visibleCells.count];
            }
			[c removeFromSuperview];
            [self _cleanUpCellForRecycle:c];
            [removedCells addObject:c];
        }
    }
    
    [CATransaction commit];
    
//    DLog(@"start animation");
    
    CAMediaTimingFunction* outFunc = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    CAMediaTimingFunction* inFunc = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];

	// begin animation
    for( IndexedLayer* l in newLineLayers ) {
    	NSUInteger cellIndex = l.cellIndex;
        for( VUIGridCellView* c in _visibleCells ) {
        	if( c.index == cellIndex ) {
				CGRect frame = c.frame;
                frame.origin.x -= baseOffset.x;
			    frame.origin.y -= baseOffset.y;
//	            DLog(@"Move & reveal the cell from %@ to %@", NSStringFromCGRect(originFrame), NSStringFromCGRect(frame));
    		    CABasicAnimation* posAni = [self _moveCellLayer:l toPositionWithAni:frame.origin delegate:aniLayer];
        		posAni.timingFunction = inFunc;
                posAni.timeOffset = moveBeginTime;
                [l addAnimation:posAni forKey:@"position"];
                break;
            }
        }
    }
    
	// create layers for cell at current position

        
    for( IndexedLayer* l in layers ) {
    
        NSUInteger lindex = l.cellIndex;
        if( NSNotFound == lindex ) {
            CABasicAnimation* alphaAni = [self _changeOpacityOfCellLayer:l to:0 delegate:aniLayer];
            [l addAnimation:alphaAni forKey:@"opacity"];
            continue;
        }
        
        VUIGridCellView* cell = nil;
        for( VUIGridCellView* c in _visibleCells ) {
            if( c.index == lindex ) {
                cell = c;
                break;
            }
        }
        
        if( nil == cell ) {
            continue;
        }
        
        CGRect destFrame = cell.frame;
        
        destFrame.origin.x -= baseOffset.x;
        destFrame.origin.y -= baseOffset.y;

//        DLog(@"Check ani for layer of cell index %d", lindex);
        
        CGRect originFrame = l.frame;
        CGFloat originY = originFrame.origin.y;
        CGFloat destY = destFrame.origin.y;
        if( IS_PIXEL_COORDINATE_CHANGED(originY, destY) ) {
            // move the the right and disppear
//            DLog(@"check the layer of new line");
            CGPoint pos = originFrame.origin;
            CGFloat cw = (self.cellSize.width+self.cellSpacing.width)*(destY < originY?-1:1);
            if( 0 != lindex ) {
                NSUInteger prevIndex = lindex - 1;
                // find the previouse layer
                for( IndexedLayer* prev in layers ) {
                    NSUInteger pIndex = prev.cellIndex;
                    if( pIndex == prevIndex ) {
//                        DLog(@"Change by prev position %@", NSStringFromCGPoint(prev.position));
                        if( IS_PIXEL_COORDINATE_CHANGED(prev.position.y, pos.y) ) {
                            pos.x = _numberOfColumns*cw;
                        } else {
                            pos.x = prev.position.x + cw;
                        }
                        break;
                    } else if( pIndex > prevIndex ) {
//                        DLog(@"not found");
                        break;
                    }
                }
            } else {
//                DLog(@"just move");
                pos.x += cw;
            }
            
//            DLog(@"Move & hide cell from %@ to %@", NSStringFromCGPoint(originFrame.origin) , NSStringFromCGPoint(pos));
            CABasicAnimation* posAni = [self _moveCellLayer:l toPositionWithAni:pos delegate:aniLayer];
            CABasicAnimation* alphaAni = [self _changeOpacityOfCellLayer:l to:0 delegate:aniLayer];
            CAAnimationGroup *anim = [CAAnimationGroup animation];
            [anim setAnimations:[NSArray arrayWithObjects:posAni, alphaAni, nil]];
            [anim setDuration:CLIP_ANI_DURATION];
            [anim setFillMode:kCAFillModeForwards];
            anim.timeOffset = moveBeginTime;
            [l addAnimation:anim forKey:nil];
            
            posAni.timingFunction = outFunc;
            alphaAni.timingFunction = outFunc;
            
        } else if( !IS_DIFFERENT_FRAME(originFrame, destFrame) ) {
//                        DLog(@"Reveil the new cell");
            CABasicAnimation* alphaAni = [self _changeOpacityOfCellLayer:l to:1 delegate:aniLayer];
            alphaAni.timeOffset = insertBeginTime;
            [l addAnimation:alphaAni forKey:@"opacity"];
        } else {
//                	DLog(@"Move cell from %@ to %@ ", NSStringFromCGRect(originFrame) , NSStringFromCGRect(destFrame));
            CABasicAnimation* posAni = [self _moveCellLayer:l toPositionWithAni:destFrame.origin delegate:aniLayer];
            posAni.timeOffset = moveBeginTime;
            [l addAnimation:posAni forKey:@"position"];
        }
    }
    

    [newLineLayers release];
    [layers release];
    
    if( removedCells ) {
       	[_visibleCells minusSet:removedCells];
        [_recycledCells unionSet:removedCells];
        [removedCells release];
    }
    
//    DLog(@"ani created");

}

- (void)_animateReloadAtIndex:(NSUInteger)index {

	CALayer* scrollViewLayer = self.scrollView.layer;
    CellAniLayer* aniLayer = [CellAniLayer layer];
    CGRect bounds = scrollViewLayer.bounds;
    CGPoint baseOffset = bounds.origin;

    aniLayer.frame = bounds;
    aniLayer.gridView = self;
    
    NSMutableSet* removedCells = nil;
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];

	// create layers for cell at current position
    for( VUIGridCellView* c in _visibleCells ) {
    	// create layer for each cell
        NSUInteger cellIndex = c.index;
        if( NSNotFound == cellIndex || cellIndex == index ) {
            IndexedLayer* layer = [self _layerForCell:c offset:baseOffset];
            [aniLayer addSublayer:layer];
            // hide dumped cell
            c.hidden = YES;
            if( cellIndex == NSNotFound ) {
                 // the cell is deleted, not used any more
                if( nil == removedCells ) {
                    removedCells = [[NSMutableSet alloc] initWithCapacity:_visibleCells.count];
                }
                [c removeFromSuperview];
                [self _cleanUpCellForRecycle:c];
                [removedCells addObject:c];
            } else {
                layer.opacity = 0;
            }
        }
        
    }
    
    [scrollViewLayer addSublayer:aniLayer];
    
    [CATransaction commit];

	for( IndexedLayer* l in aniLayer.sublayers ) {
    	NSUInteger cellIndex = l.cellIndex;
        CGFloat opacity = 0;
        CFTimeInterval delay = 0;
        if( NSNotFound != cellIndex ) {
        	opacity = 1;
            delay = CLIP_ANI_DURATION;
        }
        CABasicAnimation* alphaAni = [self _changeOpacityOfCellLayer:l to:opacity delegate:aniLayer];
        alphaAni.timeOffset = delay;
        [l addAnimation:alphaAni forKey:@"opacity"];
    }
    
    if( removedCells ) {
       	[_visibleCells minusSet:removedCells];
        [_recycledCells unionSet:removedCells];
        [removedCells release];
    }

}

- (void)animationAllStoppedInLayer:(CellAniLayer*)layer {

//	DLog(@"all ani stopped");

    int64_t delayInSeconds = 0.0f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        for( VUIGridCellView* c in _visibleCells ) {
        	// check all cells
            if( c.hidden ) {
//	            NSUInteger cellIndex = c.index;
//                for( IndexedLayer* l in layer.sublayers ) {
//					if( l.cellIndex == cellIndex ) {
                    	c.hidden = NO;
//                    }
//                }
            }
        }
        [layer removeFromSuperlayer];
    });


}

@end

#endif
 