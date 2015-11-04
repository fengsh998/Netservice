//
//  CTCopyObject.m
//  QianbaoIM
//
//  Created by fengsh on 10/5/15.
//  Copyright (c) 2015年 qianbao.com. All rights reserved.
//

#import "CTModelObject.h"
#import <objc/runtime.h>

@implementation CTModelObject

///只取当前对象的属性
- (NSDictionary *)getAllPropertiesAndVaules:(id)object
{
    NSMutableDictionary *props = [NSMutableDictionary dictionary];
    unsigned int outCount, i;
    objc_property_t *properties =class_copyPropertyList([object class], &outCount);
    for (i = 0; i<outCount; i++)
    {
        objc_property_t property = properties[i];
        const char* char_f =property_getName(property);
        NSString *propertyName = [NSString stringWithUTF8String:char_f];
        
        id propertyValue = [object valueForKey:(NSString *)propertyName];
        
        if (propertyValue)
        {
            [props setObject:propertyValue forKey:propertyName];
        }
        else
        {
            [props setObject:/*[NSNull null]*/@"nil" forKey:propertyName];
        }
    }
    free(properties);
    return props;
}

///取当前对象及其祖族对象
- (NSDictionary *)getAllPropertiesAndVaulesIncludeSuperClass:(id)object
{
    NSMutableDictionary *props = [NSMutableDictionary dictionary];
    
    Class cls = [object class];
    while (cls != [NSObject class]) {
        
        unsigned int outCount, i;
        objc_property_t *properties =class_copyPropertyList(cls, &outCount);
        for (i = 0; i<outCount; i++)
        {
            objc_property_t property = properties[i];
            const char* char_f =property_getName(property);
            NSString *propertyName = [NSString stringWithUTF8String:char_f];
            
            id propertyValue = [object valueForKey:(NSString *)propertyName];
            
            if (propertyValue)
            {
                [props setObject:propertyValue forKey:propertyName];
            }
            else
            {
                [props setObject:/*[NSNull null]*/@"nil" forKey:propertyName];
            }
        }
        free(properties);
        
        cls = class_getSuperclass(cls);
    }
    return props;
}

///实现深COPY
- (id)copyWithZone:(NSZone *)zone
{
    id copyObject = [[[self class]allocWithZone:zone]init];

    Class cls = [self class];
    while (cls != [NSObject class])
    {
        unsigned int outCount, i;
        objc_property_t *properties =class_copyPropertyList(cls, &outCount);
        for (i = 0; i<outCount; i++)
        {
            objc_property_t property = properties[i];
            const char* char_f =property_getName(property);
            NSString *propertyName = [NSString stringWithUTF8String:char_f];
            
            id propertyValue = [self valueForKey:(NSString *)propertyName];

            /*
            //获取成员内容的Ivar
            Ivar iVar = class_getInstanceVariable([self class], [propertyName UTF8String]);
            //其实上面那行获取代码是为了保险起见，基本是获取不到内容的。因为成员的名称默认会在前面加"_" ，
            if (iVar == nil) {
                iVar = class_getInstanceVariable([self class], [[NSString stringWithFormat:@"_%@",propertyName] UTF8String]);
            }
            */
            
            //  取值
            //id propertyVal = object_getIvar(self, iVar);

            Ivar iVarOfCopy = class_getInstanceVariable([copyObject class],[propertyName UTF8String]);
            if (iVarOfCopy == nil) {
                iVarOfCopy = class_getInstanceVariable([copyObject class], [[NSString stringWithFormat:@"_%@",propertyName] UTF8String]);
            }

            //object_setIvar(copyObject, iVarOfCopy, [propertyVal copy]);
            
            if (iVarOfCopy) {
                [copyObject setValue:[propertyValue copy] forKey:(NSString *)propertyName];
            }
        }
        free(properties);
        
        cls = class_getSuperclass(cls);
    }
    
    return copyObject;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
    Class cls = [self class];
    while (cls != [NSObject class]) {
        unsigned int numberOfIvars =0;
        Ivar* ivars = class_copyIvarList(cls, &numberOfIvars);
        for(const Ivar* p = ivars; p < ivars+numberOfIvars; p++){
            Ivar const ivar = *p;
            const char *type =ivar_getTypeEncoding(ivar);
            NSString *key = [NSString stringWithUTF8String:ivar_getName(ivar)];
            id value = [self valueForKey:key];
            if (value) {
                switch (type[0]) {
                    case _C_STRUCT_B: {
                        NSUInteger ivarSize =0;
                        NSUInteger ivarAlignment =0;
                        NSGetSizeAndAlignment(type, &ivarSize, &ivarAlignment);
#if ! __has_feature(objc_arc)
                        const char * varchar = (const char *)self + ivar_getOffset(ivar);
#else
                        const char * varchar = (const char*)(__bridge void*)self + ivar_getOffset(ivar);
#endif
                        NSData *data = [NSData dataWithBytes:varchar
                                                      length:ivarSize];
                        [aCoder encodeObject:data forKey:key];
                    }
                        break;
                    default:
                        [aCoder encodeObject:value forKey:key];
                        break;
                }
            }
        }
        free(ivars);
        cls = class_getSuperclass(cls);
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        Class cls = [self class];
        while (cls != [NSObject class]) {
            unsigned int numberOfIvars =0;
            Ivar* ivars = class_copyIvarList(cls, &numberOfIvars);
            
            for(const Ivar* p = ivars; p < ivars + numberOfIvars; p++){
                Ivar const ivar = *p;
                const char *type =ivar_getTypeEncoding(ivar);
                NSString *key = [NSString stringWithUTF8String:ivar_getName(ivar)];
                id value = [aDecoder decodeObjectForKey:key];
                if (value) {
                    switch (type[0]) {
                        case _C_STRUCT_B: {
                            NSUInteger ivarSize =0;
                            NSUInteger ivarAlignment =0;
                            NSGetSizeAndAlignment(type, &ivarSize, &ivarAlignment);
                            NSData *data = [aDecoder decodeObjectForKey:key];
#if ! __has_feature(objc_arc)
                            char *sourceIvarLocation = (char*)self + ivar_getOffset(ivar);
#else
                            char *sourceIvarLocation = (char*)(__bridge void*)self + ivar_getOffset(ivar);
#endif
                            [data getBytes:sourceIvarLocation length:ivarSize];
                        }
                            break;
                        default:
                            [self setValue:[aDecoder decodeObjectForKey:key]
                                    forKey:key];
                            break;
                    }
                }
            }
            free(ivars);
            cls = class_getSuperclass(cls);
        }
    }
    return self;
}


- (NSString *)description
{
    NSDictionary *dic = [self getAllPropertiesAndVaules:self];
    
    return [NSString stringWithFormat:@"%@ <%p> %@",[self class],self,dic];;
}

@end
