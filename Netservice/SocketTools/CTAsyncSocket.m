//
//  CTAsyncSocket.m
//  QianbaoIM
//
//  Created by fengsh on 17/5/15.
//  Copyright (c) 2015年 qianbao.com. All rights reserved.
//

#import "CTAsyncSocket.h"
#import "GCDAsyncSocket.h"

@interface CTAsyncSocket()<GCDAsyncSocketDelegate>
{
    GCDAsyncSocket          *_imsocket;
}
@end

@implementation CTAsyncSocket

- (id)init
{
    self = [super init];
    if (self) {
        dispatch_queue_t queue          = dispatch_queue_create("com.fengsh.dispatchqueue", 0);
        dispatch_queue_t socketqueue    = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        _imsocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:queue
                                                socketQueue:socketqueue];
    }
    return self;
}

- (void)dealloc
{
    [_imsocket setDelegate:nil delegateQueue:NULL];
    [_imsocket disconnect];
}

- (BOOL)connectSocketHost:(NSString*)host atPort:(uint16_t)port
{
    NSError *error = nil;
    BOOL ok = [_imsocket connectToHost:host onPort:port error:&error];
    if (!ok) {
        NSLog(@"Socket Connect Error : %@",error);
    }
    
    return ok;
}

- (void)sendPacket:(NSData *)packet withTag:(long)tag
{
    if ([packet length] == 0)
    {
        return;
    }
    
    [_imsocket writeData:packet withTimeout:-1 tag:tag];
}

///断开连接
- (void)disconnect
{
    [_imsocket disconnect];
}

///是否已连接
- (BOOL)isConnected
{
    return _imsocket.isConnected;
}

#pragma mark - GCDAsyncSocketDelegate
///成功连接上
- (void)socket:(GCDAsyncSocket *)sender didConnectToHost:(NSString *)host port:(UInt16)port
{
    if ([_delegate respondsToSelector:@selector(socketDidConnectFinish:withHost:withport:)]) {
        [_delegate socketDidConnectFinish:self withHost:host withport:port];
    }
    [_imsocket readDataWithTimeout:-1 tag:0];
}

///接收到数据时
- (void)socket:(GCDAsyncSocket *)sender didReadData:(NSData *)data withTag:(long)tag
{
    if ([_delegate respondsToSelector:@selector(socket:didReceivedData:withTag:)]) {
        [_delegate socket:self didReceivedData:data withTag:tag];
    }
    
    [_imsocket readDataWithTimeout:-1 tag:tag];
}


- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"write data :tag = %ld",tag);
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    if ([_delegate respondsToSelector:@selector(socketDidDisconnect:withError:)]) {
        [_delegate socketDidDisconnect:self withError:err];
    }
}
@end
