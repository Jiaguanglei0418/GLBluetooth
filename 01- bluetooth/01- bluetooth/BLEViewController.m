//
//  BLEViewController.m
//  01- bluetooth
//
//  Created by jiaguanglei on 16/2/16.
//  Copyright © 2016年 roseonly. All rights reserved.
//
/**
 *  主界面 --- 控制控制器跳转
 */


#import "BLEViewController.h"

#import "CentralViewController.h"
#import "PeripheryViewController.h"

@interface BLEViewController ()
- (IBAction)peripheryMethod:(id)sender;
- (IBAction)centralMethod:(id)sender;


@end

@implementation BLEViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"BLEViewController";
}


- (IBAction)peripheryMethod:(id)sender {
    
    [self.navigationController pushViewController:[[PeripheryViewController alloc] init] animated:YES];
    
}

- (IBAction)centralMethod:(id)sender {
    [self.navigationController pushViewController:[[CentralViewController alloc] init] animated:YES];
}
@end
