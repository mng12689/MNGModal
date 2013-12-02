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
    MNGModalLayer *layer = [self peekModalLayer];
    if (layer) {
        [self.modalLayerStack removeLastObject];
    }
    return layer;
}

- (MNGModalLayer *)peekModalLayer
{
    return [self.modalLayerStack lastObject];
}

#pragma mark - modal presentation and dismissal methods
-(void)presentViewController:(UIViewController *)presentedViewController
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
    
    CGFloat dimmingYOrigin;
    // if modal being presented should cover nav bar, cover it
    if (!(options & MNGModalOptionShouldNotCoverNavigationBar)) {
        dimmingYOrigin = 0;
    }else{
        // else if the modal current top modal should cover the nav bar, ignore the presentingVC not covering the nav bar since the
        // current top modal is covering it anyways
        if ([self peekModalLayer] && !([[self peekModalLayer] options] & MNGModalOptionShouldNotCoverNavigationBar)) {
            dimmingYOrigin = 0;
        }else{
            // if no modal in the stack has yet covered the nav bar, and the presentingVC doesn't want this modal to cover the
            // nav bar either, then take into account the nav bar when framing the dimming view
            dimmingYOrigin = presentingViewController.navigationController ? [[presentingViewController topLayoutGuide] length] : 0;
        }
    }
    // we dont want to animate the frame of the dimming view for the first modal, so we set it before the animation block
    if (![self peekModalLayer]) {
        dimmingView.frame = CGRectMake(0, dimmingYOrigin, mainWindow.bounds.size.width, mainWindow.bounds.size.height-dimmingYOrigin);
    }
    
    CGRect startFrame = frame;
    NSInteger animationOption =  (7 << 2) & options;
    
    if (animationOption == MNGModalAnimationSlideFromBottom) {
        startFrame.origin.y = dimmingView.frame.size.height;
    }else if (animationOption == MNGModalAnimationSlideFromTop) {
        startFrame.origin.y = dimmingView.frame.origin.y-presentedViewController.view.frame.size.height;
    }else if (animationOption == MNGModalAnimationSlideFromRight) {
        startFrame.origin.x = dimmingView.frame.size.width;
    }else if (animationOption == MNGModalAnimationSlideFromLeft) {
        startFrame.origin.x = dimmingView.frame.origin.x-presentedViewController.view.frame.size.width;
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

        presentedViewController.view.frame = frame;
        presentedViewController.view.alpha = viewFinalAlpha;
    };
    
    if (animationOption == MNGModalAnimationNone) {
        animationsBlock();
        if (completion) {
            completion();
        }
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
    NSInteger animationOption =  (7 << 2) & options;
    
    if (animationOption == MNGModalAnimationSlideFromBottom) {
        endFrame.origin.y = self.dimmingView.frame.size.height;
    }else if (animationOption == MNGModalAnimationSlideFromTop) {
        endFrame.origin.y = self.dimmingView.frame.origin.y-presentedViewController.view.frame.size.height;
    }else if (animationOption == MNGModalAnimationSlideFromRight) {
        endFrame.origin.x = self.dimmingView.frame.size.width;
    }else if (animationOption == MNGModalAnimationSlideFromLeft) {
        endFrame.origin.x = self.dimmingView.frame.origin.x-presentedViewController.view.frame.size.width;
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
        UIViewController *presentingVC = [[self peekModalLayer] presentingViewController];
        dimmingYOrigin = presentingVC.navigationController ? [[presentingVC topLayoutGuide] length] : 0;
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
