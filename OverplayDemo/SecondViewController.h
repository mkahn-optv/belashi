//
//  SecondViewController.h
//  OverplayDemo
//
//  Created by Mitchell Kahn on 1/29/16.
//  Copyright © 2016 AppDelegates. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Overplayer.h"

@interface SecondViewController : UIViewController <UIWebViewDelegate>

@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) Overplayer* op;

@end

