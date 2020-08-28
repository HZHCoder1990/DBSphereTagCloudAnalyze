//
//  ViewController.m
//  FTSphereTgasView
//
//  Created by 黄智浩 on 2020/8/26.
//  Copyright © 2020 黄智浩. All rights reserved.
//


#define random(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)/255.0]
#define randomColor random(arc4random_uniform(256), arc4random_uniform(256), arc4random_uniform(256), arc4random_uniform(256))


#import "ViewController.h"
#import "FTSphereTgasView.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    NSMutableArray *array = [NSMutableArray array];
    for (NSInteger i = 0; i < 40; i ++) {
        UILabel *view = [[UILabel alloc]init];
        
        CGRect frame = view.frame;
        frame.size = CGSizeMake(60, 20);
        view.frame = frame;
        
        view.text = [NSString stringWithFormat:@"P%zd",i + 1];
        view.font = [UIFont boldSystemFontOfSize:24];
        view.textAlignment = NSTextAlignmentCenter;
        
        [array addObject:view];
    }
    
    FTSphereTgasView *sphereTagsView = [[FTSphereTgasView alloc]initWithFrame:CGRectMake(0, (CGRectGetHeight(self.view.frame) - CGRectGetWidth(self.view.frame)) * 0.5, CGRectGetWidth(self.view.frame), CGRectGetWidth(self.view.frame)) tags:array];
    [self.view addSubview:sphereTagsView];
}


@end
