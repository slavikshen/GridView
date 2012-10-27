//
//  VUIGridView+Ani.m
//  GridView
//
//  Created by Shen Slavik on 10/24/12.
//  Copyright (c) 2012 Voyager Apps. All rights reserved.
//

#import "VUIGridView+Ani.h"
#import "VUIGridView+Layout.h"

#import <QuartzCore/QuartzCore.h>

#define CLIP_ANI_DURATION (0.3f)

@interface IndexedLayer : CALayer

@property(nonatomic,assign) NSUInteger cellIndex;

@end

@implementation IndexedLayer

@end

@interface CellAniLayer : CALayer

@property(nonatomic,assign) NSUInteger aniCount;

@end

@implementation CellAniLayer

- (void)animationDidStart:(CAAnimation *)theAnimation {

	_aniCount++;

}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {

	_aniCount--;
    
    if( 0 == _aniCount ) {
    	[self.delegate animationAllStoppedInLayer:self];
    }

}


@end

@implementation VUIGridView (Ani)

- (IndexedLayer*)_newLayerForCell:(VUIGridCellView*)cell offset:(CGPoint)offset {
    
    CGFloat scale = self.window.screen.scale;
    CALayer* rootLayer = cell.layer;
    
    // snapshot the root
    CGSize originalSize = cell.frame.size;
	UIGraphicsBeginImageContextWithOptions(originalSize,NO,scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [rootLayer renderInContext:ctx];
    
//    CGContextSetFillColorWithColor(ctx, [[UIColor redColor] CGColor]);
//	CGContextFillRect(ctx, CGRectMake(0, 0, 5, 5));
    
	CGImageRef resultingImage = CGBitmapContextCreateImage(ctx);
	UIGraphicsEndImageContext();
    
	IndexedLayer* layer = [[IndexedLayer alloc] init];
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
    posAni.removedOnCompletion = YES;
    posAni.delegate = delegate;
    l.position = pos;
    [l addAnimation:posAni forKey:@"position"];
    
    return posAni;
}

- (CABasicAnimation*)_changeOpacityOfCellLayer:(CALayer*)l to:(CGFloat)opacity delegate:(id)delegate  {
    CABasicAnimation *alphaAni = [CABasicAnimation animationWithKeyPath:@"opacity"];
    alphaAni.duration = CLIP_ANI_DURATION;
    alphaAni.fromValue = [l valueForKey:@"opacity"];
    alphaAni.toValue = [NSNumber numberWithFloat:opacity];
    alphaAni.delegate = delegate;
    l.opacity = opacity;
    [l addAnimation:alphaAni forKey:@"opacity"];
    
    return alphaAni;
}

- (void)_animateChangeAfterIndex:(NSUInteger)start {

	CALayer* scrollViewLayer = self.scrollView.layer;
    CellAniLayer* aniLayer = [CellAniLayer layer];
    CGRect bounds = scrollViewLayer.bounds;
    CGPoint baseOffset = bounds.origin;

    aniLayer.frame = bounds;
    aniLayer.delegate = self;

	NSMutableArray* layers = [[NSMutableArray alloc] initWithCapacity:_visibleCells.count*2];
	NSMutableArray* newLineLayers =  [[NSMutableArray alloc] initWithCapacity:_visibleCells.count/_numberOfColumns];

	// create layers for cell at current position
    for( VUIGridCellView* c in _visibleCells ) {
    	// create layer for each cell
        NSUInteger cellIndex = c.index;
        if( NSNotFound == cellIndex || cellIndex >= start ) {
            IndexedLayer* layer = [self _newLayerForCell:c offset:baseOffset];
            [layers addObject:layer];
            [layer release];
            // hide dumped cell
            c.hidden = YES;
        }
    }
    
    // calculate new positions
    [self _layoutCells];

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
        	if( l.cellIndex == cellIndex ) {
       	        [aniLayer addSublayer:l];
               	CGRect originFrame = l.frame;
                CGFloat originY = originFrame.origin.y;
                CGFloat destY = destFrame.origin.y;
                if( IS_PIXEL_COORDINATE_CHANGED(originY, destY) ) {
                	// not at the same row now
                    // dump a layer to the new row
                    IndexedLayer* newLayer = [[IndexedLayer alloc] init];
                    newLayer.cellIndex = l.cellIndex;
                    newLayer.anchorPoint = CGPointZero;
                    newLayer.contentsScale = l.contentsScale;
                    newLayer.contents = l.contents;
                    newLayer.anchorPoint = CGPointMake(0,0);
                    
                    CGRect frame = destFrame;
                    CGFloat cw = frame.size.width;
                    frame.origin.x += ( destY < originY ? cw : -cw );
                    newLayer.frame = frame;
                    
//                    DLog(@"Add cell for new line at frame %@", NSStringFromCGRect(frame));

                	[newLineLayers addObject:newLayer];
                    
                    [aniLayer addSublayer:newLayer];
                    
                    [newLayer release];
                } else if( !IS_DIFFERENT_FRAME(originFrame, destFrame) ) {
//                	DLog(@"Set opacity of the new cell to 0 at %@", NSStringFromCGRect(destFrame));
					if( cellIndex != NSNotFound ) {
                    	// this is a new cell
                        // hide it at first
                		l.opacity = 0;
                    }
                } else {
//                	DLog(@"Just move cell");
                }
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
                break;
            }
        }
    }
    
	// create layers for cell at current position
    for( VUIGridCellView* c in _visibleCells ) {
    	// create layer for each cell
        CGRect destFrame = c.frame;
        
        destFrame.origin.x -= baseOffset.x;
        destFrame.origin.y -= baseOffset.y;
        
        for( IndexedLayer* l in layers ) {
        	
            NSUInteger i = l.cellIndex;
        	
        	if( i == c.index ) {
				CGRect originFrame = l.frame;
                CGFloat originY = originFrame.origin.y;
                CGFloat destY = destFrame.origin.y;
                if( IS_PIXEL_COORDINATE_CHANGED(originY, destY) ) {
                	// move the the right and disppear
					CGRect frame = originFrame;
                    CGFloat cw = frame.size.width;
                    frame.origin.x += ( destY < originY ? -cw : cw );
//                    DLog(@"Move & hide cell from %@ to %@", NSStringFromCGRect(originFrame) , NSStringFromCGRect(frame));
                    CABasicAnimation* posAni = [self _moveCellLayer:l toPositionWithAni:frame.origin delegate:aniLayer];
                    CABasicAnimation* alphaAni = [self _changeOpacityOfCellLayer:l to:0 delegate:aniLayer];
                    
                    posAni.timingFunction = outFunc;
	                alphaAni.timingFunction = outFunc;
                    
                } else if( !IS_DIFFERENT_FRAME(originFrame, destFrame) ) {
	                
//                    DLog(@"Reveal the cell");
                    if( i != NSNotFound ) {
	                    CABasicAnimation* alphaAni = [self _changeOpacityOfCellLayer:l to:1 delegate:aniLayer];
	                	alphaAni.beginTime = CLIP_ANI_DURATION;
                    } else {
	                    [self _changeOpacityOfCellLayer:l to:0 delegate:aniLayer];
                    }
                    
                } else {
                
//                	DLog(@"Move cell from %@ to %@ ", NSStringFromCGRect(originFrame) , NSStringFromCGRect(destFrame));
                    [self _moveCellLayer:l toPositionWithAni:destFrame.origin delegate:aniLayer];
                }
                break;
            }
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
    aniLayer.delegate = self;
    
    NSMutableSet* removedCells = nil;
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];

	// create layers for cell at current position
    for( VUIGridCellView* c in _visibleCells ) {
    	// create layer for each cell
        NSUInteger cellIndex = c.index;
        if( NSNotFound == cellIndex || cellIndex == index ) {
            IndexedLayer* layer = [self _newLayerForCell:c offset:baseOffset];
            [aniLayer addSublayer:layer];
            [layer release];
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
        [self _changeOpacityOfCellLayer:l to:opacity delegate:aniLayer].beginTime = delay;
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
	            NSUInteger cellIndex = c.index;
                for( IndexedLayer* l in layer.sublayers ) {
					if( l.cellIndex == cellIndex ) {
                    	c.hidden = NO;
                    }
                }
            }
        }
        [layer removeFromSuperlayer];

    });


}

@end
 