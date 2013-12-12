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

int bigFourByteToInt(char* bytes)
{
    int num = 0;
    num += (int) bytes[0] << 24;
    num += (int) bytes[1] << 16;
    num += (int) bytes[2] << 8;
    num += (int) bytes[3];
    return num;
}

int bigThreeByteToInt(char* bytes)
{
    int num = 0;
    num += (int) bytes[0] << 16;
    num += (int) bytes[1] << 8;
    num += (int) bytes[2];
    return num;
}

int bigTwoByteToInt(char* bytes)
{
    int num = 0;
    num += (int) bytes[0] << 8;
    num += (int) bytes[1];
    return num;
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
    if(isStartPub) return;
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
    if(isStartPlay) return;
    NSThread *thread = [[NSThread alloc]initWithTarget:self selector:@selector(openPlayThread:) object:rtmpURL];
    [thread start];
}
-(void)stopPlay
{
    isStartPlay = NO;
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
        NSLog(@"Publisher RTMP_Connected");
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
    short *output_buffer = NULL;
    do {
        if(outDelegate)
        {
            [outDelegate EventCallback:2000];
        }
        //1. init speex decoder
        speex_bits_init(&dbits);
        dec_state = speex_decoder_init(&speex_wb_mode);
        speex_decoder_ctl(dec_state, SPEEX_GET_FRAME_SIZE, &dec_frame_size);
        output_buffer = malloc(dec_frame_size * sizeof(short));
        
        NSLog(@"Init Speex decoder success frame_size = %d",dec_frame_size);
        
        //2. init rtmp
        pPlayRtmp = RTMP_Alloc();
        RTMP_Init(pPlayRtmp);
        NSLog(@"Play RTMP_Init %@\n", rtmpUrl);
        if (!RTMP_SetupURL(pPlayRtmp, (char*)[rtmpUrl UTF8String])) {
            NSLog(@"Play RTMP_SetupURL error\n");
            if(outDelegate)
            {
                [outDelegate EventCallback:2002];
            }
            break;
        }
        if (!RTMP_Connect(pPlayRtmp, NULL) || !RTMP_ConnectStream(pPlayRtmp, 0)) {
            NSLog(@"Play RTMP_Connect or RTMP_ConnectStream error\n");
            if(outDelegate)
            {
                [outDelegate EventCallback:2002];
            }
            break;
        }
        if(outDelegate)
        {
            [outDelegate EventCallback:2001];
        }
        NSLog(@"Player RTMP_Connected \n");
        RTMPPacket rtmp_pakt = { 0 };
        isStartPlay = YES;
        while (isStartPlay && RTMP_ReadPacket(pPlayRtmp, &rtmp_pakt)) {
            if (RTMPPacket_IsReady(&rtmp_pakt)) {
                if (!rtmp_pakt.m_nBodySize)
                    continue;
                if (rtmp_pakt.m_packetType == RTMP_PACKET_TYPE_AUDIO) {
                    // 处理音频数据包
                   // NSLog(@"AUDIO audio size:%d  head:%d  time:%d\n", rtmp_pakt.m_nBodySize, rtmp_pakt.m_body[0], rtmp_pakt.m_nTimeStamp);
                    speex_bits_read_from(&dbits, rtmp_pakt.m_body + 1, rtmp_pakt.m_nBodySize - 1);
                    speex_decode_int(dec_state, &dbits, output_buffer);
               //     putAudioQueue(output_buffer,dec_frame_size);
                } else if (rtmp_pakt.m_packetType == RTMP_PACKET_TYPE_VIDEO) {
                    // 处理视频数据包
                } else if (rtmp_pakt.m_packetType == RTMP_PACKET_TYPE_INFO) {
                    // 处理信息包
                } else if (rtmp_pakt.m_packetType == RTMP_PACKET_TYPE_FLASH_VIDEO) {
                    // 其他数据
                    int index = 0;
                    while (1) {
                        int StreamType; //1-byte
                        int MediaSize; //3-byte
                        int TiMMER; //3-byte
                        int Reserve; //4-byte
                        char* MediaData; //MediaSize-byte
                        int TagLen; //4-byte
                        
                        StreamType = rtmp_pakt.m_body[index];
                        index += 1;
                        MediaSize = bigThreeByteToInt(rtmp_pakt.m_body + index);
                        index += 3;
                        TiMMER = bigThreeByteToInt(rtmp_pakt.m_body + index);
                        index += 3;
                        Reserve = bigFourByteToInt(rtmp_pakt.m_body + index);
                        index += 4;
                        MediaData = rtmp_pakt.m_body + index;
                        index += MediaSize;
                        TagLen = bigFourByteToInt(rtmp_pakt.m_body + index);
                        index += 4;
                        //NSLog(@"bodySize:%d   index:%d",rtmp_pakt.m_nBodySize,index);
                        //LOGI("StreamType:%d MediaSize:%d  TiMMER:%d TagLen:%d\n", StreamType, MediaSize, TiMMER, TagLen);
                        if (StreamType == 0x08) {
                            //音频包
                            //int MediaSize = bigThreeByteToInt(rtmp_pakt.m_body+1);
                            //  LOGI("FLASH audio size:%d  head:%d time:%d\n", MediaSize, MediaData[0], TiMMER);
                            speex_bits_read_from(&dbits, MediaData + 1, MediaSize - 1);
                            speex_decode_int(dec_state, &dbits, output_buffer);
                          //  putAudioQueue(output_buffer,dec_frame_size);
                        } else if (StreamType == 0x09) {
                            //视频包
                            //  LOGI( "video size:%d  head:%d\n", MediaSize, MediaData[0]);
                        }
                        if (rtmp_pakt.m_nBodySize == index) {
                            //     LOGI("one pakt over\n");
                            break;
                        }
                    }
                }
                //  LOGI( "rtmp_pakt size:%d  type:%d\n", rtmp_pakt.m_nBodySize, rtmp_pakt.m_packetType);
                RTMPPacket_Free(&rtmp_pakt);
            }
        }
        if (isStartPlay) {
            if(outDelegate)
            {
                [outDelegate EventCallback:2005];
            }
            isStartPlay = NO;
        }
    } while (0);
    if(outDelegate)
    {
        [outDelegate EventCallback:2004];
    }
    if (RTMP_IsConnected(pPlayRtmp)) {
        RTMP_Close(pPlayRtmp);
    }
    RTMP_Free(pPlayRtmp);
    free(output_buffer);
    speex_bits_destroy(&dbits);
    speex_decoder_destroy(dec_state);
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
