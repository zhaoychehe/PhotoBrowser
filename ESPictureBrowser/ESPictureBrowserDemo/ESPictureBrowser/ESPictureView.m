//
// MIT License
//
// Copyright (c) 2016 EnjoySR <https://github.com/EnjoySR/ESPictureBrowser>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#import "ESPictureView.h"
#import "ESPictureProgressView.h"
#import <YYWebImage/YYWebImage.h>
#import "UIView+Expand.h"

@interface ESPictureView()<UIScrollViewDelegate, UIGestureRecognizerDelegate>

// 实际图片大小
@property (nonatomic, assign) CGSize showPictureSize;
// 是否是双击大图模式
@property (nonatomic, assign) BOOL doubleClicks;
// 最后滚动的位置
@property (nonatomic, assign) CGPoint lastContentOffset;

@property (nonatomic, assign) CGFloat scale;

@property (nonatomic, assign) CGFloat offsetY;

@property (nonatomic, weak) ESPictureProgressView *progressView;

@property (nonatomic, assign, getter=isShowAnim) BOOL showAnim;

@property (nonatomic, assign) CGFloat screenW;
@property (nonatomic, assign) CGFloat screenH;

// 是否是拖动图片
@property (nonatomic, assign, getter=isPanEnabled) BOOL panEnabled;
// 拖动图片最后Y值
@property (nonatomic, assign) CGFloat lastPanY;

@end

@implementation ESPictureView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.screenW = [UIScreen mainScreen].bounds.size.width;
    self.screenH = [UIScreen mainScreen].bounds.size.height;
    
    self.delegate = self;
    self.alwaysBounceVertical = true;
    self.backgroundColor = [UIColor clearColor];
    self.showsHorizontalScrollIndicator = false;
    self.showsVerticalScrollIndicator = false;
    self.maximumZoomScale = 2;
    
    // 添加 imageView
    YYAnimatedImageView *imageView = [[YYAnimatedImageView alloc] init];
    imageView.clipsToBounds = true;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.frame = self.bounds;
    imageView.userInteractionEnabled = true;
    _imageView = imageView;
    [self addSubview:imageView];
    
    // 添加进度view
    ESPictureProgressView *progressView = [[ESPictureProgressView alloc] init];
    [self addSubview:progressView];
    self.progressView = progressView;
    
    // 添加监听事件
    UITapGestureRecognizer *doubleTapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleClick:)];
    doubleTapGes.numberOfTapsRequired = 2;
    [imageView addGestureRecognizer:doubleTapGes];
    
//    UIPanGestureRecognizer *panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panEvent:)];
//    panGes.delegate = self;
//    [imageView addGestureRecognizer:panGes];
}

#pragma mark - 外部方法
// 动画显示
- (void)animationShowWithFromRect:(CGRect)rect animationBlock:(void (^)())animationBlock completionBlock:(void (^)())completionBlock {
    self.imageView.frame = rect;
    self.showAnim = true;
    [self.progressView setHidden:true];
    [UIView animateWithDuration:0.25 animations:^{
        if (animationBlock != nil) {
            animationBlock();
        }
        // 调整图片展示位置
        self.imageView.frame = [self getImageActualFrame:self.showPictureSize];
    } completion:^(BOOL finished) {
        if (finished) {
            if (completionBlock) {
                completionBlock();
            }
        }
        self.showAnim = false;
    }];
}
// 动画取消
- (void)animationDismissWithToRect:(CGRect)rect animationBlock:(void (^)())animationBlock completionBlock:(void (^)())completionBlock {
    
    // 隐藏进度视图
    self.progressView.hidden = true;
    [UIView animateWithDuration:0.25 animations:^{
        if (animationBlock) {
            animationBlock();
        }
        CGRect toRect = rect;
        toRect.origin.y += self.offsetY;
        // 这一句话用于在放大的时候去关闭
        toRect.origin.x += self.contentOffset.x;
        self.imageView.frame = toRect;
    } completion:^(BOOL finished) {
        if (finished) {
            if (completionBlock) {
                completionBlock();
            }
        }
    }];
}

#pragma mark - 私有方法

- (void)layoutSubviews {
    [super layoutSubviews];
    self.progressView.center = CGPointMake(self.frame.size.width * 0.5, self.frame.size.height * 0.5);
}

- (void)setShowAnim:(BOOL)showAnim {
    _showAnim = showAnim;
    if (showAnim == true) {
        self.progressView.hidden = true;
    }else {
        self.progressView.hidden = self.progressView.progress == 1;
    }
}

