//
//  RtmpClient.m
//  SayHey
//
//  Created by Mingliang Chen on 13-12-11.
//  Copyright (c) 2013年 Mingliang Chen. All rights reserved.
//

#import "RtmpClient.h"


@implementation RtmpClient


void send_pkt(RTMP* pRtmp,char* buf, int buflen, int type, unsigned int timestamp)
{
    int ret;
    RTMPPacket rtmp_pakt;
    RTMPPacket_Reset(&rtmp_pakt);
    RTMPPacket_Alloc(&rtmp_pakt, buflen);
    rtmp_pakt.m_packetType = type;
    rtmp_pakt.m_nBodySize = buflen;
    rtmp_pakt.m_nTimeStamp = timestamp;
    rtmp_pakt.m_nChannel = 4;
    rtmp_pakt.m_headerType = RTMP_PACKET_SIZE_LARGE;
    rtmp_pakt.m_nInfoField2 = pRtmp->m_stream_id;
    memcpy(rtmp_pakt.m_body, buf, buflen);
    ret = RTMP_SendPacket(pRtmp, &rtmp_pakt, 0);
    RTMPPacket_Free(&rtmp_pakt);
}

-(id)initWithSampleRate:(int)sampleRate withEncoder:(int)audioEncoder
{
    self = [super init];
    if(self){
        mAudioRecord = [[AudioRecoder alloc] initWIthSampleRate:sampleRate];
        [mAudioRecord setOutDelegate:self];
        condition = [[NSCondition alloc] init];
    }
    return self;
}

-(void)setOutDelegate:(id<RtmpClientDelegate>)delegate
{
    outDelegate = delegate;
}

-(void)startPublishWithUrl:(NSString*) rtmpURL
{
    NSThread *thread = [[NSThread alloc]initWithTarget:self selector:@selector(openPublishThread:) object:rtmpURL];
    [thread start];
}
-(void)stopPublish
{
    [condition lock];
    [condition signal];
    [condition unlock];
}

-(void)startPlayWithUrl:(NSString*) rtmpURL
{
    if(isStartPub) return;
    NSThread *thread = [[NSThread alloc]initWithTarget:self selector:@selector(openPlayThread:) object:rtmpURL];
    [thread start];
}
-(void)stopPlay
{
    
}

-(void)openPublishThread:(NSString*) rtmpUrl
{
    int compression = 6,sample_rate;
    do {
        isStartPub = YES;
        if(outDelegate)
        {
            [outDelegate EventCallback:1000];
        }
        //1 init speex encoder
        speex_bits_init(&ebits);
        enc_state = speex_encoder_init(&speex_wb_mode);
        speex_encoder_ctl(enc_state, SPEEX_SET_QUALITY, &compression);
        speex_encoder_ctl(enc_state, SPEEX_GET_FRAME_SIZE, &enc_frame_size);
        speex_encoder_ctl(enc_state, SPEEX_GET_SAMPLING_RATE, &sample_rate);
        pcm_buffer = malloc(enc_frame_size * sizeof(short));
        output_buffer = malloc(enc_frame_size * sizeof(char));
        NSLog(@"Speex Encoder init,enc_frame_size:%d sample_rate:%d\n", enc_frame_size, sample_rate);
        
        //2 init rtmp
        pPubRtmp = RTMP_Alloc();
        RTMP_Init(pPubRtmp);
        if(!RTMP_SetupURL(pPubRtmp, (char*)[rtmpUrl UTF8String]))
        {
            NSLog(@"RTMP_SetupURL error");
            if(outDelegate)
            {
                [outDelegate EventCallback:1002];
            }
            break; 
        }
        RTMP_EnableWrite(pPubRtmp);
        NSLog(@"RTMP_EnableWrite");
        if (!RTMP_Connect(pPubRtmp, NULL) || !RTMP_ConnectStream(pPubRtmp, 0)) {
            NSLog(@"RTMP_Connect or RTMP_ConnectStream error!");
            if(outDelegate)
            {
                [outDelegate EventCallback:1002];
            }
            break;
        }
        NSLog(@"RTMP_Connected");
        [mAudioRecord startRecord];
        if(outDelegate)
        {
            [outDelegate EventCallback:1001];
        }
        
    } while (0);
    [condition lock];
    [condition wait];
    [condition unlock];
    isStartPub = NO;
    NSLog(@"Stop Publish start release");
    [mAudioRecord stopRecord];
    if (RTMP_IsConnected(pPubRtmp)) {
        RTMP_Close(pPubRtmp);
    }
    RTMP_Free(pPubRtmp);
    free(pcm_buffer);
    free(output_buffer);
    speex_bits_destroy(&ebits);
    speex_encoder_destroy(enc_state);
    if(outDelegate)
    {
        [outDelegate EventCallback:1004];
    }
}

-(void)openPlayThread:(NSString*) rtmpUrl
{

}

-(void)AudioDataOutputBuffer:(char *)audioBuffer bufferSize:(int)size
{
    const char speex_head = '\xB6';
    speex_bits_reset(&ebits);
    memcpy(pcm_buffer, audioBuffer, enc_frame_size * sizeof(short));
    speex_encode_int(enc_state, pcm_buffer, &ebits);
    int enc_size = speex_bits_write(&ebits, output_buffer, enc_frame_size);
   // NSLog(@"AudioDataOutputBuffer size=%d  encSize=%d",size,enc_size);
    char* send_buf = malloc(enc_size + 1);
    memcpy(send_buf, &speex_head, 1);
    memcpy(send_buf + 1, output_buffer, enc_size);
    send_pkt(pPubRtmp,send_buf, enc_size + 1, RTMP_PACKET_TYPE_AUDIO, pubTs += 20);
    free(send_buf);
}


@end
