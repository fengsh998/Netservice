//
//  CTAFHttpRequest.m
//  QianbaoIM
//
//  Created by fengsh on 18/4/15.
//  Copyright (c) 2015年 fengsh. All rights reserved.
//

#import "CTAFHttpRequest.h"
#import "AFNetworking.h"
//扩展AF
#import "AFDownloadRequestOperation.h"
#import "CTHttpCookies.h"

#pragma mark - 引擎实现
///使用AFNetWorking第三方库进行实现
@interface CTAFHttpEngine()
{
    //负责平常的小数据量的请求(GET,POST...)
    AFHTTPRequestOperationManager           *_manager;
    //负责对大文件的上传下载的线程管理
    AFHTTPRequestOperationManager           *_transferManager;
    
    NSDictionary                            *_method_dic;
}
@property (nonatomic, strong) NSMutableDictionary               *reqeusts;
@end

@implementation CTAFHttpEngine

#pragma mark - 单例
+ (instancetype)shareAFHttpEngine
{
    static CTAFHttpEngine *afengineInstance = nil;
    static dispatch_once_t afengine = 0;
    
    dispatch_once(&afengine, ^{
        afengineInstance = [[CTAFHttpEngine alloc]init];
    });
    
    return afengineInstance;
}

#pragma mark - 初始化/释放
- (id)init
{
    if (self = [super init])
    {
        self.reqeusts = [NSMutableDictionary dictionary];
        _method_dic = @{@(httpPost):@"POST",
                        @(httpGet):@"GET",
                        @(httpDelete):@"DELETE",
                        @(httpHead):@"HEAD",
                        @(httpPut):@"PUT"};//key-vlaue
    }
    return self;
}

- (void)dealloc
{
    //生命结束前，需要取消所有请求。
    [self cancelAllRequest];
}

#pragma mark - 成员函数
///构键普通请求
- (NSMutableURLRequest *)buildThreadSafeRequest:(CTHttpRequest *)request
{
    //头域
    NSMutableURLRequest *rq = [[NSMutableURLRequest alloc]initWithURL:request.url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:request.timeout];
    
    [self convertRequestHeader:request toMutableRequest:rq];
    
    return rq;
}

- (void)convertRequestHeader:(CTHttpRequest *)request toMutableRequest:(NSMutableURLRequest *)mtbrequest
{
    [request.requestHeaders enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [mtbrequest setValue:obj forHTTPHeaderField:key];
    }];
    
    //是否带cookie
    if (request.useCookies) {
        NSDictionary *cookies = [[CTHttpCookies shareCookies]findHttpRequestCookiesForRequestURL:request.url];
        [cookies enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [mtbrequest setValue:obj forHTTPHeaderField:key];
        }];
    }
}

- (NSString *)convertRequestIDToString:(CTHttpRequestID )reqid
{
    return [NSString stringWithFormat:@"%lu",(unsigned long)reqid];
}

///通过请求id查找相应的操作请求
- (AFHTTPRequestOperation *)getOperationRequest:(CTHttpRequestID )reqid
{
    NSString *key = [self convertRequestIDToString:reqid];
    return [self.reqeusts objectForKey:key];
}

#pragma mark - 延迟加载
///创建并发队列,不使用串行队列
- (AFHTTPRequestOperationManager*)manager
{
    if (!_manager) {
        _manager = [AFHTTPRequestOperationManager manager];
        _manager.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        _manager.completionGroup = dispatch_group_create();
        _manager.operationQueue.maxConcurrentOperationCount = 5;
    }
    return _manager;
}

- (AFHTTPRequestOperationManager*)transferManager
{
    if (!_transferManager) {
        _transferManager = [AFHTTPRequestOperationManager manager];
        _transferManager.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        _transferManager.completionGroup = dispatch_group_create();
        _transferManager.operationQueue.maxConcurrentOperationCount = 4;
    }
    return _transferManager;
}

