//
//  SecondViewController.m
//  OverplayDemo
//
//  Created by Mitchell Kahn on 1/29/16.
//  Copyright © 2016 AppDelegates. All rights reserved.
//

#import "SecondViewController.h"
#import "SVProgressHUD.h"

@interface SecondViewController ()
@property (strong, nonatomic) IBOutlet UILabel *bannerLabel;
- (IBAction)disme:(id)sender;

@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSUInteger r = arc4random_uniform(100000);
    
    if ([self respondsToSelector:@selector(setAutomaticallyAdjustsScrollViewInsets:)]) {
        [self setAutomaticallyAdjustsScrollViewInsets:NO];
    }
        self.webView.delegate = self;
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@/opp/io.overplay.mainframe/app/control/index.html?decache=%ld", self.op.ipAddress, r]]]];
    self.bannerLabel.text = self.op.systemName;
    [SVProgressHUD setBackgroundColor:[[UIColor whiteColor] colorWithAlphaComponent:0]];
    [SVProgressHUD showWithStatus:@"Loading..."];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    
    [SVProgressHUD dismiss];
}


- (IBAction)disme:(id)sender {
    
    [SVProgressHUD dismiss];
    [self.navigationController popViewControllerAnimated:YES];
}
@end
