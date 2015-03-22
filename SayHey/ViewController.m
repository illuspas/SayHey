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
    BOOL isStartRecord;
    BOOL isStartPlay;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    mRtmpClient = [[RtmpClient alloc] initWithSampleRate:16000 withEncoder:0];
    [mRtmpClient setOutDelegate:self];
    [_streamServerText setDelegate:self];
    [_pubStreamNameText setDelegate:self];
    [_playStreamNameText setDelegate:self];
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
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
    if(isStartPlay)
    {
        [mRtmpClient stopPlay];
    }else
    {
        NSString* rtmpUrl = [[NSString alloc] initWithFormat:@"%@/%@ live=1",_streamServerText.text,_playStreamNameText.text];
        [mRtmpClient startPlayWithUrl:rtmpUrl];
        NSLog(@"Start play with url %@",rtmpUrl);
    }
}

-(void)updateLogs:(NSString*)text
{
    _logView.text = text;
}
-(void)updatePubBtn:(NSString*)text
{
    [_pubBtn setTitle:text forState:UIControlStateNormal];
}

-(void)updatePlayBtn:(NSString*)text
{
    [_playBtn setTitle:text forState:UIControlStateNormal];
}
-(void)EventCallback:(int)event{
    NSLog(@"EventCallback %d",event);
    NSString* viewText = _logView.text;
    switch (event) {
        case 1000:
            viewText =  [viewText stringByAppendingString:@"开始发布\r\n"];
            break;
        case 1001:
            viewText = [viewText stringByAppendingString:@"发布成功\r\n"];
            [self performSelectorOnMainThread:@selector(updatePubBtn:) withObject:@"Stop" waitUntilDone:YES];
            isStartRecord = YES;
            break;
        case 1002:
            viewText = [viewText stringByAppendingString:@"发布失败\r\n"];
            break;
        case 1004:
            viewText = [viewText stringByAppendingString:@"发布结束\r\n"];
            [self performSelectorOnMainThread:@selector(updatePubBtn:) withObject:@"Publish" waitUntilDone:YES];
            isStartRecord = NO;
            break;
        case 2000:
            viewText =  [viewText stringByAppendingString:@"开始播放\r\n"];
            break;
        case 2001:
            viewText = [viewText stringByAppendingString:@"播放成功\r\n"];
           [self performSelectorOnMainThread:@selector(updatePlayBtn:) withObject:@"Stop" waitUntilDone:YES];
            isStartPlay = YES;
            break;
        case 2002:
            viewText = [viewText stringByAppendingString:@"播放失败\r\n"];
            break;
        case 2004:
            viewText = [viewText stringByAppendingString:@"播放结束\r\n"];
            [self performSelectorOnMainThread:@selector(updatePlayBtn:) withObject:@"Play" waitUntilDone:YES];
            isStartPlay = NO;
            break;
        case 2005:
            viewText = [viewText stringByAppendingString:@"播放异常结束或发布端关闭\r\n"];
            break;
        default:
            break;
    }
    [self performSelectorOnMainThread:@selector(updateLogs:) withObject:viewText waitUntilDone:YES];
    
    
}
@end
