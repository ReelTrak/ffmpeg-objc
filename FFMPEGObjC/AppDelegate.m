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
    self.filterGraph = avfilter_graph_alloc();
    
    //Open file
    NSString *urlString = [[NSBundle mainBundle] pathForResource:@"bass" ofType:@"mp3"];
    NSLog(@"urlstring %@", urlString);
    AVFormatContext* pFormatCtx = avformat_alloc_context();
//    avformat_open_input(<#AVFormatContext **ps#>, <#const char *filename#>, <#AVInputFormat *fmt#>, <#AVDictionary **options#>)
    
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