#pragma mark - 发送请求
- (void)sendRequest:(CTHttpRequest *)request
{
    if ([request isKindOfClass:[CTAFHttpUploadRequest class]])
    {
        [self doSendUploadRequest:(CTAFHttpUploadRequest *)request];
    }
    else if ([request isKindOfClass:[CTAFHttpDownloadRequest class]])
    {
        [self doSendDownloadRequest:(CTAFHttpDownloadRequest *)request];
    }
    else
    {
        [self doSendNomalRequest:(CTAFHttpRequest *)request];
    }
}

#pragma mark - 普通请求
- (void)doSendNomalRequest:(CTAFHttpRequest *)request
{
    //构建下载的请求
    NSMutableURLRequest *urlreqeust = nil;
    
    NSString *methodstring = _method_dic[@(request.method)];
    
    //默认为GET
    if (methodstring.length == 0) {
        methodstring = @"GET";
    }
    
    NSError *serializationError = nil;
    
    if (request.useJsonFormat)
    {
        urlreqeust = [[AFJSONRequestSerializer serializer]requestWithMethod:methodstring URLString:request.url.absoluteString parameters:request.requestParams error:&serializationError];
    }
    else
    {
        urlreqeust = [[AFHTTPRequestSerializer serializer]requestWithMethod:methodstring URLString:request.url.absoluteString parameters:request.requestParams error:&serializationError];
    }
    
    //如果有错，直接返回错误
    if (serializationError) {
        if (request.failureCallBack) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
            dispatch_async(self.manager.completionQueue ?: dispatch_get_main_queue(), ^{
                request.failureCallBack(nil, serializationError);
            });
#pragma clang diagnostic pop
        }
        return;
    }
    
    if (request.cachepolicy != httpCachePolicyNone)
    {
        urlreqeust.cachePolicy = request.cachepolicy;
    }
    //设置超时
    [urlreqeust setTimeoutInterval:request.timeout];
    //设置头域
    [self convertRequestHeader:request toMutableRequest:urlreqeust];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:urlreqeust];
    operation.responseSerializer = request.useJsonFormat ? [AFJSONResponseSerializer serializer] : [AFHTTPResponseSerializer serializer];
    
    //对SSL进行处理
    if (request.security && request.isSSL)
    {
        AFSecurityPolicy *sp = nil;
        switch (request.security.sslPinningMode) {
            case CTSSLPinningModePublicKey:
            {
                sp = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
            }
                break;
            case CTSSLPinningModeCertificate:
            {
                sp = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
            }
                break;
            default:
                sp = [AFSecurityPolicy defaultPolicy];
                break;
        }
        operation.shouldUseCredentialStorage = request.security.shouldUseCredentialStorage;
        operation.credential = request.security.credential;
        
        sp.validatesCertificateChain = request.security.validatesCertificateChain;
        //暂不需要这个，使用默认
        //sp.validatesCertificateChain = request.security.pinnedCertificates;
        sp.allowInvalidCertificates  = request.security.allowInvalidCertificates;
        //sp.validatesDomainName       = request.security.validatesDomainName;

        operation.securityPolicy = sp;
    }
        
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self handleRequestResult:operation withResponseObj:responseObject withError:nil];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleRequestResult:operation withResponseObj:nil withError:error];
    }];
    
    operation.completionQueue = self.manager.completionQueue;
    operation.completionGroup = self.manager.completionGroup;
    
    //添加请求
    NSString *opkey = [NSString stringWithFormat:@"%lu", (unsigned long)[operation hash]];
    [self.reqeusts setObject:request forKey:opkey];
    [self.reqeusts setObject:operation forKey:[self convertRequestIDToString:request.requestid]];
    
    [self.manager.operationQueue addOperation:operation];
}

