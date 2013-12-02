//
//  MNGModalLayer.h
//  MNGModal
//
//  Created by Paperless Post on 11/8/13.
//
//

#import <Foundation/Foundation.h>
#import "MNGModalViewControllerOptions.h"
@protocol MNGModalProtocol;

@interface MNGModalLayer : NSObject

@property (nonatomic, strong) UIViewController *presentingViewController;
@property (nonatomic, strong) UIViewController *presentedViewController;
@property (nonatomic, assign) MNGModalViewControllerOptions options;
@property (nonatomic, weak) id <MNGModalProtocol> delegate;

+ (instancetype)layerWithPresentingViewController:(UIViewController*)presentingViewController
                          presentedViewController:(UIViewController*)presentedViewController
                                          options:(MNGModalViewControllerOptions)options
                                         delegate:(id <MNGModalProtocol>)delegate;

@end
