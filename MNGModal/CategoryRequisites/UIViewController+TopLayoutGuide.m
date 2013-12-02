//
//  UIViewController+TopLayoutGuide.m
//  MNGModal
//
//  Created by Paperless Post on 12/2/13.
//
//

#import "UIViewController+TopLayoutGuide.h"

@implementation UIViewController (TopLayoutGuide)

- (CGFloat)safety_topLayoutGuideLength
{
    CGFloat length = 0;
    if ([self respondsToSelector:@selector(topLayoutGuide)]) {
        length = [[self topLayoutGuide] length];
    }else{
        length = self.navigationController.navigationBar.frame.size.height;
    }
    return length;
}

@end
