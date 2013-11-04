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
    
    NSInteger buttonWidth = self.view.frame.size.width/2;
    NSInteger buttonHeight = 50;
    UIButton *dismissButton = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width/2-buttonWidth/2,
                                                                        self.view.frame.size.height/2-buttonHeight/2,
                                                                        buttonWidth,
                                                                        buttonHeight)];
    [dismissButton setTitle:@"Dismiss Modal" forState:UIControlStateNormal];
    dismissButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    dismissButton.backgroundColor = [UIColor blackColor];
    [dismissButton addTarget:self action:@selector(dismissCurrentModal) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:dismissButton];
}

- (void)dismissCurrentModal
{
    [self dismissModalViewControllerWithCompletion:nil];
}

@end
