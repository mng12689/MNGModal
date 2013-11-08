//
//  MNGModalWindowManager.h
//  MNGModal
//
//  Created by Paperless Post on 10/31/13.
//
//

#import <Foundation/Foundation.h>
#import "MNGModalViewControllerOptions.h"
@protocol MNGModalProtocol;

@interface MNGModalManager : NSObject

+ (MNGModalManager *)manager;

-(void)presentViewController:(UIViewController *)presentedViewController fromViewController:(UIViewController *)presentingViewController frame:(CGRect)frame options:(MNGModalViewControllerOptions)options completion:(void (^)(void))completion delegate:(id<MNGModalProtocol>)delegate;

- (void)dismissModalViewControllerWithCompletion:(void (^)(void))completion;

@end
