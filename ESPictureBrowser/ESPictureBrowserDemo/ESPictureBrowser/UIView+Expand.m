//
//  UIView+Expand.m
//  MyProject
//
//  Created by 毕珂 on 15/11/15.
//  Copyright © 2015年 BIKE. All rights reserved.
//

#import "UIView+Expand.h"

@implementation UIView (Expand)

-(void)setX:(CGFloat)x
{
    self.frame = CGRectMake(x, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
}

-(CGFloat)x
{
    return self.frame.origin.x;
}

-(void)setY:(CGFloat)y
{
    self.frame = CGRectMake(self.frame.origin.x, y, self.frame.size.width, self.frame.size.height);
}


-(CGFloat)y
{
    return self.frame.origin.y;
}

-(void)setWidth:(CGFloat)width
{
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, width, self.frame.size.height);
}
-(CGFloat)width
{
    return self.frame.size.width;
}

-(void)setHeight:(CGFloat)height
{
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, height);
}

-(CGFloat)height
{
    return self.frame.size.height;
}

-(void)setCenterX:(CGFloat)centerX
{
    CGPoint point = self.center;
    point.x = centerX;
    self.center = point;
}

-(CGFloat)centerX
{
    return self.center.x;
}

-(void)setCenterY:(CGFloat)centerY
{
    CGPoint point = self.center;
    point.y = centerY;
    self.center = point;
}

-(CGFloat)centerY
{
    return self.center.y;
}

- (CGFloat)right
{
    return CGRectGetMaxX(self.frame);
}

- (CGFloat)bottom
{
    return CGRectGetMaxY(self.frame);
}

- (void)setRight:(CGFloat)right
{
    self.x = right - self.width;
}

- (void)setBottom:(CGFloat)bottom
{
    self.y = bottom - self.height;
}
- (CGSize)size
{
    return self.frame.size;
}

- (void)setSize:(CGSize)size
{
    CGRect tempFrame = self.frame;
    tempFrame.size = size;
    self.frame = tempFrame;
}

-(void)cutRadius:(CGFloat)radius
{
    UIBezierPath * path = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:radius];
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = path.CGPath;
    maskLayer.frame = self.bounds;
    self.layer.mask = maskLayer;
}

-(void)addRoundBorderWithColor:(UIColor*)color lineWidth:(CGFloat)lineWidth radius:(CGFloat)radius
{
    UIBezierPath * path = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:radius];
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = path.CGPath;
    maskLayer.frame = self.bounds;
    self.layer.mask = maskLayer;
    
    CAShapeLayer * borderLayer = [CAShapeLayer layer];
    borderLayer.path = path.CGPath;
    borderLayer.borderWidth = lineWidth;
    borderLayer.strokeColor = color.CGColor;
    borderLayer.fillColor = [UIColor clearColor].CGColor;
    [self.layer addSublayer:borderLayer];
}



@end