#pragma mark - 上传
- (void)doSendUploadRequest:(CTAFHttpUploadRequest *)request
{
    if (!request.postfromdataCallBack) {
        //没东西上传，走普通post吧
        [self doSendNomalRequest:(CTAFHttpRequest*)request];
        
        return;
    }
    
    NSString *methodstring = _method_dic[@(request.method)];
    
    //默认为POST
    if (methodstring.length == 0) {
        methodstring = @"POST";
    }
    
    NSError *serializationError = nil;
    NSMutableURLRequest *urlreqeust = nil;
    
    if (request.useJsonFormat) {

        urlreqeust = [[AFJSONRequestSerializer serializer]multipartFormRequestWithMethod:methodstring URLString:request.url.absoluteString parameters:request.requestParams constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            
            CTAFMutipartFormData *fd = [[CTAFMutipartFormData alloc]init];
            fd.delegate = formData;
            //request.formdata = fd;
            request.postfromdataCallBack(request,fd);
            
        } error:&serializationError];
    }
    else
    {
        urlreqeust = [[AFHTTPRequestSerializer serializer]multipartFormRequestWithMethod:methodstring URLString:request.url.absoluteString parameters:request.requestParams constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            
            CTAFMutipartFormData *fd = [[CTAFMutipartFormData alloc]init];
            fd.delegate = formData;
            //request.formdata = fd;
            request.postfromdataCallBack(request,fd);
            
        } error:&serializationError];
    }
    
    //如果有错，直接返回错误
    if (serializationError) {
        if (request.failureCallBack) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
            dispatch_async(self.transferManager.completionQueue ?: dispatch_get_main_queue(), ^{
                request.failureCallBack(nil, serializationError);
            });
#pragma clang diagnostic pop
        }
        return;
    }
    //设置超时
    [urlreqeust setTimeoutInterval:request.timeout];
    //设置头域
    [self convertRequestHeader:request toMutableRequest:urlreqeust];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:urlreqeust];
    operation.responseSerializer = request.useJsonFormat ? [AFJSONResponseSerializer serializer] : [AFHTTPResponseSerializer serializer];
    
    //对SSL进行处理
    if (request.security && request.isSSL)
    {
        AFSecurityPolicy *sp = nil;
        switch (request.security.sslPinningMode) {
            case CTSSLPinningModePublicKey:
            {
                sp = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
            }
                break;
            case CTSSLPinningModeCertificate:
            {
                sp = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
            }
                break;
            default:
                sp = [AFSecurityPolicy defaultPolicy];
                break;
        }
        operation.shouldUseCredentialStorage = request.security.shouldUseCredentialStorage;
        operation.credential = request.security.credential;
        
        sp.validatesCertificateChain = request.security.validatesCertificateChain;
        //暂不需要这个，使用默认
        //sp.validatesCertificateChain = request.security.pinnedCertificates;
        sp.allowInvalidCertificates  = request.security.allowInvalidCertificates;
        //sp.validatesDomainName       = request.security.validatesDomainName;
        
        operation.securityPolicy = sp;
    }
    
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        request.bytesOfCurrentTranfers = totalBytesExpectedToWrite;
        if (request.progressCallBack)
        {
            __weak CTAFHttpUploadRequest *_weakrequest = request;
            request.progressCallBack(_weakrequest,bytesWritten,totalBytesWritten,totalBytesExpectedToWrite);
        }
    }];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self handleRequestResult:operation withResponseObj:responseObject withError:nil];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleRequestResult:operation withResponseObj:nil withError:error];
    }];
    
    operation.completionQueue = self.transferManager.completionQueue;
    operation.completionGroup = self.transferManager.completionGroup;
    
    //添加请求
    NSString *opkey = [NSString stringWithFormat:@"%lu", (unsigned long)[operation hash]];
    [self.reqeusts setObject:request forKey:opkey];
    [self.reqeusts setObject:operation forKey:[self convertRequestIDToString:request.requestid]];
    
    [self.transferManager.operationQueue addOperation:operation];
}

