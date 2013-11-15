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
    
    UIWindow *mainWindow = [[UIApplication sharedApplication].delegate window];
    UIColor *dimmedColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
    UIView *dimmingView = self.dimmingView;
    
    CGFloat dimmingYOrigin;
    // if modal being presented shouldnt cover nav bar, don't
    if (!(options & MNGModalOptionShouldNotCoverNavigationBar)) {
        dimmingYOrigin = 0;
    }else{
        // else if the modal current top modal should cover the nav bar, ignore the presentingVC not covering the nav bar since the
        // current top modal is covering it anyways
        if ([self topModalLayer] && !([[self topModalLayer] options] & MNGModalOptionShouldNotCoverNavigationBar)) {
            dimmingYOrigin = 0;
        }else{
            // if no modal in the stack has yet covered the nav bar, and the presentingVC doesn't want this modal to cover the
            // nav bar either, then take into account the nav bar when framing the dimming view
            dimmingYOrigin = presentingViewController.navigationController ? [[presentingViewController topLayoutGuide] length] : 0;
        }
    }
    // we dont want to animate the frame of the dimming view for the first modal, so we set it before the animation block
    if (![self topModalLayer]) {
        dimmingView.frame = CGRectMake(0, dimmingYOrigin, mainWindow.bounds.size.width, mainWindow.bounds.size.height-dimmingYOrigin);
    }
    
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
    
    [mainWindow addSubview:presentedViewController.view];
    [presentedViewController.view didMoveToSuperview];
    
    MNGModalLayer *layer = [MNGModalLayer layerWithPresentingViewController:presentingViewController presentedViewController:presentedViewController options:options delegate:delegate];
    [self pushModalLayer:layer];
    
    void(^animationsBlock)() = ^() {
        if (options & MNGModalOptionShouldDarken) {
            dimmingView.backgroundColor = dimmedColor;
        }
        dimmingView.frame = CGRectMake(0, dimmingYOrigin, mainWindow.bounds.size.width, mainWindow.bounds.size.height-dimmingYOrigin);

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
    
    UIWindow *mainWindow = [[UIApplication sharedApplication].delegate window];
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
    
    NSInteger dimmingYOrigin = self.dimmingView.frame.origin.y;
    if ([self topModalLayer] && [[self topModalLayer] options] & MNGModalOptionShouldNotCoverNavigationBar) {
        UIViewController *presentingVC = [[self topModalLayer] presentingViewController];
        dimmingYOrigin = presentingVC.navigationController ? [[presentingVC topLayoutGuide] length] : 0;
    }
    
    void(^animationsBlock)() = ^() {
        if (options & MNGModalOptionShouldDarken) {
            UIView *dimmingView = [[MNGModalManager manager] dimmingView];
            dimmingView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0];
        }
        self.dimmingView.frame = CGRectMake(0, dimmingYOrigin, mainWindow.bounds.size.width, mainWindow.bounds.size.height-dimmingYOrigin);
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
