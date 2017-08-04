//
//  UIView+Expand.h
//  MyProject
//
//  Created by 毕珂 on 15/11/15.
//  Copyright © 2015年 BIKE. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Expand)

//X
@property (nonatomic,assign) CGFloat x;
//Y
@property (nonatomic,assign) CGFloat y;
//宽
@property (nonatomic,assign) CGFloat width;
//高
@property (nonatomic,assign) CGFloat height;
//CenterX
@property (nonatomic,assign) CGFloat centerX;
//CenterY
@property (nonatomic,assign) CGFloat centerY;
// maxX
@property (nonatomic,assign) CGFloat right;
// maxY
@property (nonatomic,assign) CGFloat bottom;
// size
@property (nonatomic, assign)CGSize size;

-(void)cutRadius:(CGFloat)radius;

-(void)addRoundBorderWithColor:(UIColor*)color lineWidth:(CGFloat)lineWidth radius:(CGFloat)radius;




@end
