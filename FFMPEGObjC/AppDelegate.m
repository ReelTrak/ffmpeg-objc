//
//  AppDelegate.m
//  FFMPEGObjC
//
//  Created by Peter Bødskov on 22/03/16.
//  Copyright © 2016 ReelTrak. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

AVFilterGraph *filterGraph;

char strbuf[512];
AVFilterGraph *filter_graph = NULL;
AVFilterContext *abuffer_ctx = NULL;
AVFilterContext *volume_ctx = NULL;
AVFilterContext *aformat_ctx = NULL;
AVFilterContext *abuffersink_ctx = NULL;

AVFrame *oframe = NULL;

int init_filter_graph(AVFormatContext *ic, AVStream *audio_st) {
    // create new graph
    
    filterGraph = avfilter_graph_alloc();
    if (!filterGraph) {
        av_log(NULL, AV_LOG_ERROR, "unable to create filter graph: out of memory\n");
        return -1;
    }
    
    AVFilter *abuffer = avfilter_get_by_name("abuffer");
    AVFilter *volume = avfilter_get_by_name("volume");
    AVFilter *aformat = avfilter_get_by_name("aformat");
    AVFilter *abuffersink = avfilter_get_by_name("abuffersink");
    
    int err;
    // create abuffer filter
    AVCodecContext *avctx = audio_st->codec;
    AVRational time_base = audio_st->time_base;
    snprintf(strbuf, sizeof(strbuf),
             "time_base=%d/%d:sample_rate=%d:sample_fmt=%s:channel_layout=0x%"PRIx64,
             time_base.num, time_base.den, avctx->sample_rate,
             av_get_sample_fmt_name(avctx->sample_fmt),
             avctx->channel_layout);
    fprintf(stderr, "abuffer: %s\n", strbuf);
    err = avfilter_graph_create_filter(&abuffer_ctx, abuffer,
                                       NULL, strbuf, NULL, filter_graph);
    if (err < 0) {
        av_log(NULL, AV_LOG_ERROR, "error initializing abuffer filter\n");
        return err;
    }
    // create volume filter
    double vol = 0.90;
    snprintf(strbuf, sizeof(strbuf), "volume=%f", vol);
    fprintf(stderr, "volume: %s\n", strbuf);
    err = avfilter_graph_create_filter(&volume_ctx, volume, NULL,
                                       strbuf, NULL, filter_graph);
    if (err < 0) {
        av_log(NULL, AV_LOG_ERROR, "error initializing volume filter\n");
        return err;
    }
    // create aformat filter
    snprintf(strbuf, sizeof(strbuf),
             "sample_fmts=%s:sample_rates=%d:channel_layouts=0x%"PRIx64,
             av_get_sample_fmt_name(AV_SAMPLE_FMT_S16), 44100,
             (uint64_t)AV_CH_LAYOUT_STEREO);
    fprintf(stderr, "aformat: %s\n", strbuf);
    err = avfilter_graph_create_filter(&aformat_ctx, aformat,
                                       NULL, strbuf, NULL, filter_graph);
    if (err < 0) {
        av_log(NULL, AV_LOG_ERROR, "unable to create aformat filter\n");
        return err;
    }
    // create abuffersink filter
    err = avfilter_graph_create_filter(&abuffersink_ctx, abuffersink,
                                       NULL, NULL, NULL, filter_graph);
    if (err < 0) {
        av_log(NULL, AV_LOG_ERROR, "unable to create aformat filter\n");
        return err;
    }
    
    // connect inputs and outputs
    if (err >= 0) err = avfilter_link(abuffer_ctx, 0, volume_ctx, 0);
    if (err >= 0) err = avfilter_link(volume_ctx, 0, aformat_ctx, 0);
    if (err >= 0) err = avfilter_link(aformat_ctx, 0, abuffersink_ctx, 0);
    if (err < 0) {
        av_log(NULL, AV_LOG_ERROR, "error connecting filters\n");
        return err;
    }
    err = avfilter_graph_config(filter_graph, NULL);
    if (err < 0) {
        av_log(NULL, AV_LOG_ERROR, "error configuring the filter graph\n");
        return err;
    }
    return 0;
}

static int audio_decode_frame(AVFormatContext *ic, AVStream *audio_st,
                              AVPacket *pkt, AVFrame *frame)
{
    AVPacket pkt_temp_;
    memset(&pkt_temp_, 0, sizeof(pkt_temp_));
    AVPacket *pkt_temp = &pkt_temp_;
    
    *pkt_temp = *pkt;
    
    int len1, got_frame;
    int new_packet = 1;
    while (pkt_temp->size > 0 || (!pkt_temp->data && new_packet)) {
        avcodec_get_frame_defaults(frame);
        new_packet = 0;
        
        len1 = avcodec_decode_audio4(audio_st->codec, frame, &got_frame, pkt_temp);
        if (len1 < 0) {
            // if error we skip the frame
            pkt_temp->size = 0;
            return -1;
        }
        
        pkt_temp->data += len1;
        pkt_temp->size -= len1;
        
        if (!got_frame) {
            // stop sending empty packets if the decoder is finished
            if (!pkt_temp->data &&
                audio_st->codec->codec->capabilities&CODEC_CAP_DELAY)
            {
                return 0;
            }
            continue;
        }
        
        // push the audio data from decoded frame into the filtergraph
        int err = av_buffersrc_write_frame(abuffer_ctx, frame);
        if (err < 0) {
            av_log(NULL, AV_LOG_ERROR, "error writing frame to buffersrc\n");
            return -1;
        }
        // pull filtered audio from the filtergraph
        for (;;) {
            int err = av_buffersink_get_frame(abuffersink_ctx, oframe);
            if (err == AVERROR_EOF || err == AVERROR(EAGAIN))
                break;
            if (err < 0) {
                av_log(NULL, AV_LOG_ERROR, "error reading buffer from buffersink\n");
                return -1;
            }
            int nb_channels = av_get_channel_layout_nb_channels(oframe->channel_layout);
            int bytes_per_sample = av_get_bytes_per_sample(oframe->format);
            int data_size = oframe->nb_samples * nb_channels * bytes_per_sample;
//            ao_play(device, (void*)oframe->data[0], data_size);
        }
        return 0;
    }
    return 0;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
//    self.filterGraph = avfilter_graph_alloc();
    
    av_register_all();
    avcodec_register_all();
    avformat_network_init();
    avfilter_register_all();
    
    //Open file
    NSString *urlString = [[NSBundle mainBundle] pathForResource:@"bass" ofType:@"mp3"];
    NSLog(@"urlstring %@", urlString);
    AVFormatContext* pFormatCtx = avformat_alloc_context();
    if(avformat_open_input(&pFormatCtx, [urlString cStringUsingEncoding:NSASCIIStringEncoding], NULL, NULL) != 0) {
        NSLog(@"Error opening");
    }
    
    
    
    NSLog(@"after");
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