#pragma mark - 下载(支持断点下载)
- (void)doSendDownloadRequest:(CTAFHttpDownloadRequest *)request
{
    //构建下载的请求
    NSMutableURLRequest *urlreqeust = [self buildThreadSafeRequest:request];
    
    AFDownloadRequestOperation *operation = [[AFDownloadRequestOperation alloc] initWithRequest:urlreqeust
                                                                                     targetPath:request.downloadPath shouldResume:YES];
    
    //对SSL进行处理
    if (request.security && request.isSSL)
    {
        AFSecurityPolicy *sp = nil;
        switch (request.security.sslPinningMode) {
            case CTSSLPinningModePublicKey:
            {
                sp = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
            }
                break;
            case CTSSLPinningModeCertificate:
            {
                sp = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
            }
                break;
            default:
                sp = [AFSecurityPolicy defaultPolicy];
                break;
        }
        operation.shouldUseCredentialStorage = request.security.shouldUseCredentialStorage;
        operation.credential = request.security.credential;
        
        sp.validatesCertificateChain = request.security.validatesCertificateChain;
        //暂不需要这个，使用默认
        //sp.validatesCertificateChain = request.security.pinnedCertificates;
        sp.allowInvalidCertificates  = request.security.allowInvalidCertificates;
        //sp.validatesDomainName       = request.security.validatesDomainName;
        
        operation.securityPolicy = sp;
    }
    
    [operation setProgressiveDownloadProgressBlock:^(AFDownloadRequestOperation *operation, NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpected, long long totalBytesReadForFile, long long totalBytesExpectedToReadForFile)
    {
        request.bytesOfCurrentTranfers = totalBytesReadForFile;
        if (request.progressCallBack)
        {
            //防止retain cycle.
            __weak CTAFHttpDownloadRequest *_weakrequest = request;
            request.progressCallBack(_weakrequest,totalBytesExpected,totalBytesReadForFile,totalBytesExpectedToReadForFile);
        }
    }];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self handleRequestResult:operation withResponseObj:responseObject withError:nil];
    }                                failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleRequestResult:operation withResponseObj:nil withError:nil];
    }];
    
    operation.completionGroup = self.transferManager.completionGroup;
    operation.completionQueue = self.transferManager.completionQueue;
    
    //添加请求
    NSString *opkey = [NSString stringWithFormat:@"%lu", (unsigned long)[operation hash]];
    [self.reqeusts setObject:request forKey:opkey];
    [self.reqeusts setObject:operation forKey:[self convertRequestIDToString:request.requestid]];
    //添加到上传下载的队列
    [self.transferManager.operationQueue addOperation:operation];
}

#pragma mark - 回调
- (void)handleRequestResult:(AFHTTPRequestOperation *)operation withResponseObj:(id)responseobj
                  withError:(NSError *)error
{
    NSString *opkey = [NSString stringWithFormat:@"%lu", (unsigned long)[operation hash]];
    CTHttpRequest *req = [self.reqeusts objectForKey:opkey];
    
    if (!req) {
        return;
    }
    
    NSString *removereqid = [self convertRequestIDToString:req.requestid];
    
    CTHttpResponse *response = [[CTHttpResponse alloc]init];
    response.allResponseHeaders = operation.response.allHeaderFields;
    response.statuscode = operation.response.statusCode;
    response.responseObject   = responseobj;
    response.contextRequestid = req.requestid;
    
    req.response = response;
    req.requestHeaders = operation.request.allHTTPHeaderFields;
    
    if (!error) {
        if (req.useCookies)
        {
            [[CTHttpCookies shareCookies]storeHttpResponseCookies:operation.response.allHeaderFields forRequestURL:operation.request.URL];
        }
        
        if (req.successCallBack)
        {
            __weak CTHttpRequest *_weak_req = req;
            req.successCallBack(_weak_req);
        }
    }
    else
    {
        if (req.failureCallBack)
        {
            __weak CTHttpRequest *_weak_req = req;
            req.failureCallBack(_weak_req,error);
        }
    }
    
    [self.reqeusts removeObjectForKey:opkey];
    [self.reqeusts removeObjectForKey:removereqid];
}

#pragma mark - 请求控制
- (void)supendRequest:(CTHttpRequest *)request
{
    AFHTTPRequestOperation *operation = [self getOperationRequest:request.requestid];
    if (operation) {
        [operation pause];
    }
}

- (void)resumeRequest:(CTHttpRequest *)request
{
    AFHTTPRequestOperation *operation = [self getOperationRequest:request.requestid];
    if (operation) {
        [operation resume];
    }
}

