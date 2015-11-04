//
//  CTAsyncSocket.h
//  QianbaoIM
//
//  Created by fengsh on 17/5/15.
//  Copyright (c) 2015年 qianbao.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CTAsyncSocket;

@protocol CTAsyncSocketDelegate <NSObject>

- (void)socketDidConnectFinish:(CTAsyncSocket *)socket withHost:(NSString *)host withport:(uint16_t)port;
- (void)socketDidDisconnect:(CTAsyncSocket *)socket withError:(NSError *)err;
- (void)socket:(CTAsyncSocket *)socket didReceivedData:(NSData *)data withTag:(long)tag;

@end

@interface CTAsyncSocket : NSObject
@property (nonatomic,weak)              id<CTAsyncSocketDelegate>       delegate;
@property (nonatomic,assign,readonly)   BOOL                            isConnected;

- (id)init;

- (BOOL)connectSocketHost:(NSString*)host atPort:(uint16_t)port;

- (void)sendPacket:(NSData *)packet withTag:(long)tag;

- (void)disconnect;


@end
