//
//  UIViewController+TopLayoutGuide.h
//  MNGModal
//
//  Created by Paperless Post on 12/2/13.
//
//

#import <UIKit/UIKit.h>

@interface UIViewController (TopLayoutGuide)

/**
 *  An iOS 6 method to access the top layout guide length safely
 *
 *  @return returns value of top layout guide's length if the view controller responds to topLayoutGuide,
 *  or if not it returns the height of the navigation controller's navigation bar
 */
- (CGFloat)safety_topLayoutGuideLength;

@end
