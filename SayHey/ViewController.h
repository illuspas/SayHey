//
//  ViewController.h
//  SayHey
//
//  Created by Mingliang Chen on 13-11-29.
//  Copyright (c) 2013年 Mingliang Chen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RtmpClient.h"

@interface ViewController : UIViewController<RtmpClientDelegate,UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *streamServerText;
@property (weak, nonatomic) IBOutlet UITextField *pubStreamNameText;
@property (weak, nonatomic) IBOutlet UITextField *playStreamNameText;
@property (weak, nonatomic) IBOutlet UIButton *pubBtn;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UITextView *logView;


- (IBAction)clickPubBtn:(id)sender;
- (IBAction)clickPlayBtn:(id)sender;


@end
