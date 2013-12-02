//
//  ButtonViewController.m
//  MNGModal
//
//  Created by Paperless Post on 10/29/13.
//
//

#import "ButtonViewController.h"
#import "UIViewController+CustomModals.h"
#import "PresentedViewController.h"
#import "MNGModalProtocol.h"

@interface ButtonViewController () <MNGModalProtocol>

@property (nonatomic,strong) UISegmentedControl *segControl;
@property (nonatomic,strong) NSArray *animationOptions;

@property (nonatomic,assign) BOOL shouldDarken;
@property (nonatomic,assign) BOOL shouldntCoverNav;

@end

@implementation ButtonViewController

- (id)init
{
    if (self = [super init]) {
        self.animationOptions = @[@(MNGModalAnimationNone),
                                  @(MNGModalAnimationFade),
                                  @(MNGModalAnimationSlideFromLeft),
                                  @(MNGModalAnimationSlideFromRight),
                                  @(MNGModalAnimationSlideFromBottom),
                                  @(MNGModalAnimationSlideFromTop)];
    }
    return self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSInteger buttonWidth = 250;
    NSInteger buttonHeight = 50;
    NSInteger spacing = 10;
    
    UIButton *presentButton = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width/2-buttonWidth/2,
                                                                        80,
                                                                        buttonWidth,
                                                                        buttonHeight)];
    [presentButton setTitle:@"Present Modal" forState:UIControlStateNormal];
    presentButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    presentButton.backgroundColor = [UIColor blackColor];
    [presentButton addTarget:self action:@selector(testCategory) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:presentButton];
    
    
    NSArray *items = @[@"None", @"Fade", @"Left", @"Right", @"Bottom", @"Top"];
    self.segControl = [[UISegmentedControl alloc]initWithItems:items];
    self.segControl.frame = CGRectMake(spacing,
                                  presentButton.frame.origin.y+presentButton.frame.size.height+spacing,
                                  self.view.frame.size.width-spacing-spacing,
                                  presentButton.frame.size.height);
    self.segControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.segControl];
    
    UIButton *shouldDarkenButton = [UIButton new];
    shouldDarkenButton.frame = CGRectMake(spacing,
                                       self.segControl.frame.origin.y+self.segControl.frame.size.height+spacing,
                                       buttonWidth,
                                       self.segControl.frame.size.height);
    [shouldDarkenButton setTitle:@"Should Darken" forState:UIControlStateNormal];
    [shouldDarkenButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [shouldDarkenButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [shouldDarkenButton setBackgroundColor:[UIColor whiteColor]];
    shouldDarkenButton.layer.cornerRadius = 3;
    shouldDarkenButton.layer.borderColor = [UIColor blueColor].CGColor;
    shouldDarkenButton.layer.borderWidth = 1;
    [shouldDarkenButton addTarget:self action:@selector(toggleShouldDarken:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:shouldDarkenButton];
    
    UIButton *shouldCoverNavButton = [UIButton new];
    shouldCoverNavButton.frame = CGRectMake(shouldDarkenButton.frame.origin.x+shouldDarkenButton.frame.size.width+spacing,
                                            shouldDarkenButton.frame.origin.y,
                                            buttonWidth,
                                            self.segControl.frame.size.height);
    [shouldCoverNavButton setTitle:@"Shouldn't Cover Nav" forState:UIControlStateNormal];
    [shouldCoverNavButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [shouldCoverNavButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [shouldCoverNavButton setBackgroundColor:[UIColor whiteColor]];
    shouldCoverNavButton.layer.cornerRadius = 3;
    shouldCoverNavButton.layer.borderColor = [UIColor blueColor].CGColor;
    shouldCoverNavButton.layer.borderWidth = 1;
    [shouldCoverNavButton addTarget:self action:@selector(toggleShouldntCoverNav:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:shouldCoverNavButton];
}

- (void)testCategory
{
    UIViewController *testVC = [ButtonViewController new];
    
    NSUInteger index = self.segControl.selectedSegmentIndex;
    MNGModalViewControllerOptions options = [ButtonViewController animationOptionAtIndex:index];
    if (self.shouldDarken) {
        options = options|MNGModalOptionShouldDarken;
    }
    if (self.shouldntCoverNav) {
        options = options|MNGModalOptionShouldNotCoverNavigationBar;
    }
    
    [self presentViewController:testVC
                          frame:CGRectMake(100, 100, 500, 900)
                        options:options
                     completion:nil
                       delegate:self];
}

+ (MNGModalViewControllerOptions)animationOptionAtIndex:(NSUInteger)index
{
    MNGModalViewControllerOptions option;
    switch (index) {
        case 0:
            option = MNGModalAnimationNone;
            break;
        case 1:
            option = MNGModalAnimationFade;
            break;
        case 2:
            option = MNGModalAnimationSlideFromLeft;
            break;
        case 3:
            option = MNGModalAnimationSlideFromRight;
            break;
        case 4:
            option = MNGModalAnimationSlideFromBottom;
            break;
        case 5:
            option = MNGModalAnimationSlideFromTop;
            break;
        default:
            option = 0;
            break;
    }
    return option;
}

- (void)toggleShouldDarken:(id)sender
{
    self.shouldDarken = !self.shouldDarken;
    UIButton *button = (UIButton*)sender;
    [button setSelected:self.shouldDarken];
    UIColor *backgroundColor = button.selected ? [UIColor blueColor] : [UIColor whiteColor];
    [button setBackgroundColor:backgroundColor];
}

- (void)toggleShouldntCoverNav:(id)sender
{
    self.shouldntCoverNav = !self.shouldntCoverNav;
    UIButton *button = (UIButton*)sender;
    [button setSelected:self.shouldntCoverNav];
    UIColor *backgroundColor = button.selected ? [UIColor blueColor] : [UIColor whiteColor];
    [button setBackgroundColor:backgroundColor];
}

-(void)tapDetectedOutsideModal:(UITapGestureRecognizer *)tapGestureRecognizer
{
    [self dismissModalViewControllerWithCompletion:nil];
}

@end
