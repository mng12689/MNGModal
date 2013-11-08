//
//  PresentedViewController.m
//  MNGModal
//
//  Created by Paperless Post on 11/1/13.
//
//

#import "PresentedViewController.h"
#import "UIViewController+CustomModals.h"

@interface PresentedViewController ()

@end

@implementation PresentedViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blueColor];
    
    NSInteger buttonWidth = self.view.frame.size.width-40;
    NSInteger buttonHeight = 50;
    UIButton *dismissButton = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width/2-buttonWidth/2,
                                                                        self.view.frame.size.height/2-buttonHeight/2,
                                                                        buttonWidth,
                                                                        buttonHeight)];
    dismissButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleWidth;
    [dismissButton setTitle:@"Dismiss Modal" forState:UIControlStateNormal];
    dismissButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    dismissButton.backgroundColor = [UIColor blackColor];
    [dismissButton addTarget:self action:@selector(dismissCurrentModal) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:dismissButton];
    
    UIButton *presentAgainButton = [[UIButton alloc]initWithFrame:CGRectMake(dismissButton.frame.origin.x,
                                                                             10,
                                                                             buttonWidth,
                                                                             buttonHeight)];
    presentAgainButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleWidth;
    [presentAgainButton setTitle:@"Present Next Modal" forState:UIControlStateNormal];
    presentAgainButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    presentAgainButton.backgroundColor = [UIColor blackColor];
    [presentAgainButton addTarget:self action:@selector(presentNextModal) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:presentAgainButton];

}

#pragma mark - button actions
- (void)dismissCurrentModal
{
    [self dismissModalViewControllerWithCompletion:nil];
}

- (void)presentNextModal
{
    PresentedViewController *nextVC = [PresentedViewController new];
    [self presentViewController:nextVC frame:self.view.frame options:MNGModalAnimationSlideFromBottom completion:nil];
}

@end
