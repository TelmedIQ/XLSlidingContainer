//
//  XLSlidingContainerViewController.m
//  XLForm ( https://github.com/xmartlabs/XLSlidingContainer )
//
//  Copyright (c) 2015 Xmartlabs ( http://xmartlabs.com )
//
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


#import "XLSlidingContainerViewController.h"

#define VEL_THRESHOLD 4000

@interface XLSlidingContainerViewController () <UIGestureRecognizerDelegate>

@property (nonatomic) IBOutlet UIView *dragView;
@property (nonatomic) UIView *upperView;
@property (nonatomic) UIView *lowerView;
@property (nonatomic) NSInteger panDirection;
@property (weak, nonatomic) IBOutlet UIView *navView;

@property (nonatomic) UIViewController <XLContainedViewVController> *lowerController;
@property (nonatomic) UIViewController <XLContainedViewVController> *upperController;

@end

@implementation XLSlidingContainerViewController
{
    BOOL _initialPositionSetUp;
    BOOL _isDragging;
    double _lastChange;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _initialPositionSetUp = NO;
    _isDragging = NO;
    
    if(!_dataSource)
        _dataSource = self;
    if(!_delegate)
        _delegate = self;

    [self addChildViewController:self.upperController];
    [self addChildViewController:self.lowerController];
    
    if (![self.upperView superview]){
        [self.navView addSubview:self.upperView];
    }
    if (![self.dragView superview]){
        [self.navView addSubview:self.dragView];
    }
    
    if (![self.lowerView superview]){
        [self.navView addSubview:self.lowerView];
    }
    
    [self.upperView addSubview:self.upperController.view];
    [self.lowerView addSubview:self.lowerController.view];
    
    [self.lowerController maximizedController:[self getMovementDifference]];
    [self.upperController minimizedController:[self getMovementDifference]];
    
    [self.lowerController didMoveToParentViewController:self];
    [self.upperController didMoveToParentViewController:self];
    
    UIPanGestureRecognizer* pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panDragView:)];
    pgr.delegate = self;
    [pgr setDelaysTouchesBegan:NO];
    [pgr setDelaysTouchesEnded:NO];
    [pgr setCancelsTouchesInView:NO];
    [self.navView addGestureRecognizer:pgr];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
}


-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if (!_initialPositionSetUp){
        _initialPositionSetUp = YES;
        [self drawViews];
    }
    self.lowerController.view.frame = [self frameForLowerController];
    self.upperController.view.frame = [self frameForUpperController];
    
}

#pragma mark - Getter and Setter

-(UIView *)navView{
    if(!_navView)
        return self.view;
    return _navView;
}

-(UIView *)upperView{
    if (_upperView) return _upperView;
    _upperView = [[UIView alloc] init];
    return _upperView;
}

-(UIView *)lowerView{
    if (_lowerView) return _lowerView;
    _lowerView = [[UIView alloc] init];
    return _lowerView;
}

-(UIView *)dragView
{
    if (_dragView) return _dragView;
    
    if ([self.dataSource respondsToSelector:@selector(getDragView)]){
        _dragView = [self.dataSource getDragView];
        if (_dragView)
            return _dragView;
    }
    
    _dragView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 42.0)];
    _dragView.backgroundColor = [UIColor darkGrayColor];
    
    return _dragView;
}

-(UIViewController *)lowerController{
    if(!_lowerController)
        _lowerController = [_dataSource getLowerControllerFor:self];
    return _lowerController;
}

-(UIViewController *)upperController{
    if (!_upperController)
        _upperController = [_dataSource getUpperControllerFor:self];;
    return _upperController;
}

#pragma mark - Helper functions

-(CGFloat)dragViewHeight{
    return CGRectGetHeight(self.dragView.frame);
}

-(CGFloat)getMovementDifference{
    return (CGRectGetHeight(self.navView.frame) - [self.delegate getUpperViewMinFor:self] - [self.delegate getLowerViewMinFor:self] - [self dragViewHeight] );
}

#pragma mark - Frame Management

