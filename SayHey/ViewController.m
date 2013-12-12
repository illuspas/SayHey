//
//  ViewController.m
//  SayHey
//
//  Created by Mingliang Chen on 13-11-29.
//  Copyright (c) 2013年 Mingliang Chen. All rights reserved.
//

#import "ViewController.h"
#import "RtmpClient.h"

@interface ViewController ()
{
    RtmpClient *mRtmpClient;
    bool isStartRecord;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    mRtmpClient = [[RtmpClient alloc] initWithSampleRate:16000 withEncoder:0];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setStreamServerText:nil];
    [self setPubStreamNameText:nil];
    [self setPlayStreamNameText:nil];
    [self setPubBtn:nil];
    [self setPlayBtn:nil];
    [super viewDidUnload];
}

- (IBAction)clickPubBtn:(id)sender {
    if(isStartRecord){
        [mRtmpClient stopPublish];
        [_pubBtn setTitle:@"Publish" forState:UIControlStateNormal];
    }else {
        NSString* rtmpUrl = [[NSString alloc] initWithFormat:@"%@/%@ live=1",_streamServerText.text,_pubStreamNameText.text];
        [mRtmpClient startPublishWithUrl:rtmpUrl];
        NSLog(@"Start publish with url %@",rtmpUrl);
        [_pubBtn setTitle:@"Stop" forState:UIControlStateNormal];
    }
    isStartRecord = !isStartRecord;
}

- (IBAction)clickPlayBtn:(id)sender {
}
@end
