//
//  PullRefreshView.m
//  PullRefresh
//
//  Created by Shen Slavik on 11/25/12.
//  Copyright (c) 2012 Shen Slavik. All rights reserved.
//

#import "VUIGVPullRefreshView.h"
#import <QuartzCore/QuartzCore.h>
#import "VUIGridView.h"

#define INDENT_R 2
#define DROP_R 3
#define MIN_R 13

@interface VUIGVPullRefreshView()

@property(nonatomic,assign) CGFloat rotate;

- (void)_refreshPath;

@end

@implementation VUIGVPullRefreshView {

    CAShapeLayer* _balloon;
    CAShapeLayer* _tail;
    CAShapeLayer* _reload;

    CATextLayer* _text;

}

@dynamic title;

- (void)_layoutSubViews {

    CGSize size = self.frame.size;

    CGFloat W = size.width;
    CGFloat H = size.height;

    CGFloat midX = W/10;
    CGFloat midY = H/2;
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    CATransform3D t = _reload.transform;
    BOOL transformed = !CATransform3DIsIdentity(t);
    if( transformed ) {
        _reload.transform = CATransform3DIdentity;
    }
    
    CGRect frame = _reload.frame;
    frame.origin.x = floorf(midX -frame.size.width/2);
    frame.origin.y = floorf(midY -frame.size.height/2);
    
    _reload.frame = frame;
    
    if( transformed ) {
        _reload.transform = t;
    }
    
    CGFloat right = ceilf(midX+H/2)+5;
    CGFloat top = frame.origin.y;
    CGRect textFrame = CGRectMake(right, top, W-right, H );
    _text.frame = textFrame;
    
    [CATransaction commit];
    
}

- (void)_setup {

    self.backgroundColor = [UIColor clearColor];
    
    _balloon = [CAShapeLayer layer];
    _tail = [CAShapeLayer layer];
    _tail.hidden = YES;
    
    _reload = [CALayer layer];
    UIImage* icon = [UIImage imageNamed:@"icn_pull_reload"];
    CGFloat scale = icon.scale;
    _reload.contentsScale = scale;
    _reload.contents = (id)icon.CGImage;
    _reload.contentsGravity = kCAGravityCenter;
    
    CGRect frame = CGRectMake(0, 0, icon.size.width, icon.size.height);
    _reload.frame = frame;
    
    _text = [CATextLayer layer];
    _text.wrapped = YES;
    _text.fontSize = 18;
    _text.foregroundColor = [[UIColor darkGrayColor] CGColor];
    _text.contentsScale = scale;
    _text.alignmentMode = kCAAlignmentJustified;
    
    CALayer* layer = self.layer;
    
    [layer addSublayer:_tail];
    [layer addSublayer:_balloon];
    [layer addSublayer:_reload];
    [layer addSublayer:_text];
    
    [self _layoutSubViews];
    
    self.tint = [UIColor colorWithHue:0.1f saturation:0.1f brightness:0.7f alpha:1];

}

- (void)dealloc {

    self.activeAnimation = NO;
    self.tint = nil;
    [super dealloc];
    
}

- (void)setTint:(UIColor *)tint {

    if( [_tint isEqual:tint] ) { return; }
    
    [_tint release];
    _tint = [tint retain];
    
    if( _tint ) {
        _balloon.fillColor = _tint.CGColor;
        _tail.fillColor = _tint.CGColor;
    }

}

- (void)setTitle:(NSString *)title {
    if( ![title isEqualToString:_text.string] ) {
        _text.string = title;
    }
}

- (NSString*)title {
    return _text.string;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    [self _setup];
    return self;
}

- (void)setFrame:(CGRect)frame {

    CGSize prevSize = self.frame.size;
    [super setFrame:frame];
    CGSize size = self.frame.size;
    
    if( IS_SIZE_CHANGED(prevSize, size) ) {
        [self _layoutSubViews];
    }

}

- (void)layoutSublayersOfLayer:(CALayer *)layer {

    [super layoutSublayersOfLayer:layer];

    if( layer == self.layer ) {
        [self _refreshPath];
    }

}

- (void)setTailLength:(CGFloat)tailLength {

    _tailLength = tailLength;
    
    if( _tailLength > 0 ) {
        if( !_activeAnimation ) {
            _tail.hidden = NO;
        }
    } else {
        _tail.hidden = YES;
        self.rotate = 0;
    }
    
    [self _refreshPath];

}

