//
//  MNGModalViewControllerOptions.h
//  MNGModal
//
//  Created by Paperless Post on 11/8/13.
//
//

#ifndef MNGModal_MNGModalViewControllerOptions_h
#define MNGModal_MNGModalViewControllerOptions_h

/**
 *  Usable options when presenting a modal view controller.
 */
typedef NS_OPTIONS(NSUInteger, MNGModalViewControllerOptions) {
    /**
     *  This option adds a semi-transparent dimming view behind the view controller being presented.
     *  The dimming view dims the entire screen by default, or dims below the nav bar if the 
     *  MNGModalOptionShouldNotCoverNavigationBar is specified
     */
    MNGModalOptionShouldDarken                  = 1 << 0,
    /**
     *  This option controls whether the navigation bar is covered by the dimming view. If it is not covered by
     *  the dimming view, touches outside the presented view controller will not be detected on the navigation bar
     *  (and the navigation bar will respond to these touches normally). Also, since the frame of the presented
     *  view controller is based on the dimming view, the y origin of the frame specified will now be relative
     *  to the bottom of the navigation bar instead of the top of the screen.
     */
    MNGModalOptionShouldNotCoverNavigationBar   = 1 << 1,
    /**
     *  This option specifies that the modal view controller should be presented with no animation.
     */
    MNGModalAnimationNone                       = 0 << 2,
    /**
     *  This option specifies that the modal view controller should slide in from the right side of the screen.
     *  The modal view controller will slide back off of the right side of the screen upon dismissal.
     */
    MNGModalAnimationSlideFromRight             = 1 << 2,
    /**
     *  This option specifies that the modal view controller should slide in from the left side of the screen.
     *  The modal view controller will slide back off of the left side of the screen upon dismissal.
     */
    MNGModalAnimationSlideFromLeft              = 2 << 2,
    /**
     *  This option specifies that the modal view controller should slide in from the top of the screen.
     *  The modal view controller will slide back off the top of the screen upon dismissal.
     */
    MNGModalAnimationSlideFromTop               = 3 << 2,
    /**
     *  This option specifies that the modal view controller should slide in from the bottom of the screen.
     *  The modal view controller will slide back off the bottom of the screen upon dismissal.
     */
    MNGModalAnimationSlideFromBottom            = 4 << 2,
    /**
     *  This option specifies that the modal view controller should fade in.
     *  The modal view controller will fade back out upon dismissal.
     */
    MNGModalAnimationFade                       = 5 << 2,
};

#endif