-(void)drawViews{
    
    CGRect middle = CGRectMake(
                               0,
                               0,
                               self.navView.bounds.size.width,
                               [self dragViewHeight]
                               );
    self.dragView.frame = middle;
    
    CGRect upper = CGRectMake(0,
                              0,
                              self.navView.bounds.size.width,
                              (self.navView.bounds.size.height - [self.delegate getLowerViewMinFor:self] - [self dragViewHeight])
                              );
    self.upperView.frame = upper;
    
    CGRect lower = CGRectMake(0,
                              CGRectGetMaxY(middle),
                              self.navView.frame.size.width,
                              self.navView.frame.size.height - 50 + [self dragViewHeight] // 50 is hieght of input view on compose screen
                              );
                              
    self.lowerView.frame = lower;
    
    [self.view bringSubviewToFront:self.dragView];
}

-(CGRect) frameForLowerController{
    CGRect rect = CGRectMake(self.lowerView.bounds.origin.x, self.lowerView.bounds.origin.y, self.lowerView.bounds.size.width, self.lowerView.bounds.size.height);
    return rect;
}

-(CGRect) frameForUpperController{
    CGRect rect = CGRectMake(self.upperView.bounds.origin.x, self.upperView.bounds.origin.y, self.upperView.bounds.size.width, self.upperView.bounds.size.height);
    return rect;
}

-(void)updateViews:(CGPoint) translation forState:(UIGestureRecognizerState) state {
    
    CGRect f0 = self.dragView.frame;
    CGRect f1 = self.upperView.frame;
    CGRect f2 = self.lowerView.frame;
    
    if ([self.delegate getMovementTypeFor:self] == XLSlidingContainerMovementTypeHideUpperPushLower){
        if (state == UIGestureRecognizerStateEnded){
            if ((self.panDirection > 0) || ((self.panDirection == 0) && (self.dragView.frame.origin.y > 0.5*CGRectGetHeight(self.navView.frame)))){
                
                f2.size.height = [self.delegate getLowerViewMinFor:self];
                f2.origin.y = self.navView.frame.size.height - [self.delegate getLowerViewMinFor:self];
                
                f0.origin.y = f2.origin.y - f0.size.height;
                
                f1.size.height = f0.origin.y;
                
            }
            else {
                f1.size.height = [self.delegate getUpperViewMinFor:self];
                
                f0.origin.y = f1.origin.y + f1.size.height;
                
                f2.size.height = self.navView.bounds.size.height - f0.size.height - [self.delegate getUpperViewMinFor:self];
                f2.origin.y = f0.origin.y + f0.size.height;
            }
        
        }
        else{
        
            f1.size.height += translation.y;
            
            f0.origin.y += translation.y;
            
            f2.size.height -= translation.y;
            f2.origin.y += translation.y;

        }
    }
    else if ([self.delegate getMovementTypeFor:self] == XLSlidingContainerMovementTypePush){
        if (state == UIGestureRecognizerStateEnded){
            if ((self.panDirection > 0) || ((self.panDirection == 0) && (self.dragView.frame.origin.y > 0.5*CGRectGetHeight(self.navView.frame)))){
                
                f2.size.height = [self.delegate getLowerViewMinFor:self];
                f2.origin.y = self.navView.frame.size.height - [self.delegate getLowerViewMinFor:self];
                
                f0.origin.y = f2.origin.y - f0.size.height;
                
                f1.origin.y = 0;
                
            }
            else {
                f1.origin.y = [self.delegate getUpperViewMinFor:self] - f1.size.height;
                
                f0.origin.y = f1.origin.y + f1.size.height;
                
                f2.origin.y = f0.origin.y + f0.size.height;
                f2.size.height = self.navView.bounds.size.height - f0.size.height  - [self.delegate getUpperViewMinFor:self];
            }
            
        }
        else{
            
            f1.origin.y += translation.y;
            
            f0.origin.y += translation.y;
            
            f2.size.height -= translation.y;
            f2.origin.y += translation.y;
            
        }
    }
    self.lowerView.frame = f2;
    self.upperView.frame = f1;
    self.dragView.frame = f0;
    
    self.lowerController.view.frame = [self frameForLowerController];
    self.upperController.view.frame = [self frameForUpperController];

}

