//
//  CTHttpEngine.h
//  QianbaoIM
//
//  Created by fengsh on 18/4/15.
//  Copyright (c) 2015年 qianbao.com. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CTHttpRequest;

@interface CTHttpEngineBase : NSObject

- (void)sendRequest:(CTHttpRequest *)request;
- (void)cancelRequest:(CTHttpRequest *)request;
- (void)cancelAllRequest;

@end

