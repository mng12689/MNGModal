//
//  MNGModalWindowManager.m
//  MNGModal
//
//  Created by Paperless Post on 10/31/13.
//
//

#import "MNGModalManager.h"
#import "MNGModalProtocol.h"

@interface MNGModalManager ()

@property (nonatomic, strong) UIView *dimmingView;

@property (nonatomic, strong) UIViewController *viewControllerToPresent;
@property (nonatomic, assign) MNGModalViewControllerOptions options;

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
        [_dimmingView addGestureRecognizer:[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapGestureDetected:)]];
        [mainWindow addSubview:_dimmingView];
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
    
    UIView *dimmingView = self.dimmingView;
    if (options & MNGModalAnimationShouldDarken) {
        dimmingView.backgroundColor = [UIColor clearColor];
    }
    
    CGRect startFrame = frame;
    NSInteger equalityTest =  (7 << 2) & options;
    
    if (equalityTest == MNGModalAnimationSlideFromBottom) {
        startFrame.origin.y = dimmingView.frame.size.height;
    }else if (equalityTest == MNGModalAnimationSlideFromTop) {
        startFrame.origin.y = dimmingView.frame.origin.y-viewControllerToPresent.view.frame.size.height;
    }else if (equalityTest == MNGModalAnimationSlideFromRight) {
        startFrame.origin.x = dimmingView.frame.size.width;
    }else if (equalityTest == MNGModalAnimationSlideFromLeft) {
        startFrame.origin.x = dimmingView.frame.origin.x-viewControllerToPresent.view.frame.size.width;
    }
    viewControllerToPresent.view.frame = startFrame;
    
    CGFloat viewFinalAlpha = viewControllerToPresent.view.alpha;
    if (equalityTest == MNGModalAnimationFade) {
        viewControllerToPresent.view.alpha = 0;
    }
    
    [dimmingView addSubview:viewControllerToPresent.view];
    [viewControllerToPresent.view didMoveToSuperview];
    
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
    MNGModalViewControllerOptions options = self.options;
    UIViewController *presentedViewController = self.viewControllerToPresent;
    
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
        
        self.viewControllerToPresent = nil;
        
        [self.dimmingView removeFromSuperview];
        self.dimmingView = nil;
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

#pragma mark - protocol forwarding
- (void)tapGestureDetected:(UITapGestureRecognizer *)tapGestureRecognizer
{
    if ([self.viewControllerToPresent respondsToSelector:@selector(tapDetectedOutsideModal:)]) {
        id <MNGModalProtocol> viewController = (id <MNGModalProtocol>) self.viewControllerToPresent;
        [viewController tapDetectedOutsideModal:tapGestureRecognizer];
    }
}

@end
