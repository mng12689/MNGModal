//
//  ButtonViewController.m
//  MNGModal
//
//  Created by Paperless Post on 10/29/13.
//
//

#import "ButtonViewController.h"
#import "UIViewController+CustomModals.h"

@interface ButtonViewController () <MNGModalProtocol>

@property (nonatomic,strong) UISegmentedControl *segControl;
@property (nonatomic,strong) NSArray *animationOptions;

@property (nonatomic,assign) BOOL shouldDarken;

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
    
    NSInteger buttonWidth = 150;
    NSInteger buttonHeight = 50;
    NSInteger spacing = 10;
    
    UIButton *presentButton = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width/2-buttonWidth-spacing,
                                                                        2*spacing,
                                                                        buttonWidth,
                                                                        buttonHeight)];
    [presentButton setTitle:@"Present Modal" forState:UIControlStateNormal];
    presentButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    presentButton.backgroundColor = [UIColor blackColor];
    [presentButton addTarget:self action:@selector(testCategory) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:presentButton];
    
    UIButton *dismissButton = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width/2+spacing,
                                                                        presentButton.frame.origin.y,
                                                                        buttonWidth,
                                                                        buttonHeight)];
    [dismissButton setTitle:@"Dismiss Modal" forState:UIControlStateNormal];
    dismissButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    dismissButton.backgroundColor = [UIColor blackColor];
    [dismissButton addTarget:self action:@selector(dismissCurrentModal) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:dismissButton];
    
    NSArray *items = @[@"None", @"Fade", @"From Left", @"From Right", @"From Bottom", @"From Top"];
    self.segControl = [[UISegmentedControl alloc]initWithItems:items];
    self.segControl.frame = CGRectMake(spacing,
                                  dismissButton.frame.origin.y+dismissButton.frame.size.height+spacing,
                                  self.view.frame.size.width-spacing-spacing,
                                  dismissButton.frame.size.height);
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
}

- (void)testCategory
{
    UIViewController *testVC = [UIViewController new];
    testVC.view.backgroundColor = [UIColor blueColor];
    
    UITextField *textField = [[UITextField alloc]initWithFrame:CGRectMake(40, 40, 100, 40)];
    textField.userInteractionEnabled = YES;
    textField.backgroundColor = [UIColor greenColor];
    [testVC.view addSubview:textField];
    [testVC.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissCurrentModal)]];
    
    NSUInteger index = self.segControl.selectedSegmentIndex;
    MNGModalViewControllerOptions options = [ButtonViewController animationOptionAtIndex:index];
    if (self.shouldDarken) {
        options = options|MNGModalAnimationShouldDarken;
    }
    
    [self presentViewController:testVC
                          frame:CGRectMake(200, 200, 300, 400)
                        options:options
                     completion:nil];
}

- (void)dismissCurrentModal
{
    [self dismissModalViewControllerWithCompletion:nil];
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

-(void)tapDetectedOutsideModal:(UITapGestureRecognizer *)tapGestureRecognizer
{
    [self dismissModalViewControllerWithCompletion:nil];
}

@end
