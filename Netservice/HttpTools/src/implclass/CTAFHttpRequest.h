//
//  CTAFHttpRequest.h
//  QianbaoIM
//
//  Created by fengsh on 18/4/15.
//  Copyright (c) 2015年 fengsh. All rights reserved.
//
/**
 *  低耦合模块，只与AFNetworking第三方库交互，增强维护性。
 *
 */

#import <Foundation/Foundation.h>

#import "CTHttpEngine.h"
#import "CTHttpDefine.h"

@interface CTAFHttpEngine : CTHttpEngineBase

+ (instancetype)shareAFHttpEngine;

- (void)sendRequest:(CTHttpRequest *)request;
- (void)supendRequest:(CTHttpRequest *)request;
- (void)resumeRequest:(CTHttpRequest *)request;

- (void)cancelRequest:(CTHttpRequest *)request;
- (void)cancelAllRequest;


@end


//***************************具体的请求对象实现****************************
@protocol AFMultipartFormData;

@interface CTAFMutipartFormData : NSObject<CTHttpMutipartFormData>
@property (nonatomic, assign) id<AFMultipartFormData> delegate;
@end

@interface CTAFHttpRequest : CTHttpRequest
{
    CTSecurityPolicy            *_security;
}
@end

@interface CTAFHttpUploadRequest : CTHttpUploadRequest
{
    CTSecurityPolicy            *_security;
}
//当前已传输了的字节数
@property (nonatomic, assign)   long long int           bytesOfCurrentTranfers;

@property (nonatomic, readonly) Progressing             progressCallBack;
@property (nonatomic, readonly) PostFormData            postfromdataCallBack;

@end

@interface CTAFHttpDownloadRequest : CTHttpDownloadRequest
{
    CTSecurityPolicy            *_security;
}
//当前已传输了的字节数
@property (nonatomic, assign)   long long int           bytesOfCurrentTranfers;
@property (nonatomic, readonly) Progressing             progressCallBack;

@end