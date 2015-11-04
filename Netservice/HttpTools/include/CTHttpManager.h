//
//  CTHttpManager.h
//  QianbaoIM
//
//  Created by fengsh on 24/6/15.
//  Copyright (c) 2015年 qianbao.com. All rights reserved.
//
/**
 *                          处理http管理
 */

#import <Foundation/Foundation.h>
#import "CTHttpDefine.h"

/**
 *  每个管理对应一个服务器域
 */
@interface CTHttpManager : NSObject
///请求构建器
@property (nonatomic,readonly) id<ICTHttpRequestConstruction>   requestConstruct;
/**
 *  如果请求是https且需要验证的则要设置ssl(属性设置后影响到所有接口的https)
 *  如果各个https使用的证书不同。则需要多个CTHttpManager 对象来处理。对于一个CTHttpManager对象
 *  只能处理使用相同证书的https请求。
 */
@property (nonatomic,strong)    CTSecurityPolicy                *ssl;

+ (instancetype)shareHttpManager;
///有时候当程序被T出时，需要取消正在进行的请求时就可以使用
- (void)cancelAllRequest;
/*****************************************常用接口***************************************/
/**
 *  url请求 通用请求
 *
 *  @param url              请求的URL
 *  @param mothod           GET,POST,PUT,DELETE,HEAD
 *  @param headers          请求的头域，nil时使用http默认头域
 *  @param params           请求的参数
 *  @param usecookie        请求时自动检测,如果有cookies则带上cookies头
 *  @param isJson           是否使用json的请求方式和响应方式
 *  @param cache            请求响应回来的结果是否需要缓传httpCachePolicyNone
 *  @param success          请求成功响应的回调
 *  @param failure          请求失败响应的回调
 *
 *  @return @return 请求id
 */
- (CTHttpRequest *)requesturl:(NSString *)url
withHttpMothod:(CTHttpMethod)mothod
   withHeaders:(NSDictionary *)headers
    withParams:(id)params
    useCookies:(BOOL)usecookie
withTransferAsJson:(BOOL)isJson
 cacheResponse:(CTHttpCachePolicy)cache
       andThen:(SuccessCompletion)success
    withFailed:(FailedCompletion)failure;


- (CTHttpRequest *)GET:(NSString *)URLString
           withHeaders:(NSDictionary *)headers
                     parameters:(id)parameters
                        success:(SuccessCompletion)success
                        failure:(FailedCompletion)failure;

- (CTHttpRequest *)GETForJson:(NSString *)URLString
                  withHeaders:(NSDictionary *)headers
                   withParams:(id)parameters
                      success:(SuccessCompletion)success
                      failure:(FailedCompletion)failure;

- (CTHttpRequest *)HEAD:(NSString *)URLString
                      parameters:(id)parameters
                         success:(SuccessCompletion)success
                         failure:(FailedCompletion)failure;

- (CTHttpRequest *)POST:(NSString *)URLString
            withHeaders:(NSDictionary *)headers
                      parameters:(id)parameters
                         success:(SuccessCompletion)success
                         failure:(FailedCompletion)failure;

- (CTHttpRequest *)POSTForJson:(NSString *)URLString
                   withHeaders:(NSDictionary *)headers
                    withParams:(id)parameters
                       success:(SuccessCompletion)success
                       failure:(FailedCompletion)failure;

- (CTHttpRequest *)POST:(NSString *)URLString
            withHeaders:(NSDictionary *)headers
                      parameters:(id)parameters
       constructingBodyWithBlock:(void (^)(id <CTHttpMutipartFormData> formData))block
                         success:(SuccessCompletion)success
                         failure:(FailedCompletion)failure;


- (CTHttpRequest *)PUT:(NSString *)URLString
                     parameters:(id)parameters
                        success:(SuccessCompletion)success
                        failure:(FailedCompletion)failure;

- (CTHttpRequest *)DELETE:(NSString *)URLString
                        parameters:(id)parameters
                           success:(SuccessCompletion)success
                           failure:(FailedCompletion)failure;

/*************************************上传***********************************************/
/**
 *  上传单个文件,采用的是post form的方式进行上传。过程中不支持控制，如暂停，恢复操作。
 *
 *  @param url          请求URL
 *  @param headers      请求头域，nil时使用http默认头域
 *  @param params       请求参数,可选
 *  @param fullpath     上传文件的全路径名
 *  @param mimetype     参考http://www.iana.org/assignments/media-types/media-types.xhtml
 *  @param usecookie    使用cookie,对于不需要登录的网站上传时可以不需要cookies，否则需要带上登录cookie
 *  @param progress     上传进度
 *  @param success      请求成功响应的回调
 *  @param failure      请求失败响应的回调
 *
 *  @return 请求id
 */
- (CTHttpUploadRequest *)upload:(NSString *)url
              withHeaders:(NSDictionary *)headers
               withParams:(id)params
             withFilePath:(NSString *)fullpath
             withMimetype:(NSString *)mimetype
               useCookies:(BOOL)usecookie
                  andThen:(Progressing)progress
             withComplete:(SuccessCompletion)success
               withFailed:(FailedCompletion)failure;

- (CTHttpUploadRequest *)uploadImage:(NSString *)url
                   withHeaders:(NSDictionary *)headers
                    withParams:(id)params
                 withImageData:(NSData *)image
                  withFileName:(NSString *)filename
                  withMimetype:(NSString *)mimetype
                    useCookies:(BOOL)usecookie
                  withComplete:(SuccessCompletion)success
                    withFailed:(FailedCompletion)failure;

/************************************下载***************************************/
/**
 *  下载文件
 *
 *  @param url          请求的URL
 *  @param filepath     保存文件的路径名(带文件名)
 *  @param headers      请求的头域，可选，当需要带cookies时就可以使用
 *  @param params       请求参数(可选)
 *  @param isbreakpoint 是否启用断点续传
 *  @param usecookie    使用cookie
 *  @param progress     下载进度
 *  @param success      请求成功响应的回调
 *  @param failure      请求失败响应的回调
 *
 *  @return 请求id
 */
- (CTHttpDownloadRequest *)downloadFileForURLString:(NSString *)url
                                      withStorepath:(NSString *)filepath
                                withHeaders:(NSDictionary *)headers
                                         withParams:(id)params
                                     resume:(BOOL)isbreakpoint
                                 useCookies:(BOOL)usecookie
                                    andThen:(Progressing)progress
                               withComplete:(SuccessCompletion)success
                                 withFailed:(FailedCompletion)failure;
@end
