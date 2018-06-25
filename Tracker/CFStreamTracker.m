//
//  CFStreamTracker.m
//  FortunePlat
//
//  Created by sgcy on 2018/6/20.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "CFStreamTracker.h"
#import "fishhook.h"
#import <CFNetwork/CFNetwork.h>


@implementation CFStreamTracker

void* (*origin_CFURLConnectionCreate)(CFAllocatorRef allocator, void* request, const void *ctx);
void (*origin_CFURLConnectionStart)(void * connection);

Boolean (*origin_CFReadStreamSetClient)(CFReadStreamRef stream, CFOptionFlags streamEvents, CFReadStreamClientCallBack clientCB, CFStreamClientContext *clientContext);
Boolean (*origin_CFWriteStreamSetClient)(CFWriteStreamRef stream, CFOptionFlags streamEvents, CFWriteStreamClientCallBack clientCB, CFStreamClientContext *clientContext);

Boolean (*origin_CFReadStreamOpen)(CFReadStreamRef stream);
Boolean (*origin_CFWriteStreamOpen)(CFWriteStreamRef stream);

CFIndex (*origin_CFReadStreamRead)(CFReadStreamRef stream, UInt8 *buffer, CFIndex bufferLength);
CFIndex (*origin_CFWriteStreamWrite)(CFWriteStreamRef stream, const UInt8 *buffer, CFIndex bufferLength);

+ (void)load
{
    int result = rcd_rebind_symbols((struct rcd_rebinding[8]){
        {
            "CFReadStreamRead",
            objc_CFReadStreamRead,
            (void *)&origin_CFReadStreamRead
        },
        {
            "CFWriteStreamWrite",
            objc_CFWriteStreamWrite,
            (void *)&origin_CFWriteStreamWrite
        },
        {
            "CFReadStreamOpen",
            objc_CFReadStreamOpen,
            (void *)&origin_CFReadStreamOpen
        },
        {
            "CFWriteStreamOpen",
            objc_CFWriteStreamOpen,
            (void *)&origin_CFWriteStreamOpen
        },
        {
            "CFReadStreamSetClient",
            objc_CFReadStreamSetClient,
            (void *)&origin_CFReadStreamSetClient
        },
        {
            "CFWriteStreamSetClient",
            objc_CFWriteStreamSetClient,
            (void *)&origin_CFWriteStreamSetClient
        },
        {
            "CFURLConnectionCreate",
            objc_CFURLConnectionCreate,
            (void *)&origin_CFURLConnectionCreate
        },
        {
            "CFURLConnectionStart",
            objc_CFURLConnectionStart,
            (void *)&origin_CFURLConnectionStart
        }
    }, 8);
    NSLog(@"%d",result);
}

void* objc_CFURLConnectionCreate(CFAllocatorRef allocator, void *request, const void *ctx)
{
    void *result = origin_CFURLConnectionCreate(allocator,request,ctx);
    return result;
}

void objc_CFURLConnectionStart(void *connection)
{
    return origin_CFURLConnectionStart(connection);
}

Boolean objc_CFWriteStreamSetClient(CFWriteStreamRef stream, CFOptionFlags streamEvents, CFWriteStreamClientCallBack clientCB, CFStreamClientContext *clientContext)
{
    Boolean result = origin_CFWriteStreamSetClient(stream,streamEvents,clientCB,clientContext);
    [CFStreamTracker trackEvent:[[TrackEvent alloc] initWithType:TrackerEventTypeCFRequestOpen stream:stream]];
    return result;
}

Boolean objc_CFReadStreamSetClient(CFReadStreamRef stream, CFOptionFlags streamEvents, CFReadStreamClientCallBack clientCB, CFStreamClientContext *clientContext)
{
    Boolean result = origin_CFReadStreamSetClient(stream,streamEvents,clientCB,clientContext);
    [CFStreamTracker trackEvent:[[TrackEvent alloc] initWithType:TrackerEventTypeCFResponseOpen stream:stream]];
    return result;
}

static Boolean objc_CFWriteStreamOpen(CFWriteStreamRef stream)
{
    BOOL open = origin_CFWriteStreamOpen(stream);
    [CFStreamTracker trackEvent:[[TrackEvent alloc] initWithType:TrackerEventTypeCFRequestOpen stream:stream]];
    return open;
}

static Boolean objc_CFReadStreamOpen(CFReadStreamRef stream)
{
    BOOL open = origin_CFReadStreamOpen(stream);
    [CFStreamTracker trackEvent:[[TrackEvent alloc] initWithType:TrackerEventTypeCFResponseOpen stream:stream]];
    return open;
}

static CFIndex objc_CFReadStreamRead(CFReadStreamRef stream, UInt8 *buffer, CFIndex bufferLength)
{
    
    CFIndex index = origin_CFReadStreamRead(stream,buffer,bufferLength);
    [CFStreamTracker trackEvent:[[TrackEvent alloc] initWithType:TrackerEventTypeCFRequest buffer:buffer length:bufferLength stream:stream]];
    return index;
}

static CFIndex objc_CFWriteStreamWrite(CFWriteStreamRef stream, const UInt8 *buffer, CFIndex bufferLength)
{
    CFIndex index = origin_CFWriteStreamWrite(stream,buffer,bufferLength);
    [CFStreamTracker trackEvent:[[TrackEvent alloc] initWithType:TrackerEventTypeCFResponse buffer:buffer length:bufferLength stream:stream]];
    return index;
}

@end