- (void)panDragView:(UIPanGestureRecognizer *)gr {
    CGPoint location = [gr locationInView:self.navView];
    CGRect frame = self.dragView.frame;
    
    if (gr.state == UIGestureRecognizerStateBegan){
        frame.origin.y = MAX(frame.origin.y - [self.delegate getupperExtraDraggableArea:self], 0);
        frame.size.height = frame.size.height + [self.delegate getLowerExtraDraggableArea:self] + [self.delegate getupperExtraDraggableArea:self];
    }
    
    if ( gr.state == UIGestureRecognizerStateChanged )
        _lastChange = CFAbsoluteTimeGetCurrent();
    
    CGPoint dy = [gr translationInView:self.navView];
    [gr setTranslation:CGPointZero inView:self.navView];
    
    
    if (CGRectContainsPoint(frame, location) == NO  && _isDragging == NO){
        // pan ousite drag area
        return;
    }
    else if (!_isDragging){
        _isDragging = YES;
        if ([self.delegate respondsToSelector:@selector(slidingContainerDidEndDrag:)]){
            [self.delegate slidingContainerDidEndDrag:self];
        }
    }
    

    
    XLSlidingContainerViewController* __weak weakself = self;
    
    if (gr.state == UIGestureRecognizerStateEnded)
    {
       
        double curTime = CFAbsoluteTimeGetCurrent();
        double timeElapsed = curTime - _lastChange;
        double velocity = ( ABS(self.panDirection) / timeElapsed );
        if ( velocity > VEL_THRESHOLD )
            velocity = VEL_THRESHOLD;
        double realVelocity = (velocity / VEL_THRESHOLD);
        (realVelocity < 0.1) ? realVelocity = 0.1 : realVelocity;
        
        _isDragging = NO;
        if ([self.delegate respondsToSelector:@selector(slidingContainerDidBeginDrag:)]){
            [self.delegate slidingContainerDidEndDrag:self];
        }
        CGFloat actualPos = self.lowerView.frame.origin.y;
        CGFloat lowerContDiff = (CGRectGetHeight(self.navView.frame) - [self.delegate getLowerViewMinFor:self] - actualPos);
        CGFloat upperContDiff = (actualPos - [self.delegate getUpperViewMinFor:self] - [self dragViewHeight]);
        if ((self.panDirection > 0) || ((self.panDirection == 0) && (self.dragView.frame.origin.y > 0.5*CGRectGetHeight(self.navView.frame)))){
            [UIView animateWithDuration:(0.9 - (realVelocity/2))  delay:0.0 usingSpringWithDamping:0.9 - (realVelocity/2) initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionAllowUserInteraction animations:^{
                
                [weakself updateViews:dy forState:gr.state];
                if ([weakself.lowerController respondsToSelector:@selector(minimizedController:)])
                    [weakself.lowerController minimizedController: lowerContDiff];
                if ([weakself.upperController respondsToSelector:@selector(maximizedController:)])
                    [weakself.upperController maximizedController: lowerContDiff];
                
            } completion:nil];
            
        }
        else{
            [UIView animateWithDuration:(0.9 - (realVelocity/2)) delay:0.0 usingSpringWithDamping:0.9 - (realVelocity/2) initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionAllowUserInteraction animations:^{
                
                [weakself updateViews:dy forState:gr.state];
                if ([weakself.upperController respondsToSelector:@selector(minimizedController:)])
                    [weakself.upperController minimizedController:upperContDiff];
                if ([weakself.lowerController respondsToSelector:@selector(maximizedController:)])
                    [weakself.lowerController maximizedController:upperContDiff];
                
            } completion:nil];
        }
        return;
    }
    
    
    if (dy.y > 0) {
        CGFloat xx = (self.navView.bounds.size.height - (self.lowerView.frame.origin.y + dy.y));
        if (xx <= [self.delegate getLowerViewMinFor:self])
            dy.y = self.navView.bounds.size.height - self.lowerView.frame.origin.y - [self.delegate getLowerViewMinFor:self];
    } else {
        if (self.upperView.frame.origin.y + self.upperView.frame.size.height + dy.y <= [self.delegate getUpperViewMinFor:self])
            dy.y = [self.delegate getUpperViewMinFor:self] - CGRectGetHeight(self.upperView.frame) - self.upperView.frame.origin.y;
    }
    [weakself updateViews:dy forState:gr.state];
    if ([weakself.upperController respondsToSelector:@selector(updateFrameForYPct: absolute:)]){
        CGFloat yPct = 100 * ((self.dragView.frame.origin.y - [self.delegate getUpperViewMinFor:self]) / (self.navView.bounds.size.height - [self.delegate getUpperViewMinFor:self] - [self.delegate getLowerViewMinFor:self] - [self dragViewHeight]));
        [weakself.upperController updateFrameForYPct:yPct absolute:dy.y];
        
    }
    if ([weakself.lowerController respondsToSelector:@selector(updateFrameForYPct:absolute:)]){
        CGFloat yPct = 100 - 100 * ((self.dragView.frame.origin.y - [self.delegate getUpperViewMinFor:self]) / (self.navView.bounds.size.height - [self.delegate getUpperViewMinFor:self] - [self.delegate getLowerViewMinFor:self] - [self dragViewHeight]));
        [weakself.lowerController updateFrameForYPct:yPct absolute:dy.y];
    }
    
    self.panDirection = dy.y;
}

