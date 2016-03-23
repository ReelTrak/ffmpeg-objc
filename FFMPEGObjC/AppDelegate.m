//
//  AppDelegate.m
//  FFMPEGObjC
//
//  Created by Peter Bødskov on 22/03/16.
//  Copyright © 2016 ReelTrak. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property AVFilterGraph *filterGraph;


@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
//    self.filterGraph = avfilter_graph_alloc();
    
    av_register_all();
    avcodec_register_all();
    avformat_network_init();
    
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
