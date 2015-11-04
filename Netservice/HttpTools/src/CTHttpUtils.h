//
//  CTHttpUtils.h
//  QianbaoIM
//
//  Created by fengsh on 20/4/15.
//  Copyright (c) 2015年 fengsh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CTHttpUtils : NSObject
///创建UUID
+ (NSString *)createUUID;
///将url中带中文或其它字符的进行转议
+ (NSString *)urlEncode:(NSString*)str;
+ (NSString *)urlParametersStringFromParameters:(NSDictionary *)parameters;
+ (NSString *)md5StringFromString:(NSString *)string;
@end