- (void)_refreshPath {

    CGRect bounds = self.bounds;
    CGFloat W = bounds.size.width;
    CGFloat H = bounds.size.height;
    
    CGFloat midX = W/10;
    CGFloat midY = H/2;
    
    CGFloat baseR = MIN(W,H)/2-INDENT_R;
    
    CGFloat R = baseR - _tailLength*0.2f;
    
    if( R < MIN_R ) {
        R = MIN_R;
    }
    
    CGPoint center = CGPointMake(midX, midY);
    
    UIBezierPath* ball = [UIBezierPath bezierPathWithArcCenter:center radius:R startAngle:0 endAngle:M_PI*2 clockwise:NO];
    _balloon.path = ball.CGPath;

    
    CGFloat leftX = midX - R;
    CGFloat rightX = midX + R;
    
    CGFloat bottomY = midY + _tailLength;
    CGFloat rate = R/baseR;
    CGFloat DR = DROP_R*rate;
    
    CGPoint left = CGPointMake(leftX, midY);
    CGPoint right = CGPointMake(rightX, midY);
    CGPoint leftB = CGPointMake(midX-DR, bottomY-DR*2);
    CGPoint rightB = CGPointMake(midX+DR, bottomY-DR*2);
    
    CGPoint CLeft1 = left;
    CLeft1.x += 5; //+10*(1-rate);
    CLeft1.y += 10;
    CGPoint CLeft2 = leftB;
    CLeft2.x -= 10;
    CLeft2.y -= 10;
    
    CGPoint CRight1 = right;
    CRight1.x -= 5; //+10*(1-rate);
    CRight1.y += 10;
    CGPoint CRight2 = rightB;
    CRight2.x += 10;
    CRight2.y -= 10;
    
    UIBezierPath* tail = [UIBezierPath new];
    
    [tail moveToPoint:left];
    [tail addCurveToPoint:leftB controlPoint1:CLeft1 controlPoint2:CLeft2];
    
    [tail addQuadCurveToPoint:rightB controlPoint:CGPointMake(midX, bottomY-DR)];
    
    [tail addCurveToPoint:right controlPoint1:CRight2 controlPoint2:CRight1];
    
    [tail closePath];
    
    _tail.path = tail.CGPath;
    [tail release];
    
    if( !_activeAnimation ) {
    
        CGFloat round = _tailLength/(8*R);
        CGFloat rotate = round*M_PI;
        while( rotate < 0 ) {
            rotate += M_PI*2;
        }
        while( rotate > M_PI*2 ) {
            rotate -= M_PI*2;
        }

        self.rotate = rotate;
        
    }

}

- (void)setRotate:(CGFloat)rotate {

    _rotate = rotate;
    if( !_activeAnimation ) {
        if( 0 == _rotate ) {
            _reload.transform = CATransform3DIdentity;  
        } else {
            _reload.transform = CATransform3DMakeRotation(_rotate, 0, 0, 1);
        }
    }

}

#define ROTATION_STEP_DURATION (0.15f)

- (void)setActiveAnimation:(BOOL)flag {

    if( _activeAnimation != flag ) {
    
        if( _activeAnimation ) {
            [_reload removeAnimationForKey:@"transform"];
            [_balloon removeAnimationForKey:@"path"];
        }
        
        _activeAnimation = flag;
        
        if( _activeAnimation ) {
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            _tail.hidden = YES;
            [CATransaction commit];
            {
                CATransform3D t0 = CATransform3DMakeRotation(_rotate, 0, 0, 1);
                CATransform3D t1 = CATransform3DMakeRotation(_rotate+(M_PI*2)/3, 0, 0, 1);
                CATransform3D t2 = CATransform3DMakeRotation(_rotate+2*(M_PI*2)/3, 0, 0, 1);
                
                NSArray* values  = @[
                    [NSValue valueWithCATransform3D:t0],
                    [NSValue valueWithCATransform3D:t1],
                    [NSValue valueWithCATransform3D:t2],
                    [NSValue valueWithCATransform3D:t0],
                ];
                
                CAKeyframeAnimation* ani = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
                ani.values = values;
                ani.duration = 0.3f;
                ani.repeatCount = HUGE_VALF;
                ani.removedOnCompletion = NO;
                ani.fillMode = kCAFillModeForwards;
                
                ani.timingFunctions = @[
                    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut],
                    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
                ];
                
                [_reload addAnimation:ani forKey:@"transform"];
            }
            {
                CGRect bounds = self.bounds;
                CGFloat W = bounds.size.width;
                CGFloat H = bounds.size.height;
                
                CGFloat midX = W/10;
                CGFloat midY = H/2;
                
                CGPoint center = CGPointMake(midX, midY);
                
                UIBezierPath* ball0 = [UIBezierPath bezierPathWithArcCenter:center radius:MIN_R*1.2f startAngle:0 endAngle:M_PI*2 clockwise:NO];
                UIBezierPath* ball1 = [UIBezierPath bezierPathWithArcCenter:center radius:MIN_R startAngle:0 endAngle:M_PI*2 clockwise:NO];
                
                NSArray* values = @[
                    (id)ball0.CGPath,
                    (id)ball1.CGPath,
                    (id)ball0.CGPath
                ];
                
                CAKeyframeAnimation* ani = [CAKeyframeAnimation animationWithKeyPath:@"path"];
                ani.values = values;
                ani.duration = 0.6f;
                ani.repeatCount = HUGE_VALF;
                ani.removedOnCompletion = NO;
                ani.fillMode = kCAFillModeForwards;
                
                ani.timingFunctions = @[
                    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut],
                    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
                ];
                
                [_balloon addAnimation:ani forKey:@"path"];                
            }
        }
    }

}


@end
