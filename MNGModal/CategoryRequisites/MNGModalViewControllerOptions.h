//
//  MNGModalViewControllerOptions.h
//  MNGModal
//
//  Created by Paperless Post on 11/8/13.
//
//

#ifndef MNGModal_MNGModalViewControllerOptions_h
#define MNGModal_MNGModalViewControllerOptions_h

typedef NS_OPTIONS(NSUInteger, MNGModalViewControllerOptions) {
	MNGModalOptionShouldDarken                  = 1 << 0,
	MNGModalOptionShouldNotCoverNavigationBar   = 1 << 1,
    
    MNGModalAnimationNone                       = 0 << 2,
	MNGModalAnimationSlideFromRight             = 1 << 2,
    MNGModalAnimationSlideFromLeft              = 2 << 2,
    MNGModalAnimationSlideFromTop               = 3 << 2,
    MNGModalAnimationSlideFromBottom            = 4 << 2,
	MNGModalAnimationFade                       = 5 << 2,
};

#endif
