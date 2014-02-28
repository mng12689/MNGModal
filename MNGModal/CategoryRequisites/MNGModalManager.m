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
#import "UIViewController+TopLayoutGuide.h"

@interface MNGModalManager () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *rootView;
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
            [[NSNotificationCenter defaultCenter] addObserver:_manager selector:@selector(orientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:_manager name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

#pragma mark - lazy loaders
- (UIView *)dimmingView
{
    if (!_dimmingView) {
        _dimmingView = [UIView new];
        _dimmingView.backgroundColor = [UIColor clearColor];
        _dimmingView.clipsToBounds = YES;
        [self.rootView addSubview:_dimmingView];
    }
    return _dimmingView;
}

- (UIView *)rootView
{
    if (!_rootView) {
        UIWindow *mainWindow = [[UIApplication sharedApplication].delegate window];
        _rootView = [[UIView alloc] initWithFrame:mainWindow.bounds];
        _rootView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _rootView.backgroundColor = [UIColor clearColor];
        _rootView.clipsToBounds = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapGestureDetected:)];
        tap.delegate = self;
        [_rootView addGestureRecognizer:tap];
        [MNGModalManager setOrientationForView:_rootView animated:NO];
        [mainWindow addSubview:_rootView];
    }
    return _rootView;
}

- (NSMutableArray *)modalLayerStack
{
    if (!_modalLayerStack) {
        _modalLayerStack = [NSMutableArray new];
    }
    return _modalLayerStack;
}

#pragma mark - layer info
- (UIViewController *)MNGPresentedViewController
{
    return [[self peekModalLayer] presentedViewController];
}

#pragma mark - overriden getters
- (UIViewController *)originalPresentingViewController
{
    // need this reference to determine where the nav bar is
    return [[self.modalLayerStack firstObject] presentingViewController];
}

#pragma mark - modal layer stack methods
- (void)pushModalLayer:(MNGModalLayer *)layer
{
    [self.modalLayerStack addObject:layer];
}

- (MNGModalLayer *)popModalLayer
{
    MNGModalLayer *layer = [self peekModalLayer];
    if (layer) {
        [self.modalLayerStack removeObject:layer];
    }
    return layer;
}

- (MNGModalLayer *)peekModalLayer
{
    return [self.modalLayerStack lastObject];
}

