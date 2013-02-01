//
//  VUIGridCellHightlightView.m
//  Youplay
//
//  Created by Shen Slavik on 12/13/12.
//  Copyright (c) 2012 apollobrowser.com. All rights reserved.
//

#import "VUIGridCellHightlightView.h"

@implementation VUIGridCellHightlightView


- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if( self ) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

#if TARGET_OS_IPHONE
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if( self ) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}
#endif

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    switch( _style ) {
        
        case VUIGridCellHighlightStyle_Windows3D:
        [self _drawWindows3D:rect];
        break;
        
        case VUIGridCellHighlightStyle_GradientBlue:
        [self _drawGradient:rect
                 startColor:[UIColor colorWithHue:0.56f saturation:0.8f brightness:0.7 alpha:1]
                   endColor:[UIColor colorWithHue:0.56f saturation:0.8f brightness:1 alpha:1]];
        break;
        
        case VUIGridCellHighlightStyle_GradientRed:
        [self _drawGradient:rect
                 startColor:[UIColor colorWithHue:0 saturation:0.8f brightness:0.7 alpha:1]
                   endColor:[UIColor colorWithHue:0 saturation:0.8f brightness:1 alpha:1]];
        break;

        case VUIGridCellHighlightStyle_GradientGreen:
        [self _drawGradient:rect
                 startColor:[UIColor colorWithHue:0.3f saturation:0.8f brightness:0.7 alpha:1]
                   endColor:[UIColor colorWithHue:0.3f saturation:0.8f brightness:1 alpha:1]];
        break;
        
        default:
        break;
    }
}

- (void)_drawGradient:(CGRect)rect startColor:(UIColor*)startColor endColor:(UIColor*)endColor {

    CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSaveGState(context);
	CGContextTranslateCTM(context, 0, 0 );
	CGContextScaleCTM(context, 1, 1);
	
	CGFloat l = rect.origin.x;
	CGFloat t = rect.origin.y;
	CGFloat w = rect.size.width;
	CGFloat h = rect.size.height;
    CGFloat b = t + h;
    CGFloat r = l + w;

    
    const CGFloat* startColorComp = CGColorGetComponents([startColor CGColor]);
	const CGFloat* endColorComp = CGColorGetComponents([endColor CGColor]);
	CGFloat colors [] = { 	
		startColorComp[0], startColorComp[1], startColorComp[2], startColorComp[3],
		endColorComp[0], endColorComp[1], endColorComp[2], endColorComp[3],
	};

	CGColorSpaceRef baseSpace = CGColorSpaceCreateDeviceRGB();
	CGGradientRef gradient = CGGradientCreateWithColorComponents(baseSpace, colors, NULL, 2);
	CGColorSpaceRelease(baseSpace), baseSpace = NULL;
	
	CGPoint startPoint = CGPointMake(0,t);
	CGPoint endPoint = CGPointMake(0,b);

	CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
	CGGradientRelease(gradient), gradient = NULL;
    
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:0 alpha:0.4f].CGColor);
    CGContextMoveToPoint( context, l, t );
    CGContextAddLineToPoint( context, l, b);
    CGContextMoveToPoint( context, r, t );
    CGContextAddLineToPoint( context, r, b );
    CGContextStrokePath(context);
    
    // gray
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:0.5f alpha:1].CGColor);
    CGContextMoveToPoint(context, l, b);
    CGContextAddLineToPoint(context, r, b);
    CGContextStrokePath(context);

    // dark 
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:0 alpha:1].CGColor);
    CGContextMoveToPoint(context, l, t);
    CGContextAddLineToPoint(context, r, t);
    CGContextStrokePath(context);
    
	CGContextRestoreGState(context);

}

- (void)_drawWindows3D:(CGRect)rect {

    CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSaveGState(context);
	CGContextTranslateCTM(context, 0, 0 );
	CGContextScaleCTM(context, 1, 1);
	
	CGFloat l = rect.origin.x;
	CGFloat t = rect.origin.y;
	CGFloat w = rect.size.width;
	CGFloat h = rect.size.height;
    CGFloat b = t + h;
    CGFloat r = l + w;

    CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:0 alpha:0.05f].CGColor );
    CGContextFillRect(context, rect);
    
    // gray
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:0 alpha:0.5].CGColor);
    CGContextMoveToPoint(context, r, t);
    CGContextAddLineToPoint(context, r, b);
    CGContextAddLineToPoint(context, l, b);
    CGContextStrokePath(context);
    
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:0 alpha:0.2].CGColor);
    CGContextMoveToPoint(context, r-1, t+1);
    CGContextAddLineToPoint(context, r-1, b-1);
    CGContextAddLineToPoint(context, l+1, b-1);
    CGContextStrokePath(context);
    
    // light
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:1 alpha:0.2f].CGColor);
    CGContextMoveToPoint(context, l, b);
    CGContextAddLineToPoint(context, r, b);
    CGContextStrokePath(context);

    // dark 
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:0 alpha:0.8f].CGColor);
    CGContextMoveToPoint(context, l, b);
    CGContextAddLineToPoint(context, l, t);
    CGContextAddLineToPoint(context, r, t);
    CGContextStrokePath(context);


    CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:0 alpha:0.5f].CGColor);
    CGContextMoveToPoint(context, l+1, b-1);
    CGContextAddLineToPoint(context, l+1, t+1);
    CGContextAddLineToPoint(context, r-1, t+1);
    CGContextStrokePath(context);

	CGContextRestoreGState(context);
}

@end
