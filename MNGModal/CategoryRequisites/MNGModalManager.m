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
        _dimmingView = [UIView new];
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
    
    UIWindow *mainWindow = [[UIApplication sharedApplication].delegate window];
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
        dimmingView.frame = CGRectMake(0, dimmingYOrigin, mainWindow.bounds.size.width, mainWindow.bounds.size.height-dimmingYOrigin);
    }
    
    CGRect startFrame = frame;
    NSUInteger animationOption =  (7 << 2) & options;
    
    if (animationOption == MNGModalAnimationSlideFromBottom) {
        startFrame.origin.y = [UIScreen mainScreen].bounds.size.height;
    }else if (animationOption == MNGModalAnimationSlideFromTop) {
        startFrame.origin.y = -presentedViewController.view.frame.size.height;
    }else if (animationOption == MNGModalAnimationSlideFromRight) {
        startFrame.origin.x = [UIScreen mainScreen].bounds.size.width;
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
    [mainWindow addSubview:presentedViewController.view];
    
    void(^animationsBlock)() = ^() {
        if (options & MNGModalOptionShouldDarken) {
            dimmingView.backgroundColor = dimmedColor;
        }
        dimmingView.frame = CGRectMake(0, dimmingYOrigin, mainWindow.bounds.size.width, mainWindow.bounds.size.height-dimmingYOrigin);
        
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
    
    UIWindow *mainWindow = [[UIApplication sharedApplication].delegate window];
    MNGModalViewControllerOptions options = layer.options;
    UIViewController *presentedViewController = layer.presentedViewController;
    
    CGRect endFrame = presentedViewController.view.frame;
    NSUInteger animationOption =  (7 << 2) & options;
    
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
    
    void(^animationsBlock)() = ^() {
        if (shouldRemoveDim) {
            self.dimmingView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0];
        }
        self.dimmingView.frame = CGRectMake(0, dimmingYOrigin, mainWindow.bounds.size.width, mainWindow.bounds.size.height-dimmingYOrigin);
        if (animationOption == MNGModalAnimationFade) {
            presentedViewController.view.alpha = 0;
        }
        presentedViewController.view.frame = endFrame;
    };
    void(^completionBlock)() = ^() {
        [presentedViewController.view removeFromSuperview];
        
        if (![self peekModalLayer]) {
            [self.dimmingView removeFromSuperview];
            self.dimmingView = nil;
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
    UIView *view = [self.dimmingView hitTest:[touch locationInView:self.dimmingView] withEvent:nil];
    return view == self.dimmingView ? YES : NO;
}

@end
