//
//  ButtonViewController.m
//  MNGModal
//
//  Created by Paperless Post on 10/29/13.
//
//

#import "ButtonViewController.h"
#import "UIViewController+CustomModals.h"
#import "MNGModalProtocol.h"

@interface ButtonViewController () <MNGModalProtocol>

@property (nonatomic,strong) UISegmentedControl *segControl;
@property (nonatomic,strong) NSArray *animationOptions;

@property (nonatomic,assign) BOOL shouldDarken;
@property (nonatomic,assign) BOOL shouldntCoverNav;
@property (nonatomic,assign) BOOL allowUserInteraction;

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

- (void)dealloc
{
    NSLog(@"dealloc");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSInteger buttonHeight = 50;
    NSInteger spacing = 10;
    NSInteger buttonWidth = self.view.frame.size.width/3 - spacing*6;

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
    
    UIButton *allowUserInteractionButton = [UIButton new];
    allowUserInteractionButton.frame = CGRectMake(shouldCoverNavButton.frame.origin.x+shouldCoverNavButton.frame.size.width+spacing,
                                            shouldCoverNavButton.frame.origin.y,
                                            buttonWidth,
                                            self.segControl.frame.size.height);
    [allowUserInteractionButton setTitle:@"Allow BG Interaction" forState:UIControlStateNormal];
    [allowUserInteractionButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [allowUserInteractionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [allowUserInteractionButton setBackgroundColor:[UIColor whiteColor]];
    allowUserInteractionButton.layer.cornerRadius = 3;
    allowUserInteractionButton.layer.borderColor = [UIColor blueColor].CGColor;
    allowUserInteractionButton.layer.borderWidth = 1;
    [allowUserInteractionButton addTarget:self action:@selector(toggleAllowUserInteraction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:allowUserInteractionButton];

}

- (void)testCategory
{
    UIViewController *testVC = [ButtonViewController new];
    testVC.view.backgroundColor = [UIColor blueColor];
    
    NSUInteger index = self.segControl.selectedSegmentIndex;
    MNGModalViewControllerOptions options = [ButtonViewController animationOptionAtIndex:index];
    if (self.shouldDarken) {
        options = options|MNGModalOptionShouldDarken;
    }
    if (self.shouldntCoverNav) {
        options = options|MNGModalOptionShouldNotCoverNavigationBar;
    }
    
    if (self.allowUserInteraction) {
        options = options|MNGModalOptionAllowUserInteractionWithBackground;
    }
    
    [self presentViewController:testVC
                          frame:CGRectMake(40, 40, 500, 600)
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

- (void)toggleAllowUserInteraction:(id)sender
{
    self.allowUserInteraction = !self.allowUserInteraction;
    UIButton *button = (UIButton*)sender;
    [button setSelected:self.allowUserInteraction];
    UIColor *backgroundColor = button.selected ? [UIColor blueColor] : [UIColor whiteColor];
    [button setBackgroundColor:backgroundColor];
}

-(void)tapDetectedOutsideModal:(UITapGestureRecognizer *)tapGestureRecognizer
{
    [self dismissModalViewControllerWithCompletion:nil];
}

@end
