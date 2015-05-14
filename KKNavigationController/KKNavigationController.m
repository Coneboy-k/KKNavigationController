//
//  KKNavigationController.m
//  TS
//
//  Created by Coneboy_K on 13-12-2.
//  Copyright (c) 2013年 Coneboy_K. All rights reserved.  MIT
//  WELCOME TO MY BLOG  http://www.coneboy.com
//

#import "KKNavigationController.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

@interface KKNavigationController ()
{
    CGPoint startTouch;
    
    UIImageView *lastScreenShotView;
    UIView *blackMask;
    
}

@property (nonatomic,retain) UIView *backgroundView;
@property (nonatomic,retain) NSMutableArray *screenShotsList;

@property (nonatomic,assign) BOOL isMoving;

@end

@implementation KKNavigationController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        self.screenShotsList = [[NSMutableArray alloc]initWithCapacity:2];
        self.canDragBack = YES;
        
    }
    return self;
}

- (void)dealloc
{
    self.screenShotsList = nil;
    
    [self.backgroundView removeFromSuperview];
    self.backgroundView = nil;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImageView *shadowImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"leftside_shadow_bg"]];
    shadowImageView.frame = CGRectMake(-10, 0, 10, self.view.frame.size.height);
    [self.view addSubview:shadowImageView];
    
    UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self
                                                                                action:@selector(paningGestureReceive:)];
    [recognizer setDelegate:self];
    [recognizer delaysTouchesBegan];
    [self.view addGestureRecognizer:recognizer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self.screenShotsList addObject:[self capture]];
    
    [super pushViewController:viewController animated:animated];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    [self.screenShotsList removeLastObject];
    
    return [super popViewControllerAnimated:animated];
}

- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated{
    NSInteger index = [self.viewControllers indexOfObject:viewController];
    if (index != NSNotFound) {
        [self.screenShotsList removeObjectsInRange:NSMakeRange(index + 1, self.viewControllers.count - index - 1)];
    }
    return [super popToViewController:viewController animated:animated];
}

#pragma mark - Utility Methods -

- (UIImage *)capture
{
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, self.view.opaque, 0.0);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

- (void)moveViewWithX:(float)x
{
    x = x>self.view.bounds.size.width?self.view.bounds.size.width:x;
    x = x<0?0:x;
    
    CGRect frame = self.view.frame;
    frame.origin.x = x;
    self.view.frame = frame;
    
    float alpha = 0.4 - (x/800);
    
    blackMask.alpha = alpha;
    
    CGFloat aa = abs(startBackViewX)/kkBackViewWidth;
    CGFloat y = x*aa;
    
    UIImage *lastScreenShot = [self.screenShotsList lastObject];
    CGFloat lastScreenShotViewHeight = lastScreenShot.size.height;
    CGFloat superviewHeight = lastScreenShotView.superview.frame.size.height;
    CGFloat verticalPos = superviewHeight - lastScreenShotViewHeight;
    
    [lastScreenShotView setFrame:CGRectMake(startBackViewX+y,
                                            verticalPos,
                                            kkBackViewWidth,
                                            lastScreenShotViewHeight)];
}



-(BOOL)isBlurryImg:(CGFloat)tmp
{
    return YES;
}

#pragma mark - Gesture Recognizer -
//不响应的手势则传递下去
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (self.viewControllers.count <= 1 || !self.canDragBack){
        return NO;
    }
    return YES;
}


