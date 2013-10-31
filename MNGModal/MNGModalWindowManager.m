//
//  MNGModalWindowManager.m
//  MNGModal
//
//  Created by Paperless Post on 10/31/13.
//
//

#import "MNGModalWindowManager.h"

@interface MNGModalWindowManager ()

@property (nonatomic, strong) UIWindow *modalWindow;
@property (nonatomic, strong) UIView *dimmingView;

@property (nonatomic, strong) UIViewController *viewControllerToPresent;
@property (nonatomic, assign) MNGModalViewControllerOptions options;

@end

@implementation MNGModalWindowManager

static MNGModalWindowManager *_manager = nil;

#pragma mark - singleton accessor methods
+ (MNGModalWindowManager *)manager
{
    @synchronized([MNGModalWindowManager class])
    {
        if (!_manager) {
            _manager = [[self alloc] init];
        }
        return _manager;
    }
    return nil;
}

+ (id)alloc{
    @synchronized([MNGModalWindowManager class]){
        NSAssert(_manager == nil, @"Attempted to allocate a second instance of singleton");
        _manager = [super alloc];
        return _manager;
    }
    return nil;
}

#pragma mark - lazy loaders
- (UIWindow *)modalWindow
{
    if (!_modalWindow) {
        _modalWindow = [UIWindow new];
        _modalWindow.windowLevel = UIWindowLevelStatusBar;
        
        UIViewController *rootViewController = [UIViewController new];
        _modalWindow.rootViewController = rootViewController;
    }
    return _modalWindow;
}

- (UIView *)dimmingView
{
    if (!_dimmingView) {
        _dimmingView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.modalWindow.rootViewController.view.bounds.size.width, self.modalWindow.rootViewController.view.bounds.size.height)];
        _dimmingView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _dimmingView.backgroundColor = [UIColor clearColor];
        [self.modalWindow.rootViewController.view addSubview:_dimmingView];
    }
    return _dimmingView;
}

#pragma mark - modal presentation and dismissal methods
-(void)presentViewController:(UIViewController *)viewControllerToPresent frame:(CGRect)frame options:(MNGModalViewControllerOptions)options completion:(void (^)(void))completion
{
    if (self.viewControllerToPresent) {
        NSLog(@"WARNING: A modal view controller is already being presented from the current view controller.");
        return;
    }
    
    self.options = options;
    self.viewControllerToPresent = viewControllerToPresent;
    
    UIWindow *modalWindow = self.modalWindow;
    UIViewController *rootViewController = modalWindow.rootViewController;
    
    UIView *dimmingView = self.dimmingView;
    if (options & MNGModalAnimationShouldDarken) {
        dimmingView.backgroundColor = [UIColor clearColor];
    }
    
    CGRect startFrame = frame;
    NSInteger equalityTest =  (7 << 2) & options;
    
    if (equalityTest == MNGModalAnimationSlideFromBottom) {
        startFrame.origin.y = rootViewController.view.frame.size.height;
    }else if (equalityTest == MNGModalAnimationSlideFromTop) {
        startFrame.origin.y = rootViewController.view.frame.origin.y-viewControllerToPresent.view.frame.size.height;
    }else if (equalityTest == MNGModalAnimationSlideFromRight) {
        startFrame.origin.x = rootViewController.view.frame.size.width;
    }else if (equalityTest == MNGModalAnimationSlideFromLeft) {
        startFrame.origin.x = rootViewController.view.frame.origin.x-viewControllerToPresent.view.frame.size.width;
    }
    viewControllerToPresent.view.frame = startFrame;
    
    CGFloat viewFinalAlpha = viewControllerToPresent.view.alpha;
    if (equalityTest == MNGModalAnimationFade) {
        viewControllerToPresent.view.alpha = 0;
    }
    
    [viewControllerToPresent willMoveToParentViewController:rootViewController];
    [rootViewController addChildViewController:viewControllerToPresent];
    [viewControllerToPresent didMoveToParentViewController:rootViewController];
    
    [viewControllerToPresent.view willMoveToSuperview:rootViewController.view];
    [rootViewController.view addSubview:viewControllerToPresent.view];
    [viewControllerToPresent.view didMoveToSuperview];
    
    [modalWindow makeKeyAndVisible];
    
    void(^animationsBlock)() = ^() {
        if (options & MNGModalAnimationShouldDarken) {
            dimmingView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
        }
        viewControllerToPresent.view.frame = frame;
        viewControllerToPresent.view.alpha = viewFinalAlpha;
    };
    
    if (equalityTest == MNGModalAnimationNone) {
        animationsBlock();
    }else{
        [UIView animateWithDuration:0.5f animations:^{
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
    UIWindow *window = self.modalWindow;
    UIViewController *rootViewController = window.rootViewController;
    
    MNGModalViewControllerOptions options = self.options;
    UIViewController *presentedViewController = self.viewControllerToPresent;
    
    CGRect endFrame = presentedViewController.view.frame;
    NSInteger equalityTest =  (7 << 2) & options;
    
    if (equalityTest == MNGModalAnimationSlideFromBottom) {
        endFrame.origin.y = rootViewController.view.frame.size.height;
    }else if (equalityTest == MNGModalAnimationSlideFromTop) {
        endFrame.origin.y = rootViewController.view.frame.origin.y-presentedViewController.view.frame.size.height;
    }else if (equalityTest == MNGModalAnimationSlideFromRight) {
        endFrame.origin.x = rootViewController.view.frame.size.width;
    }else if (equalityTest == MNGModalAnimationSlideFromLeft) {
        endFrame.origin.x = rootViewController.view.frame.origin.x-presentedViewController.view.frame.size.width;
    }
    
    void(^animationsBlock)() = ^() {
        if (options & MNGModalAnimationShouldDarken) {
            UIView *dimmingView = [[MNGModalWindowManager manager] dimmingView];
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
        
        [presentedViewController willMoveToParentViewController:nil];
        [presentedViewController removeFromParentViewController];
        [presentedViewController didMoveToParentViewController:nil];
        
        self.viewControllerToPresent = nil;
        self.dimmingView = nil;
        
        [[[UIApplication sharedApplication].delegate window] makeKeyAndVisible];
    };
    
    if (equalityTest == MNGModalAnimationNone) {
        animationsBlock();
        completionBlock();
    }else{
        [UIView animateWithDuration:0.4f animations:^{
            animationsBlock();
        } completion:^(BOOL finished) {
            completionBlock();
            if (completion) {
                completion();
            }
        }];
    }
}

@end