- (void)setUrlString:(NSString *)urlString {
    _urlString = urlString;
    [self.imageView yy_cancelCurrentImageRequest];
    self.progressView.progress = 0.01;
    // 如果没有在执行动画，那么就显示出来
    if (self.isShowAnim == false) {
        // 显示出来
        self.progressView.hidden = false;
    }
    // 取消上一次的下载
    self.userInteractionEnabled = false;
    [self.imageView yy_setImageWithURL:[NSURL URLWithString:urlString] placeholder:self.placeholderImage options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        CGFloat progress = (CGFloat)receivedSize / expectedSize ;
        self.progressView.progress = progress;
    } transform:nil completion:^(UIImage * _Nullable image, NSURL * _Nonnull url, YYWebImageFromType from, YYWebImageStage stage, NSError * _Nullable error) {
        if (error != nil) {
            [self.progressView showError];
        }else {
            if (stage == YYWebImageStageFinished) {
                self.progressView.hidden = true;
                self.userInteractionEnabled = true;
                if (image != nil) {
                    // 计算图片的大小
                    [self setPictureSize:image.size];
                }else {
                    [self.progressView showError];
                }
                // 当下载完毕设置为1，因为如果直接走缓存的话，是不会走进度的 block 的
                // 解决在执行动画完毕之后根据值去判断是否要隐藏
                // 在执行显示的动画过程中：进度视图要隐藏，而如果在这个时候没有下载完成，需要在动画执行完毕之后显示出来
                self.progressView.progress = 1;
            }
        }
    }];
}

- (void)setContentSize:(CGSize)contentSize {
    [super setContentSize:contentSize];
    // 暂时不知道啥用
//    if (self.zoomScale == 1) {
//        [UIView animateWithDuration:0.25 animations:^{
//            CGPoint center = self.imageView.center;
//            center.x = self.contentSize.width * 0.5;
//            self.imageView.center = center;
//        }];
//    }
}

- (void)setLastContentOffset:(CGPoint)lastContentOffset {
    // 如果用户没有在拖动，并且绽放比 > 0.15
    if (!(self.dragging == false && self.scale > 0.15)) {
        _lastContentOffset = lastContentOffset;
    }
}
// 图片大小
- (void)setPictureSize:(CGSize)pictureSize {
    _pictureSize = pictureSize;
    if (CGSizeEqualToSize(pictureSize, CGSizeZero)) {
        return;
    }
    // 计算实际的大小
    CGFloat scale = self.screenW / pictureSize.width;
    CGFloat height = scale * pictureSize.height;
    self.showPictureSize = CGSizeMake(self.screenW, height);
}
// 计算实际的大小
- (void)setShowPictureSize:(CGSize)showPictureSize {
    _showPictureSize = showPictureSize;
    self.imageView.frame = [self getImageActualFrame:showPictureSize];
    self.contentSize = self.imageView.frame.size;
}
// 调整图片展示位置
- (CGRect)getImageActualFrame:(CGSize)imageSize {
    CGFloat x = 0;
    CGFloat y = 0;
    
    if (imageSize.height < self.screenH) {
        y = (self.screenH - imageSize.height) / 2;
    }
    return CGRectMake(x, y, imageSize.width, imageSize.height);
}
// 计算图片放大缩小后位置
- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center{
    CGRect zoomRect;
    zoomRect.size.height = self.frame.size.height / scale;
    zoomRect.size.width  = self.frame.size.width  / scale;
    zoomRect.origin.x = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0);
    return zoomRect;
}

#pragma mark - 监听方法
- (void)doubleClick:(UITapGestureRecognizer *)ges {
    CGFloat newScale = 2;
    if (self.doubleClicks) {
        newScale = 1;
    }
    CGRect zoomRect = [self zoomRectForScale:newScale withCenter:[ges locationInView:ges.view]];
    [self zoomToRect:zoomRect animated:YES];
    self.doubleClicks = !self.doubleClicks;
}