#pragma mark - modal presentation and dismissal methods
- (void)presentViewController:(UIViewController *)presentedViewController
           fromViewController:(UIViewController *)presentingViewController
                        frame:(CGRect)frame
                      options:(MNGModalViewControllerOptions)options
                   completion:(void (^)(void))completion
                     delegate:(id<MNGModalProtocol>)delegate
{
    MNGModalLayer *topLayer = [self peekModalLayer];
    if (topLayer.presentingViewController == presentingViewController) {
        NSLog(@"WARNING: A modal view controller is already being presented from the current view controller.");
        return;
    }
    
    UIColor *dimmedColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
    UIView *dimmingView = self.dimmingView;
    
    CGFloat dimmingYOrigin = 0;
    if (options & MNGModalOptionShouldNotCoverNavigationBar) {
        
        // MNGModalOptionShouldNotCoverNavigationBar option should be ignored if a modal layer behind this one already covers the nav bar
        BOOL navAlreadyCovered = NO;
        for (MNGModalLayer *layer in self.modalLayerStack) {
            if (!(layer.options & MNGModalOptionShouldNotCoverNavigationBar)){
                navAlreadyCovered = YES;
                break;
            }
        }
        if (!navAlreadyCovered) {
            UIViewController *originalPresentingVC = [self originalPresentingViewController] ? : presentingViewController;
            dimmingYOrigin = originalPresentingVC.navigationController ? [originalPresentingVC safety_topLayoutGuideLength] : 0;
        }
    }
    
    // we dont want to animate the frame of the dimming view for the first modal, so we set it before the animation block
    if (!topLayer) {
        dimmingView.frame = CGRectMake(0, dimmingYOrigin, self.rootView.bounds.size.width, self.rootView.bounds.size.height-dimmingYOrigin);
    }
    
    if (options & MNGModalOptionAllowUserInteractionWithBackground) {
        BOOL userInteractionEnabled = NO;
        for (MNGModalLayer *layer in self.modalLayerStack) {
            if (!(layer.options & MNGModalOptionAllowUserInteractionWithBackground)) {
                userInteractionEnabled = YES;
                break;
            }
        }
        dimmingView.userInteractionEnabled = userInteractionEnabled;
        self.rootView.userInteractionEnabled = userInteractionEnabled;
    }
    
    CGRect startFrame = frame;
    NSUInteger animationOption =  (7 << 4) & options;
    
    if (animationOption == MNGModalAnimationSlideFromBottom) {
        startFrame.origin.y = self.rootView.frame.size.height;
    }else if (animationOption == MNGModalAnimationSlideFromTop) {
        startFrame.origin.y = -presentedViewController.view.frame.size.height;
    }else if (animationOption == MNGModalAnimationSlideFromRight) {
        startFrame.origin.x = self.rootView.frame.size.width;
        startFrame.origin.y += dimmingYOrigin;
    }else if (animationOption == MNGModalAnimationSlideFromLeft) {
        startFrame.origin.x = -presentedViewController.view.frame.size.width;
        startFrame.origin.y += dimmingYOrigin;
    }else if (animationOption == MNGModalAnimationFade){
        startFrame.origin.y += dimmingYOrigin;
    }
    presentedViewController.view.frame = startFrame;
    
    CGFloat viewFinalAlpha = presentedViewController.view.alpha;
    if (animationOption == MNGModalAnimationFade) {
        presentedViewController.view.alpha = 0;
    }
    
    MNGModalLayer *layer = [MNGModalLayer layerWithPresentingViewController:presentingViewController
                                                    presentedViewController:presentedViewController
                                                                    options:options
                                                                   delegate:delegate];
    [self pushModalLayer:layer];
    [self.rootView addSubview:presentedViewController.view];
    
    void(^animationsBlock)() = ^() {
        if (options & MNGModalOptionShouldDarken) {
            dimmingView.backgroundColor = dimmedColor;
        }
        dimmingView.frame = CGRectMake(0, dimmingYOrigin, self.rootView.bounds.size.width, self.rootView.bounds.size.height-dimmingYOrigin);
        
        CGRect presentedVCFrame = frame;
        presentedVCFrame.origin.y += dimmingYOrigin;
        presentedViewController.view.frame = presentedVCFrame;
        
        presentedViewController.view.alpha = viewFinalAlpha;
    };
    
    if (animationOption == MNGModalAnimationNone) {
        animationsBlock();
        if (completion) {
            completion();
        }
    }else{
        [UIView animateWithDuration:0.4f
                         animations:animationsBlock
                         completion:^(BOOL finished) {
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
    NSUInteger animationOption =  (7 << 4) & options;
    
    if (animationOption == MNGModalAnimationSlideFromBottom) {
        endFrame.origin.y = [UIScreen mainScreen].bounds.size.height;
    }else if (animationOption == MNGModalAnimationSlideFromTop) {
        endFrame.origin.y = -presentedViewController.view.frame.size.height;
    }else if (animationOption == MNGModalAnimationSlideFromRight) {
        endFrame.origin.x = [UIScreen mainScreen].bounds.size.width;
    }else if (animationOption == MNGModalAnimationSlideFromLeft) {
        endFrame.origin.x = -presentedViewController.view.frame.size.width;
    }
    
    BOOL shouldCoverNavBar = NO;
    for (MNGModalLayer *layer in self.modalLayerStack) {
        if (!(layer.options & MNGModalOptionShouldNotCoverNavigationBar)){
            shouldCoverNavBar = YES;
            break;
        }
    }
    
    NSInteger dimmingYOrigin = self.dimmingView.frame.origin.y;
    if ([self peekModalLayer] && !shouldCoverNavBar) {
        dimmingYOrigin = [self originalPresentingViewController].navigationController ? [[self originalPresentingViewController] safety_topLayoutGuideLength] : 0;
    }
    
    BOOL shouldRemoveDim = YES;
    for (MNGModalLayer *layer in self.modalLayerStack) {
        if (layer.options & MNGModalOptionShouldDarken){
            shouldRemoveDim = NO;
            break;
        }
    }
    
    if (options & MNGModalOptionAllowUserInteractionWithBackground) {
        BOOL userInteractionEnabled = NO;
        for (MNGModalLayer *layer in self.modalLayerStack) {
            if (layer.options & MNGModalOptionAllowUserInteractionWithBackground) {
                userInteractionEnabled = YES;
                break;
            }
        }
        self.dimmingView.userInteractionEnabled = userInteractionEnabled;
    }
    
    void(^animationsBlock)() = ^() {
        if (shouldRemoveDim) {
            self.dimmingView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0];
        }
        self.dimmingView.frame = CGRectMake(0, dimmingYOrigin, self.rootView.bounds.size.width, self.rootView.bounds.size.height-dimmingYOrigin);
        if (animationOption == MNGModalAnimationFade) {
            presentedViewController.view.alpha = 0;
        }
        presentedViewController.view.frame = endFrame;
    };
    
    NSInteger originalAlpha = presentedViewController.view.alpha;
    void(^completionBlock)() = ^() {
        [presentedViewController.view removeFromSuperview];
        presentedViewController.view.alpha = originalAlpha;
        if (![self peekModalLayer]) {
            [self.dimmingView removeFromSuperview];
            self.dimmingView = nil;
            [self.rootView removeFromSuperview];
            self.rootView = nil;
        }
        if (completion) {
            completion();
        }
    };
    
    if (animationOption == MNGModalAnimationNone) {
        animationsBlock();
        completionBlock();
    }else{
        [UIView animateWithDuration:0.4f animations:animationsBlock
                         completion:^(BOOL finished) {
                             completionBlock();
                         }];
    }
}

#pragma mark - protocol forwarding
- (void)tapGestureDetected:(UITapGestureRecognizer *)tapGestureRecognizer
{
    MNGModalLayer *topLayer = [self peekModalLayer];
    if ([topLayer.delegate respondsToSelector:@selector(tapDetectedOutsideModal:)]) {
        [topLayer.delegate tapDetectedOutsideModal:tapGestureRecognizer];
    }
}

#pragma mark - Tap Gesture delegate methods
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    UIView *view = [self.rootView hitTest:[touch locationInView:self.rootView] withEvent:nil];
    return view == self.dimmingView ? YES : NO;
}

#pragma mark - Device orientation
- (void)orientationChanged:(NSNotification *)notification
{
    [MNGModalManager setOrientationForView:self.rootView animated:YES];
}

+ (void)setOrientationForView:(UIView *)view animated:(BOOL)animated
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGFloat angle = UIInterfaceOrientationAngleOfOrientation(orientation);
    
    CGAffineTransform transform = CGAffineTransformMakeRotation(angle);
    if (!animated) {
        view.transform = transform;
    } else {
        [UIView animateWithDuration:.3 animations:^{
            view.transform = transform;
        }];
    }
}

CGFloat UIInterfaceOrientationAngleOfOrientation(UIInterfaceOrientation orientation){
    switch (orientation){
        case UIInterfaceOrientationPortraitUpsideDown: return M_PI;
        case UIInterfaceOrientationLandscapeLeft: return -M_PI_2;
        case UIInterfaceOrientationLandscapeRight: return M_PI_2;
        default: return 0.0;
    }
}

@end
