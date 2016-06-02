//
//  DownloadWindowController.m
//  NPAPI_Download_Plugin
//
// Created by TanHao on 13-2-22.
// Copyright (c) 2012年 http://www.tanhao.me. All rights reserved.
//

#import "DownloadWindowController.h"

@interface DownloadWindowController(){
    IBOutlet NSButton *btnTest;
}

@end
@implementation DownloadWindowController
@synthesize url;

- (id)init
{
    self = [super initWithWindowNibName:@"DownloadWindowController"];
    return self;
}

- (void)dealloc
{
    [super dealloc];
    int *test = malloc(100);
    free(test);
    
    [url release];
}

- (void)awakeFromNib
{
    if (url) {
        [urlField setStringValue:url];
    }
}

- (NSString *)url
{
    return url;
}

- (void)setUrl:(NSString *)aUrl
{
    if (aUrl != url) {
        if (url) {
            [url release];
        }
        url = [aUrl retain];
        [urlField setStringValue:url];
    }
}

- (IBAction)btnTestClicked:(id)sender
{
    NSButton *btn = sender;
    if ([btn.title isEqualToString:@"点击吧"])
    {
        [btn setTitle:@"点击了"];
    }
    else
    {
        [btn setTitle:@"点击吧"];
    }
}
@end
