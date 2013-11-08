//
//  UIViewController+CustomModals.h
//  MNGModal
//
//  Created by Paperless Post on 10/29/13.
//
//

#import <UIKit/UIKit.h>
#import "MNGModalViewControllerOptions.h"
#import "MNGModalProtocol.h"

@interface UIViewController (CustomModals)

-(void)presentViewController:(UIViewController *)viewControllerToPresent frame:(CGRect)frame options:(MNGModalViewControllerOptions)options completion:(void (^)(void))completion;

-(void)presentViewController:(UIViewController *)viewControllerToPresent frame:(CGRect)frame options:(MNGModalViewControllerOptions)options completion:(void (^)(void))completion delegate:(id <MNGModalProtocol>)delegate;

- (void)dismissModalViewControllerWithCompletion:(void (^)(void))completion;

@end
