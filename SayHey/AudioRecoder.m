//
//  AudioRecoder.m
//  SayHey
//
//  Created by Mingliang Chen on 13-11-29.
//  Copyright (c) 2013年 Mingliang Chen. All rights reserved.
//

#import "AudioRecoder.h"

@implementation AudioRecoder


void MyInputBufferHandler(void *                                inUserData,
                          AudioQueueRef                         inAQ,
                          AudioQueueBufferRef					inBuffer,
                          const AudioTimeStamp *				inStartTime,
                          UInt32								inNumPackets,
                          const AudioStreamPacketDescription*	inPacketDesc)
{
    AudioRecoder* audioRecord = (__bridge AudioRecoder *)(inUserData);
  //  int64_t ts = (long long)([[NSDate date] timeIntervalSince1970]*1000.0f);
    if(audioRecord.outDelegate)
        [audioRecord.outDelegate AudioDataOutputBuffer:(char *)inBuffer->mAudioData bufferSize:inBuffer->mAudioDataByteSize];
   
    AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
}

-(id)initWIthSampleRate:(int)sampleRate
{
    self = [super init];
    if (self !=NULL) {
        memset(&mRecordFormat, 0, sizeof(mRecordFormat));
        mRecordFormat.mFormatID = kAudioFormatLinearPCM;
        mRecordFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        mRecordFormat.mBitsPerChannel = 16;
        mRecordFormat.mChannelsPerFrame = 1;
        mRecordFormat.mBytesPerPacket = mRecordFormat.mBytesPerFrame = (mRecordFormat.mBitsPerChannel / 8) * mRecordFormat.mChannelsPerFrame;
        mRecordFormat.mFramesPerPacket = 1;
        mRecordFormat.mSampleRate = sampleRate;
    }
    return self;
}

-(void)setAudioRecordDelegate:(id<AudioRecordDelegate>)delegate
{
    self.outDelegate = delegate;
}

-(void)startRecord
{
    int i,bufferByteSize;
    UInt32 size;
    OSStatus stat;
    AudioQueueNewInput(&mRecordFormat,
                       MyInputBufferHandler,
                       (__bridge void *)(self) /* userData */,
                       NULL /* run loop */, NULL /* run loop mode */,
                       0 /* flags */, &mQueue);
    size = sizeof(mRecordFormat);
    stat =  AudioQueueGetProperty(mQueue,
                          kAudioQueueProperty_StreamDescription,
                          &mRecordFormat, &size);
    bufferByteSize = [self ComputeRecordBufferSize:&mRecordFormat seconds:0.02];
    for (i = 0; i < kNumberRecordBuffers; ++i) {
        stat = AudioQueueAllocateBuffer(mQueue, bufferByteSize, &mBuffers[i]);
        stat = AudioQueueEnqueueBuffer(mQueue, mBuffers[i], 0, NULL);
    }
    stat = AudioQueueStart(mQueue, NULL);
    NSLog(@"AudioQueueStart %ld",stat);
}

-(void)stopRecord
{
    AudioQueueStop(mQueue, true);
    AudioQueueDispose(mQueue, true);
}

-(int)ComputeRecordBufferSize:(AudioStreamBasicDescription*)format seconds:(float)seconds
{
    int packets, frames, bytes = 0;
		frames = (int)ceil(seconds * format->mSampleRate);
		if (format->mBytesPerFrame > 0)
			bytes = frames * format->mBytesPerFrame;
		else {
			UInt32 maxPacketSize;
			if (format->mBytesPerPacket > 0)
				maxPacketSize = format->mBytesPerPacket;	// constant packet size
			else {
				UInt32 propertySize = sizeof(maxPacketSize);
				AudioQueueGetProperty(mQueue,
                                      kAudioQueueProperty_MaximumOutputPacketSize,
                                      &maxPacketSize,
                                      &propertySize);
			}
			if (format->mFramesPerPacket > 0)
				packets = frames / format->mFramesPerPacket;
			else
				packets = frames;	// worst-case scenario: 1 frame in a packet
			if (packets == 0)		// sanity check
				packets = 1;
			bytes = packets * maxPacketSize;
		}

	return bytes;
}
@end
