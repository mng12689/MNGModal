//
//  UIViewController+UIViewController_Modals.m
//  MNGModal
//
//  Created by Paperless Post on 10/29/13.
//
//

#import "UIViewController+CustomModals.h"
#import "MNGModalManager.h"

@implementation UIViewController (CustomModals)

-(void)presentViewController:(UIViewController *)viewControllerToPresent
                       frame:(CGRect)frame
                     options:(MNGModalViewControllerOptions)options
                  completion:(void (^)(void))completion
{
    [[MNGModalManager manager] presentViewController:viewControllerToPresent
                                  fromViewController:self
                                               frame:frame
                                             options:options
                                          completion:completion
                                            delegate:nil];
}

-(void)presentViewController:(UIViewController *)viewControllerToPresent
                       frame:(CGRect)frame
                     options:(MNGModalViewControllerOptions)options
                  completion:(void (^)(void))completion
                    delegate:(id<MNGModalProtocol>)delegate
{
    [[MNGModalManager manager] presentViewController:viewControllerToPresent
                                  fromViewController:self
                                               frame:frame
                                             options:options
                                          completion:completion
                                            delegate:delegate];
}

- (void)dismissModalViewControllerWithCompletion:(void (^)(void))completion
{
    [[MNGModalManager manager] dismissModalViewControllerWithCompletion:completion];
}

- (UIViewController *)MNGPresentedViewController
{
    return [[MNGModalManager manager] MNGPresentedViewController];
}

@end
