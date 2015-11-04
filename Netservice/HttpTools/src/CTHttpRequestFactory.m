//
//  CTHttpRequestFactory.m
//  QianbaoIM
//
//  Created by fengsh on 13/4/15.
//  Copyright (c) 2015年 fengsh. All rights reserved.
//

#import "CTHttpRequestFactory.h"
///具体的实现类引用

#import "CTAFHttpRequest.h"

@implementation CTHttpRequestFactory

- (instancetype)initWithImplType:(APIType)type
{
    self = [super init];
    if (self) {
        _type = type;
    }
    return self;
}

- (void)setType:(APIType)type
{
    _type = type;
}

- (CTHttpRequest *)createRequest
{
    switch (_type) {
        case apiASIHttpRequest:
            return nil;
            break;
        case apiNSURLSession:
            return nil;
            break;
            
        default:
            return [[CTAFHttpRequest alloc]init];
            break;
    }
}

- (CTHttpUploadRequest *)createUploadRequest
{
    switch (_type) {
        case apiASIHttpRequest:
            return nil;
            break;
        case apiNSURLSession:
            return nil;
            break;
            
        default:
            return [[CTAFHttpUploadRequest alloc]init];
            break;
    }
}

- (CTHttpDownloadRequest *)createDownloadRequest
{
    switch (_type) {
        case apiASIHttpRequest:
            return nil;
            break;
        case apiNSURLSession:
            return nil;
            break;
            
        default:
            return [[CTAFHttpDownloadRequest alloc]init];
            break;
    }
}

@end