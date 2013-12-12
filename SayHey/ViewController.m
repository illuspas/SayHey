//
//  ViewController.m
//  SayHey
//
//  Created by Mingliang Chen on 13-11-29.
//  Copyright (c) 2013年 Mingliang Chen. All rights reserved.
//

#import "ViewController.h"


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
    [mRtmpClient setOutDelegate:self];
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
    [self setLogView:nil];
    [super viewDidUnload];
}

- (IBAction)clickPubBtn:(id)sender {
    if(isStartRecord){
        [mRtmpClient stopPublish];
    }else {
        NSString* rtmpUrl = [[NSString alloc] initWithFormat:@"%@/%@ live=1",_streamServerText.text,_pubStreamNameText.text];
        [mRtmpClient startPublishWithUrl:rtmpUrl];
        NSLog(@"Start publish with url %@",rtmpUrl);
        
    }
}

- (IBAction)clickPlayBtn:(id)sender {
    
}

-(void)updateLogs:(NSString*)text
{
    _logView.text = text;
}
-(void)updatePubBtn:(NSString*)text
{
    [_pubBtn setTitle:text forState:UIControlStateNormal];
}
-(void)EventCallback:(int)event{
    NSLog(@"EventCallback %d",event);
    NSString* viewText = _logView.text;
    NSString* buttonText = @"Publish";
    switch (event) {
        case 1000:
            viewText =  [viewText stringByAppendingString:@"开始发布\r\n"];
            break;
        case 1001:
            viewText = [viewText stringByAppendingString:@"发布成功\r\n"];
            buttonText = @"Stop";
            isStartRecord = YES;
            break;
        case 1002:
            viewText = [viewText stringByAppendingString:@"发布失败\r\n"];
            break;
        case 1004:
            viewText = [viewText stringByAppendingString:@"发布结束\r\n"];
            buttonText = @"Publish";
            isStartRecord = NO;
            break;
        default:
            break;
    }
    [self performSelectorOnMainThread:@selector(updateLogs:) withObject:viewText waitUntilDone:YES];
    [self performSelectorOnMainThread:@selector(updatePubBtn:) withObject:buttonText waitUntilDone:YES];
}
@end
