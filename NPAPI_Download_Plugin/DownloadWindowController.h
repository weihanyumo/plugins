//
//  DownloadWindowController.h
//  NPAPI_Download_Plugin
//
// Created by TanHao on 13-2-22.
// Copyright (c) 2012年 http://www.tanhao.me. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DownloadWindowController : NSWindowController
{
    NSString *url;
    IBOutlet NSTextField *urlField;
}

@property (nonatomic, retain) NSString *url;

@end
