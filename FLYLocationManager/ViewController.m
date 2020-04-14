//
//  ViewController.m
//  FLYLocationManager
//
//  Created by fly on 2020/4/14.
//  Copyright © 2020 fly. All rights reserved.
//

#import "ViewController.h"
#import "FLYLocationManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[FLYLocationManager sharedManager] requestLocation:^(CLLocation *location) {
        
        NSLog(@"location = %@", location);
        
    } error:nil];
}


@end
