//
//  MNGModalLayer.m
//  MNGModal
//
//  Created by Paperless Post on 11/8/13.
//
//

#import "MNGModalLayer.h"

@implementation MNGModalLayer

+ (instancetype)layerWithPresentingViewController:(UIViewController *)presentingViewController presentedViewController:(UIViewController *)presentedViewController options:(MNGModalViewControllerOptions)options delegate:(id<MNGModalProtocol>)delegate
{
    MNGModalLayer *layer = [MNGModalLayer new];
    layer.presentingViewController = presentingViewController;
    layer.presentedViewController = presentedViewController;
    layer.options = options;
    layer.delegate = delegate;
    return layer;
}

@end
