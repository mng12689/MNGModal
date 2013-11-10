//
//  MNGModalWindowManager.m
//  MNGModal
//
//  Created by Paperless Post on 10/31/13.
//
//

#import "MNGModalManager.h"
#import "MNGModalProtocol.h"
#import "MNGModalLayer.h"

@interface MNGModalManager () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *dimmingView;
@property (nonatomic, strong) NSMutableArray *modalLayerStack;

@end

@implementation MNGModalManager

static MNGModalManager *_manager = nil;

#pragma mark - singleton accessor methods
+ (MNGModalManager *)manager
{
    @synchronized([MNGModalManager class])
    {
        if (!_manager) {
            _manager = [[self alloc] init];
        }
        return _manager;
    }
    return nil;
}

+ (id)alloc{
    @synchronized([MNGModalManager class]){
        NSAssert(_manager == nil, @"Attempted to allocate a second instance of singleton");
        _manager = [super alloc];
        return _manager;
    }
    return nil;
}

#pragma mark - lazy loaders
- (UIView *)dimmingView
{
    if (!_dimmingView) {
        UIWindow *mainWindow = [[UIApplication sharedApplication].delegate window];
        _dimmingView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, mainWindow.bounds.size.width, mainWindow.bounds.size.height)];
        _dimmingView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _dimmingView.backgroundColor = [UIColor clearColor];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapGestureDetected:)];
        tap.delegate = self;
        [_dimmingView addGestureRecognizer:tap];
        [mainWindow addSubview:_dimmingView];
    }
    return _dimmingView;
}

- (NSMutableArray *)modalLayerStack
{
    if (!_modalLayerStack) {
        _modalLayerStack = [NSMutableArray new];
    }
    return _modalLayerStack;
}

#pragma mark - modal layer stack methods
- (void)pushModalLayer:(MNGModalLayer *)layer
{
    [self.modalLayerStack addObject:layer];
}

- (MNGModalLayer *)popModalLayer
{
    MNGModalLayer *layer = [self topModalLayer];
    if (layer) {
        [self.modalLayerStack removeLastObject];
    }
    return layer;
}

- (MNGModalLayer *)topModalLayer
{
    return [self.modalLayerStack lastObject];
}

#pragma mark - modal presentation and dismissal methods
-(void)presentViewController:(UIViewController *)presentedViewController fromViewController:(UIViewController *)presentingViewController frame:(CGRect)frame options:(MNGModalViewControllerOptions)options completion:(void (^)(void))completion delegate:(id<MNGModalProtocol>)delegate
{
    MNGModalLayer *topLayer = [self topModalLayer];
    if (topLayer.presentingViewController == presentingViewController) {
        NSLog(@"WARNING: A modal view controller is already being presented from the current view controller.");
        return;
    }
    
    MNGModalLayer *layer = [MNGModalLayer layerWithPresentingViewController:presentingViewController presentedViewController:presentedViewController options:options delegate:delegate];
    [self pushModalLayer:layer];
    
    UIView *dimmingView = self.dimmingView;
    UIColor *dimmedColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
    
    CGRect startFrame = frame;
    NSInteger equalityTest =  (7 << 2) & options;
    
    if (equalityTest == MNGModalAnimationSlideFromBottom) {
        startFrame.origin.y = dimmingView.frame.size.height;
    }else if (equalityTest == MNGModalAnimationSlideFromTop) {
        startFrame.origin.y = dimmingView.frame.origin.y-presentedViewController.view.frame.size.height;
    }else if (equalityTest == MNGModalAnimationSlideFromRight) {
        startFrame.origin.x = dimmingView.frame.size.width;
    }else if (equalityTest == MNGModalAnimationSlideFromLeft) {
        startFrame.origin.x = dimmingView.frame.origin.x-presentedViewController.view.frame.size.width;
    }
    presentedViewController.view.frame = startFrame;
    
    CGFloat viewFinalAlpha = presentedViewController.view.alpha;
    if (equalityTest == MNGModalAnimationFade) {
        presentedViewController.view.alpha = 0;
    }
    
    [dimmingView addSubview:presentedViewController.view];
    [presentedViewController.view didMoveToSuperview];
    
    void(^animationsBlock)() = ^() {
        if (options & MNGModalAnimationShouldDarken) {
            dimmingView.backgroundColor = dimmedColor;
        }
        presentedViewController.view.frame = frame;
        presentedViewController.view.alpha = viewFinalAlpha;
    };
    
    if (equalityTest == MNGModalAnimationNone) {
        animationsBlock();
    }else{
        [UIView animateWithDuration:0.4f animations:^{
            animationsBlock();
        } completion:^(BOOL finished) {
            if (completion) {
                completion();
            }
        }];
    }
}

- (void)dismissModalViewControllerWithCompletion:(void (^)(void))completion
{
    MNGModalLayer *layer = [self popModalLayer];
    if (!layer) {
        NSLog(@"WARNING: There is no modal view controller currently presented to dismiss.");
        return;
    }
    
    MNGModalViewControllerOptions options = layer.options;
    UIViewController *presentedViewController = layer.presentedViewController;
    
    CGRect endFrame = presentedViewController.view.frame;
    NSInteger equalityTest =  (7 << 2) & options;
    
    if (equalityTest == MNGModalAnimationSlideFromBottom) {
        endFrame.origin.y = self.dimmingView.frame.size.height;
    }else if (equalityTest == MNGModalAnimationSlideFromTop) {
        endFrame.origin.y = self.dimmingView.frame.origin.y-presentedViewController.view.frame.size.height;
    }else if (equalityTest == MNGModalAnimationSlideFromRight) {
        endFrame.origin.x = self.dimmingView.frame.size.width;
    }else if (equalityTest == MNGModalAnimationSlideFromLeft) {
        endFrame.origin.x = self.dimmingView.frame.origin.x-presentedViewController.view.frame.size.width;
    }
    
    void(^animationsBlock)() = ^() {
        if (options & MNGModalAnimationShouldDarken) {
            UIView *dimmingView = [[MNGModalManager manager] dimmingView];
            dimmingView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0];
        }
        if (equalityTest == MNGModalAnimationFade) {
            presentedViewController.view.alpha = 0;
        }
        presentedViewController.view.frame = endFrame;
    };
    void(^completionBlock)() = ^() {
        [presentedViewController.view willMoveToSuperview:nil];
        [presentedViewController.view removeFromSuperview];
        [presentedViewController.view didMoveToSuperview];
        
        if (![self topModalLayer]) {
            [self.dimmingView removeFromSuperview];
            self.dimmingView = nil;
        }
        if (completion) {
            completion();
        }
    };
    
    if (equalityTest == MNGModalAnimationNone) {
        animationsBlock();
        completionBlock();
    }else{
        [UIView animateWithDuration:0.4f animations:^{
            animationsBlock();
        } completion:^(BOOL finished) {
            completionBlock();
        }];
    }
}

#pragma mark - protocol forwarding
- (void)tapGestureDetected:(UITapGestureRecognizer *)tapGestureRecognizer
{
    MNGModalLayer *topLayer = [self topModalLayer];
    if ([topLayer.delegate respondsToSelector:@selector(tapDetectedOutsideModal:)]) {
        [topLayer.delegate tapDetectedOutsideModal:tapGestureRecognizer];
    }
}

#pragma mark - Tap Gesture delegate methods
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    UIView *view = [self.dimmingView hitTest:[touch locationInView:self.dimmingView] withEvent:nil];
    return view == self.dimmingView ? YES : NO;
}

@end