/**
 *  注意在取消时不能进行 remove self.reqeusts 中的元素，因为这样会使用线程回调未完成，但线程被加收了。
 *  不要担心没有remove的情况。因为cancel后会走回调，在回调中有remove从而使得线程可以正常回收
 */

- (void)cancelRequest:(CTHttpRequest *)request
{
    AFHTTPRequestOperation *operation = [self getOperationRequest:request.requestid];
    if (operation)
    {
        [operation cancel];
    }
}

- (void)cancelAllRequest
{
    [[self.manager operationQueue]cancelAllOperations];
    [[self.transferManager operationQueue]cancelAllOperations];
}

@end

@implementation CTAFMutipartFormData

- (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                         name:(NSString *)name
                        error:(NSError * __autoreleasing *)error
{
    if (self.delegate) {
        return [self.delegate appendPartWithFileURL:fileURL name:name error:error];
    }
    return NO;
}

- (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                         name:(NSString *)name
                     fileName:(NSString *)fileName
                     mimeType:(NSString *)mimeType
                        error:(NSError * __autoreleasing *)error
{
    if (self.delegate) {
        return [self.delegate appendPartWithFileURL:fileURL name:name fileName:fileName mimeType:mimeType error:error];
    }
    return NO;
}

- (void)appendPartWithFileData:(NSData *)data
                          name:(NSString *)name
                      fileName:(NSString *)fileName
                      mimeType:(NSString *)mimeType
{
    if (self.delegate) {
        [self.delegate appendPartWithFileData:data name:name fileName:fileName mimeType:mimeType];
    }
}

- (void)appendPartWithHeaders:(NSDictionary *)headers
                         body:(NSData *)body
{
    if (self.delegate) {
        [self.delegate appendPartWithHeaders:headers body:body];
    }
}

@end

#pragma mark - 普通请求(实现)
@implementation CTAFHttpRequest

#pragma mark - 使用延时setter, getter方式
- (CTSecurityPolicy *)security
{
    if (!(_security)) {
        _security = [[CTSecurityPolicy alloc]init];
    }
    return _security;
}

- (void)setSecurity:(CTSecurityPolicy *)sec
{
    _security = sec;
}

- (id)copyWithZone:(NSZone *)zone
{
    CTAFHttpRequest *afrequest = [super copyWithZone:zone];
    return afrequest;
}

- (void)dealloc
{
#if DEBUG
    NSLog(@"普通请求 remove or cancel时 正常 free.");
#endif
}

- (void)go
{
  
    [[CTAFHttpEngine shareAFHttpEngine]sendRequest:self];
}

- (void)cancel
{
    [[CTAFHttpEngine shareAFHttpEngine]cancelRequest:self];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ <%p> : {requestid : %lu ,url : %@ ,tag : %ld ,\
timeout : %f ,method : %ld ,useCookies : %@ ,requestHeaders : %@ ,response : %@ ,\
requestParams : %@ ,useJsonFormat : %@ }",[self class],self,(unsigned long)self.requestid,self.url,self.tag,
            self.timeout,(long)self.method,self.useCookies ? @"YES" : @"NO",self.requestHeaders,
            self.response,self.requestParams,self.useJsonFormat ? @"YES" : @"NO"];

}

@end

#pragma mark - 上传请求(实现)
@implementation CTAFHttpUploadRequest

#pragma mark - 使用延时setter, getter方式
- (CTSecurityPolicy *)security
{
    if (!(_security)) {
        _security = [[CTSecurityPolicy alloc]init];
    }
    return _security;
}

- (void)setSecurity:(CTSecurityPolicy *)sec
{
    _security = sec;
}

- (instancetype)initWithURLString:(NSString *)url
{
    if (self = [super initWithURLString:url]) {
        self.method = httpPost;
    }
    return self;
}

- (void)dealloc
{
#if DEBUG
    NSLog(@"上传请求 remove or cancel时 正常 free.");
#endif
}

- (id)copyWithZone:(NSZone *)zone
{
    CTAFHttpUploadRequest *afuploadrequest = [super copyWithZone:zone];

    [afuploadrequest setUploadProgress:self.progressCallBack];
    
    return afuploadrequest;
}

- (void)go
{
    [[CTAFHttpEngine shareAFHttpEngine]sendRequest:self];
}

- (void)cancel
{
    [[CTAFHttpEngine shareAFHttpEngine]cancelRequest:self];
}

- (void)supend
{
    [[CTAFHttpEngine shareAFHttpEngine]supendRequest:self];
}

- (void)resume
{
    [[CTAFHttpEngine shareAFHttpEngine]resumeRequest:self];
}

- (void)setUploadProgress:(Progressing)progress
{
    _progressCallBack = [progress copy];
}

- (void)setPostFormdataBlock:(PostFormData)formdata
{
    _postfromdataCallBack = formdata;
}

- (long long int)sizeOfTranferedTotalBytes
{
    return _bytesOfCurrentTranfers;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ <%p> : {requestid : %lu ,url : %@ ,tag : %ld ,\
            timeout : %f ,method : %ld ,useCookies : %@ ,requestHeaders : %@ ,response : %@ ,\
            requestParams : %@ ,useJsonFormat : %@ }",[self class],self,(unsigned long)self.requestid,self.url,(long)self.tag,
            self.timeout,(long)self.method,self.useCookies ? @"YES" : @"NO",self.requestHeaders,
            self.response,self.requestParams,self.useJsonFormat ? @"YES" : @"NO"];
    
}

