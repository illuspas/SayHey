//
//  RtmpClient.h
//  SayHey
//
//  Created by Mingliang Chen on 13-12-11.
//  Copyright (c) 2013年 Mingliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioRecoder.h"

#include <librtmp/rtmp.h>
#include <librtmp/amf.h>
#include <librtmp/log.h>
#include <speex/speex.h>
#include <speex/speex_header.h>

@protocol RtmpClientDelegate <NSObject>

-(void)EventCallback:(int)event;

@end

@interface RtmpClient : NSObject<AudioRecordDelegate>
{
    AudioRecoder *mAudioRecord;
    
    RTMP *pPubRtmp;
    RTMP *pPlayRtmp;
    BOOL isStartPub;
    BOOL isStartPlay;
    
    SpeexBits ebits; //speex encoder
    int enc_frame_size;
    void *enc_state;
    char *output_buffer;
    short *pcm_buffer;
    UInt32 pubTs;
    
    SpeexBits dbits;//speex decoder;
    int dec_frame_size;
    void* dec_state;
    
    NSCondition *condition;
    
    id<RtmpClientDelegate> outDelegate;
}

-(id)initWithSampleRate:(int)sampleRate withEncoder:(int)audioEncoder;

-(void)setOutDelegate:(id<RtmpClientDelegate>)delegate;

-(void)startPublishWithUrl:(NSString*) rtmpURL;
-(void)stopPublish;

-(void)startPlayWithUrl:(NSString*) rtmpURL;
-(void)stopPlay;

@end