#pragma mark - Reload functions

- (void) reloadLowerViewController
{
    if(self.lowerController){
        [self.lowerController willMoveToParentViewController:nil];
        [self.lowerController.view removeFromSuperview];
        [self.lowerController removeFromParentViewController];
        
        self.lowerController = [_dataSource getLowerControllerFor:self];
    
        [self addChildViewController:self.lowerController];
        [self.lowerView addSubview:self.lowerController.view];
        [self.lowerController didMoveToParentViewController:self];
        
        [self.lowerController minimizedController:[self getMovementDifference]];
    }
}

- (void) reloadUpperViewController{
    if(self.upperController)
    {
        [self.upperController willMoveToParentViewController:nil];
        [self.upperController.view removeFromSuperview];
        [self.upperController removeFromParentViewController];
        
        self.upperController = [_dataSource getUpperControllerFor:self];
        
        [self addChildViewController:self.upperController];
        [self.upperView addSubview:self.upperController.view];
        [self.upperController didMoveToParentViewController:self];
        
        [self.upperController maximizedController:[self getMovementDifference]];
    }
}

#pragma mark - XLSliderViewControllerDataSource

- (UIViewController *) getLowerControllerFor:(XLSlidingContainerViewController *)sliderViewController;
{
    NSAssert(NO, @"_dataSource must be set");
    return nil;
}

- (UIViewController *) getUpperControllerFor:(XLSlidingContainerViewController *)sliderViewController;
{
    NSAssert(NO, @"_dataSource must be set");
    return nil;
}

#pragma mark - XLSliderViewControllerDelegate

- (CGFloat) getUpperViewMinFor:(XLSlidingContainerViewController *)sliderViewController
{
    return ceil(CGRectGetHeight(self.navView.frame) / 5);
}

- (CGFloat) getLowerViewMinFor:(XLSlidingContainerViewController *)sliderViewController
{
    return ceil((CGRectGetHeight(self.navView.frame) - [self dragViewHeight]) / 4);
}

- (CGFloat) getLowerExtraDraggableArea:(XLSlidingContainerViewController *)sliderViewController
{
    return 0.f;
}

- (CGFloat) getupperExtraDraggableArea:(XLSlidingContainerViewController *)sliderViewController
{
    return 0.f;
}

-(XLSlidingContainerMovementType)getMovementTypeFor:(XLSlidingContainerViewController *)sliderViewController{
    return XLSlidingContainerMovementTypeHideUpperPushLower;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end