@end


#pragma mark - 下载请求(实现)
@implementation CTAFHttpDownloadRequest

#pragma mark - 使用延时setter, getter方式
- (CTSecurityPolicy *)security
{
    if (!(_security)) {
        _security = [[CTSecurityPolicy alloc]init];
    }
    return _security;
}

- (void)setSecurity:(CTSecurityPolicy *)sec
{
    _security = sec;
}

- (id)copyWithZone:(NSZone *)zone
{
    CTAFHttpDownloadRequest *afdownloadrequest  = [super copyWithZone:zone];
    afdownloadrequest.isResumeBreakpoint        = self.isResumeBreakpoint;
    afdownloadrequest.downloadPath              = [self.downloadPath copy];
    afdownloadrequest.storeFileName             = [self.storeFileName copy];
    [afdownloadrequest setDownloadProgress:self.progressCallBack];
    
    return afdownloadrequest;
}

- (instancetype)initWithURLString:(NSString *)url
{
    if (self = [super initWithURLString:url]) {
        self.method = httpGet;
    }
    return self;
}

- (void)dealloc
{
#if DEBUG
    NSLog(@"下载请求 remove or cancel时 正常 free.");
#endif
}

- (void)go
{
    [[CTAFHttpEngine shareAFHttpEngine]sendRequest:self];
}

- (void)cancel
{
    [[CTAFHttpEngine shareAFHttpEngine]cancelRequest:self];
}

- (void)supend
{
    [[CTAFHttpEngine shareAFHttpEngine]supendRequest:self];
}

- (void)resume
{
    [[CTAFHttpEngine shareAFHttpEngine]resumeRequest:self];
}

- (void)setDownloadProgress:(Progressing)progress
{
    _progressCallBack = [progress copy];
}

- (long long int)sizeOfTranferedTotalBytes
{
    return _bytesOfCurrentTranfers;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ <%p> : {requestid : %lu ,url : %@ ,tag : %ld ,\
            timeout : %f ,method : %ld ,useCookies : %@ ,requestHeaders : %@ ,response : %@ ,\
            requestParams : %@ ,useJsonFormat : %@ ,isResumeBreakpoint : %@ ,downloadPath : %@ ,\
            storeFileName : %@ }",[self class],self,(unsigned long)self.requestid,self.url,self.tag,
            self.timeout,(long)self.method,self.useCookies ? @"YES" : @"NO",self.requestHeaders,
            self.response,self.requestParams,self.useJsonFormat ? @"YES" : @"NO",
            self.isResumeBreakpoint ? @"YES" : @"NO",self.downloadPath,self.storeFileName];
    
}

@end
