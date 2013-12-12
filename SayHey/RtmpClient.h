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

@interface RtmpClient : NSObject<AudioRecordDelegate>


-(id)initWithSampleRate:(int)sampleRate withEncoder:(int)audioEncoder;

-(void)startPublishWithUrl:(NSString*) rtmpURL;
-(void)stopPublish;

-(void)startPlayWithUrl:(NSString*) rtmpURL;
-(void)stopPlay;

@end
