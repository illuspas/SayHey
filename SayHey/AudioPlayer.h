//
//  AudioPlayer.h
//  SayHey
//
//  Created by Mingliang Chen on 13-12-12.
//  Copyright (c) 2013年 Mingliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <CoreFoundation/CoreFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#include <unistd.h>

#define kNumberBuffers 3

@interface AudioPlayer : NSObject
{
    AudioQueueRef					mQueue;
    AudioQueueBufferRef				mBuffers[kNumberBuffers];
    AudioStreamBasicDescription     mPlayFormat;
    int                             mIndex;
@public
    BOOL                            isStartPlay;
    int                             mBufferByteSize;
    int                             pip_fd[2];
   
}

-(id)initWithSampleRate:(int)sampleRate;
-(void)startPlayWithBufferByteSize:(int)bufferByteSize;
-(void)stopPlay;
-(void)putAudioData:(short*)pcmData;

@end