- (void)paningGestureReceive:(UIPanGestureRecognizer *)recoginzer
{
    if (self.viewControllers.count <= 1 || !self.canDragBack) return;
    
    CGPoint touchPoint = [recoginzer locationInView:KEY_WINDOW];
    
    if (recoginzer.state == UIGestureRecognizerStateBegan) {
        
        _isMoving = YES;
        startTouch = touchPoint;
        
        if (!self.backgroundView)
        {
            CGRect frame = self.view.frame;
            
            self.backgroundView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, frame.size.width , frame.size.height)];
            [self.view.superview insertSubview:self.backgroundView belowSubview:self.view];
            
            blackMask = [[UIView alloc]initWithFrame:CGRectMake(0, 0, frame.size.width , frame.size.height)];
            blackMask.backgroundColor = [UIColor blackColor];
            [self.backgroundView addSubview:blackMask];
        }
        
        self.backgroundView.hidden = NO;
        
        if (lastScreenShotView) [lastScreenShotView removeFromSuperview];
        
        
        UIImage *lastScreenShot = [self.screenShotsList lastObject];
        
        lastScreenShotView = [[UIImageView alloc]initWithImage:lastScreenShot];
        
        startBackViewX = startX;
        [lastScreenShotView setFrame:CGRectMake(startBackViewX,
                                                lastScreenShotView.frame.origin.y,
                                                lastScreenShotView.frame.size.height,
                                                lastScreenShotView.frame.size.width)];
        
        [self.backgroundView insertSubview:lastScreenShotView belowSubview:blackMask];
        
    }else if (recoginzer.state == UIGestureRecognizerStateEnded || recoginzer.state == UIGestureRecognizerStateCancelled){
        [self _panGestureRecognizerDidFinish:recoginzer];
    } else if (recoginzer.state == UIGestureRecognizerStateChanged) {
        
        if (_isMoving) {
            [self moveViewWithX:touchPoint.x - startTouch.x];
        }
    }
    
}

// 当手势结束的时候，会根据当前滑动的速度，以及当前的位置综合去计算将要移动到的位置。这样用户操作起来感觉比较自然，不然产生的情况就是，假设我移动的速度很快，但是停下来的时候没有滑动到某个位置，导致我还是不能返回。这个可以参考iOS7原生UINavigationController的效果，或者参考STKit中提供的STNavigationController的效果
//https://github.com/lovesunstar/stkitdemo/blob/master/STKitDemo/Classes/STKit.framework/Headers/STNavigationController.h
- (void)_panGestureRecognizerDidFinish:(UIPanGestureRecognizer *)panGestureRecognizer {
    // 这里应该用navigationController.view.width， 这里由于整个项目都是这样，就不做改动了
    CGFloat navigationWidth = CGRectGetWidth(KEY_WINDOW.bounds);
    
    // 获取手指离开时候的速度
    CGFloat velocityX = [panGestureRecognizer velocityInView:KEY_WINDOW].x;
    CGPoint translation = [panGestureRecognizer translationInView:KEY_WINDOW];
    // 这里的targetX是根据scrollView松手时候猜想的，这个可以动态的稍微调整一下。
    CGFloat tempTargetX = MIN(MAX(translation.x + (velocityX * 0.2), 0), navigationWidth);
    CGFloat gestureTargetX = (tempTargetX + translation.x) / 2;
    // 当前push/pop完成的百分比,根据这个百分比，可以计算得到剩余动画的时间。像现在存在一个BUG，比如我稍微移动了一下，然后返回，这个时候也是按照0.3s就不太合适
    CGFloat completionPercent = gestureTargetX / navigationWidth;
    CGFloat moveTargetX = 0;
    CGFloat duration;
    BOOL finishPop = NO;
    if (gestureTargetX > navigationWidth * 0.6) {
        // 需要pop, pop的总时间是0.3, 完成了percent,还剩余1-percent
        duration = 0.3 * (1.0 - completionPercent);
        moveTargetX = navigationWidth;
        finishPop = YES;
    } else {
        //        再push回去,如果已经pop了百分之percent,则时间就是completionPercent *0.3
        duration = completionPercent * 0.3;
    }
    duration = MAX(MIN(duration, 0.3), 0.01);
    void (^completion)(BOOL) = ^(BOOL finished) {
        _isMoving = NO;
        if (finishPop) {
            [self popViewControllerAnimated:NO];
            CGRect frame = self.view.frame;
            frame.origin.x = 0;
            self.view.frame = frame;
        } else {
            self.backgroundView.hidden = YES;
        }
    };
    [UIView animateWithDuration:duration animations:^{
        [self moveViewWithX:finishPop ? navigationWidth : 0];
    } completion:completion];
}

@end