- (void)panEvent:(UIPanGestureRecognizer *)recognizer
{
    CGPoint translation = [recognizer translationInView:self];
    CGPoint newCenter = CGPointMake(recognizer.view.center.x + translation.x,
                                    recognizer.view.center.y + translation.y);
    
    if (newCenter.y > self.screenH*0.5) {
        // 向下移动
        CGFloat mvY = newCenter.y - self.screenH*0.5;
        CGFloat zoom = mvY / (self.screenH*0.5)*0.5;
        CGRect zoomRect = [self zoomRectForScale:zoom withCenter:CGPointMake(self.screenW*0.5, self.screenH*0.5)];
        [self zoomToRect:zoomRect animated:YES];
    }else {
        // 限制屏幕范围：
        newCenter.y = MAX(recognizer.view.frame.size.height/2, newCenter.y);
        newCenter.y = MIN(self.frame.size.height - recognizer.view.frame.size.height/2,  newCenter.y);
        newCenter.x = MAX(recognizer.view.frame.size.width/2, newCenter.x);
        newCenter.x = MIN(self.frame.size.width - recognizer.view.frame.size.width/2,newCenter.x);
    }
    recognizer.view.center = newCenter;
    [recognizer setTranslation:CGPointZero inView:self];
    
//    if ((recognizer.state == UIGestureRecognizerStateEnded) || (recognizer.state == UIGestureRecognizerStateCancelled)) {
//        if (newCenter.y > self.screenH*0.5) {
//            // 向下移动
//            
//        }else {
//            // 还原
//            [UIView animateWithDuration:0.25 animations:^{
//                recognizer.view.center = CGPointMake(self.screenW*0.5, self.screenH*0.5);
//            }];
//        }
//    }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    self.lastContentOffset = scrollView.contentOffset;
    // 保存 offsetY
    self.offsetY = scrollView.contentOffset.y;
    // 正在动画
    if ([self.imageView.layer animationForKey:@"transform"] != nil) {
        return;
    }
    // 用户正在缩放
    if (self.zoomBouncing || self.zooming) {
        return;
    }
    
    // 滑动到中间 图片超出屏幕的范围
    if (scrollView.contentSize.height > self.screenH) {
        // 代表没有滑动到底部
        if (self.lastContentOffset.y > 0 && self.lastContentOffset.y <= scrollView.contentSize.height - self.screenH) {
            return;
        }
    }
    self.scale = fabs(self.lastContentOffset.y) / self.screenH;
    
    // 如果内容高度 > 屏幕高度
    // 并且偏移量 > 内容高度 - 屏幕高度
    // 那么就代表滑动到最底部了
    if (scrollView.contentSize.height > self.screenH &&
        self.lastContentOffset.y > scrollView.contentSize.height - self.screenH) {
        self.scale = (self.lastContentOffset.y - (scrollView.contentSize.height - self.screenH)) / self.screenH;
    }
    
    // 条件1：拖动到顶部再继续往下拖
    // 条件2：拖动到顶部再继续往上拖
    // 两个条件都满足才去设置 scale -> 针对于长图
    if (scrollView.contentSize.height > self.screenH) {
        // 长图
        if (scrollView.contentOffset.y < 0 || self.lastContentOffset.y > scrollView.contentSize.height - self.screenH) {
            if ([self.pictureDelegate respondsToSelector:@selector(pictureView:scale:)]) {
                [self.pictureDelegate pictureView:self scale:self.scale];
            }
        }
    }else {
        if ([self.pictureDelegate respondsToSelector:@selector(pictureView:scale:)]) {
            [self.pictureDelegate pictureView:self scale:self.scale];
        }
    }
    
    // 如果用户松手
    if (scrollView.dragging == false) {
        if (self.scale > 0.15 && self.scale <= 1) {
            // 关闭
            if ([self.pictureDelegate respondsToSelector:@selector(pictureViewTouch:)]) {
                [self.pictureDelegate pictureViewTouch:self];
            }
            // 设置 contentOffset
            [scrollView setContentOffset:self.lastContentOffset animated:false];
        }
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    CGPoint center = self.imageView.center;
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height) ? (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    center.y = scrollView.contentSize.height * 0.5 + offsetY;
    self.imageView.center = center;
    
    // 如果是缩小，保证在屏幕中间
    if (scrollView.zoomScale < scrollView.minimumZoomScale) {
        CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width) ? (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
        center.x = scrollView.contentSize.width * 0.5 + offsetX;
        self.imageView.center = center;
    }
}

#pragma mark - 手势代理
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    if ([gestureRecognizer.view isMemberOfClass:[YYAnimatedImageView class]]) {
        if (gestureRecognizer.view.centerY == self.screenH*0.5) {
            return YES;
        }else {
            return NO;
        }
    }
    return NO;
}

@end
