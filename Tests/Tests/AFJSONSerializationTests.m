#import "AFTestCase.h"

#import "AFURLRequestSerialization.h"
#import "AFURLResponseSerialization.h"
#import <objc/runtime.h>


@implementation NSObject (XXOOProperty)

/* 获取对象的所有属性和属性内容 */
- (NSDictionary *)getAllPropertiesAndVaules
{
    NSMutableDictionary *props = [NSMutableDictionary dictionary];
    static NSSet *kPrivateSystemName;\
    if (!kPrivateSystemName) {\
        kPrivateSystemName = [NSSet setWithObjects:@"hash", @"superclass", @"description", @"debugDescription", nil];\
    }\
    Class cls = [self class];   \
    while (cls != [NSObject class]) {   \
        /*判断是自身类还是父类*/    \
        BOOL bIsSelfClass = (cls == [self class]);  \
        unsigned int iVarCount = 0; \
        unsigned int propVarCount = 0;  \
        unsigned int sharedVarCount = 0;    \
        Ivar *ivarList = bIsSelfClass ? class_copyIvarList([cls class], &iVarCount) : NULL;/*变量列表，含属性以及私有变量*/   \
        objc_property_t *propList = bIsSelfClass ? NULL : class_copyPropertyList(cls, &propVarCount);/*属性列表*/   \
        sharedVarCount = bIsSelfClass ? iVarCount : propVarCount;   \
        \
        for (int i = 0; i < sharedVarCount; i++) {  \
            const char *varName = bIsSelfClass ? ivar_getName(*(ivarList + i)) : property_getName(*(propList + i)); \
            NSString *key = [NSString stringWithUTF8String:varName];   \
            if ([kPrivateSystemName containsObject:key]) { continue; } \
            props[key] = [self valueForKey:key];
        }   \
        free(ivarList); \
        free(propList); \
        cls = class_getSuperclass(cls); \
    }   \
    return props;
}
/* 获取对象的所有属性 */
- (NSArray *)getAllProperties
{
    u_int count;

    objc_property_t *properties  =class_copyPropertyList([self class], &count);

    NSMutableArray *propertiesArray = [NSMutableArray arrayWithCapacity:count];

    for (int i = 0; i < count ; i++)
    {
        const char* propertyName =property_getName(properties[i]);
        [propertiesArray addObject: [NSString stringWithUTF8String: propertyName]];
    }

    free(properties);

    return propertiesArray;
}
/* 获取对象的所有方法 */
-(void)getAllMethods
{
    unsigned int mothCout_f =0;
    Method* mothList_f = class_copyMethodList([self class],&mothCout_f);
    for(int i=0;i<mothCout_f;i++)
    {
        Method temp_f = mothList_f[i];
        IMP imp_f = method_getImplementation(temp_f);
        SEL name_f = method_getName(temp_f);
        const char* name_s =sel_getName(method_getName(temp_f));
        int arguments = method_getNumberOfArguments(temp_f);
        const char* encoding =method_getTypeEncoding(temp_f);
        NSLog(@"方法名：%@,参数个数：%d,编码方式：%@",[NSString stringWithUTF8String:name_s],
              arguments,
              [NSString stringWithUTF8String:encoding]);
    }
    free(mothList_f);
}


@end








// 分析的第一个类.

static NSData * AFJSONTestData() {
    return [NSJSONSerialization dataWithJSONObject:@{@"foo": @"bar"} options:(NSJSONWritingOptions)0 error:nil];
}

#pragma mark -

// AFNetworking iOS Tests
// 整个测试程序, 其实会变为一个 App. 里面, 测试的各种资源文件都会被移植到这个 App 内.
// 所以, Tests, 就是一个单独的程序, 来进行各个类的测试工作.
// 因为是单元测试, 一般来说, 一个测试用例也就测试一个类的方法, 彼此不会有太多的耦合的关系.

// 详细的测试过程, 可以查看 XCTestFramework 的源码, 开源.
@interface AFJSONRequestSerializationTests : AFTestCase

@property (nonatomic, strong) AFJSONRequestSerializer *requestSerializer;

@end

@implementation AFJSONRequestSerializationTests

- (void)setUp {
    // 每个测试用例, 都会在执行业务代码之前, 执行该方法. 所以, 下面有多少次 test 开头的方法, setUp 就会被调用多少次.
    // 在这里, 进行了被测试对象的初始化的工作.
    self.requestSerializer = [[AFJSONRequestSerializer alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    // 在这里, 进行资源的回收, 或者全局状态重置的工作.
}

#pragma mark -

// 这个类, 主要就是进行, JSON Request 的序列化工作.

// 同 Swift 一样, 所有的 XCTAssert 方法, 都是对于 _XCTPrimitiveAssert 的调用. 所以, 在这个方法里面, 有着判断 result, 进行 caseRun 的记录工作.

- (void)testThatJSONRequestSerializationHandlesParametersDictionary {
    NSDictionary *parameters = @{@"key":@"value"};
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"POST" URLString:self.baseURL.absoluteString parameters:parameters error:&error];

    XCTAssertNil(error, @"Serialization error should be nil");

    NSString *body = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];

    XCTAssertTrue([@"{\"key\":\"value\"}" isEqualToString:body], @"Parameters were not encoded correctly");
}

// 这里, 是测试, parameters 是 array 的情况.
- (void)testThatJSONRequestSerializationHandlesParametersArray {
    NSArray *parameters = @[@{@"key":@"value"}];
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"POST" URLString:self.baseURL.absoluteString parameters:parameters error:&error];

    XCTAssertNil(error, @"Serialization error should be nil");

    NSString *body = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];

    XCTAssertTrue([@"[{\"key\":\"value\"}]" isEqualToString:body], @"Parameters were not encoded correctly");
}

- (void)testThatJSONRequestSerializationHandlesInvalidParameters {
    NSString *string = [[NSString alloc] initWithBytes:"\xd8\x00" length:2 encoding:NSUTF16StringEncoding];
    
    NSDictionary *parameters = @{@"key":string};
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"POST" URLString:self.baseURL.absoluteString parameters:parameters error:&error];
    
    XCTAssertNil(request, @"Expected nil request.");
    XCTAssertNotNil(error, @"Expected non-nil error.");
}

- (void)testThatJSONRequestSerializationErrorsWithInvalidJSON {
    NSDictionary *parameters = @{@"key":[NSSet setWithObject:@"value"]};
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"POST" URLString:self.baseURL.absoluteString parameters:parameters error:&error];
    
    XCTAssertNil(request, @"Request should be nil");
    XCTAssertNotNil(error, @"Serialization error should be not nil");
    XCTAssertEqualObjects(error.domain, AFURLRequestSerializationErrorDomain);
    XCTAssertEqual(error.code, NSURLErrorCannotDecodeContentData);
    XCTAssertEqualObjects(error.localizedFailureReason, @"The `parameters` argument is not valid JSON.");
}

@end

#pragma mark -

@interface AFJSONResponseSerializationTests : AFTestCase
@property (nonatomic, strong) AFJSONResponseSerializer *responseSerializer;
@end

@implementation AFJSONResponseSerializationTests

- (void)setUp {
    [super setUp];
    self.responseSerializer = [AFJSONResponseSerializer serializer];
}

#pragma mark -

- (void)testThatJSONResponseSerializerAcceptsApplicationJSONMimeType {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];

    NSError *error = nil;
    [self.responseSerializer validateResponse:response data:AFJSONTestData() error:&error];

    XCTAssertNil(error, @"Error handling application/json");
}

- (void)testThatJSONResponseSerializerAcceptsTextJSONMimeType {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"text/json"}];
    NSError *error = nil;
    [self.responseSerializer validateResponse:response data:AFJSONTestData()error:&error];

    XCTAssertNil(error, @"Error handling text/json");
}

- (void)testThatJSONResponseSerializerAcceptsTextJavaScriptMimeType {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"text/javascript"}];
    NSError *error = nil;
    [self.responseSerializer validateResponse:response data:AFJSONTestData() error:&error];

    XCTAssertNil(error, @"Error handling text/javascript");
}

- (void)testThatJSONResponseSerializerDoesNotAcceptNonStandardJSONMimeType {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"nonstandard/json"}];
    NSError *error = nil;
    [self.responseSerializer validateResponse:response data:AFJSONTestData() error:&error];

    XCTAssertNotNil(error, @"Error should have been thrown for nonstandard/json");
}

- (void)testThatJSONResponseSerializerReturnsDictionaryForValidJSONDictionary {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"text/json"}];
    NSError *error = nil;
    id responseObject = [self.responseSerializer responseObjectForResponse:response data:AFJSONTestData() error:&error];

    XCTAssertNil(error, @"Serialization error should be nil");
    XCTAssert([responseObject isKindOfClass:[NSDictionary class]], @"Expected response to be a NSDictionary");
}

- (void)testThatJSONResponseSerializerReturnsErrorForInvalidJSON {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type":@"text/json"}];
    NSError *error = nil;
    [self.responseSerializer responseObjectForResponse:response data:[@"{invalid}" dataUsingEncoding:NSUTF8StringEncoding] error:&error];

    XCTAssertNotNil(error, @"Serialization error should not be nil");
}

- (void)testThatJSONResponseSerializerReturnsNilObjectAndNilErrorForEmptyData {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type":@"text/json"}];
    NSData *data = [NSData data];
    NSError *error = nil;
    id responseObject = [self.responseSerializer responseObjectForResponse:response data:data error:&error];
    XCTAssertNil(responseObject);
    XCTAssertNil(error);
}

- (void)testThatJSONResponseSerializerReturnsNilObjectAndNilErrorForSingleSpace {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type":@"text/json"}];
    NSData *data = [@" " dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    id responseObject = [self.responseSerializer responseObjectForResponse:response data:data error:&error];
    XCTAssertNil(responseObject);
    XCTAssertNil(error);
}

- (void)testThatJSONRemovesKeysWithNullValues {
    self.responseSerializer.removesKeysWithNullValues = YES;
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type":@"text/json"}];
    NSData *data = [NSJSONSerialization dataWithJSONObject:@{@"key":@"value",@"nullkey":[NSNull null],@"array":@[@{@"subnullkey":[NSNull null]}], @"arrayWithNulls": @[[NSNull null]]}
                                                   options:(NSJSONWritingOptions)0
                                                     error:nil];

    NSError *error = nil;
    NSDictionary *responseObject = [self.responseSerializer responseObjectForResponse:response
                                                                                 data:data
                                                                                error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(responseObject[@"key"]);
    XCTAssertNil(responseObject[@"nullkey"]);
    XCTAssertNil(responseObject[@"array"][0][@"subnullkey"]);
    XCTAssertEqualObjects(responseObject[@"arrayWithNulls"], @[]);
}

- (void)testThatJSONResponseSerializerCanBeCopied {
    [self.responseSerializer setAcceptableStatusCodes:[NSIndexSet indexSetWithIndex:100]];
    [self.responseSerializer setAcceptableContentTypes:[NSSet setWithObject:@"test/type"]];
    [self.responseSerializer setReadingOptions:NSJSONReadingMutableLeaves];
    [self.responseSerializer setRemovesKeysWithNullValues:YES];

    AFJSONResponseSerializer *copiedSerializer = [self.responseSerializer copy];
    XCTAssertNotEqual(copiedSerializer, self.responseSerializer);
    XCTAssertEqual(copiedSerializer.acceptableStatusCodes, self.responseSerializer.acceptableStatusCodes);
    XCTAssertEqual(copiedSerializer.acceptableContentTypes, self.responseSerializer.acceptableContentTypes);
    XCTAssertEqual(copiedSerializer.readingOptions, self.responseSerializer.readingOptions);
    XCTAssertEqual(copiedSerializer.removesKeysWithNullValues, self.responseSerializer.removesKeysWithNullValues);
}

#pragma mark NSSecureCoding

- (void)testJSONSerializerSupportsSecureCoding {
    XCTAssertTrue([AFJSONResponseSerializer supportsSecureCoding]);
}

- (void)testJSONSerializerCanBeArchivedAndUnarchived {
    AFJSONResponseSerializer *responseSerializer = [AFJSONResponseSerializer serializer];
    NSData *archive = nil;
    
    archive = [self archivedDataWithRootObject:responseSerializer];
    XCTAssertNotNil(archive);
    AFJSONResponseSerializer *unarchivedSerializer = [self unarchivedObjectOfClass:[AFJSONResponseSerializer class] fromData:archive];
    XCTAssertNotNil(unarchivedSerializer);
    XCTAssertNotEqual(unarchivedSerializer, responseSerializer);
    XCTAssertTrue([unarchivedSerializer.acceptableContentTypes isEqualToSet:responseSerializer.acceptableContentTypes]);
    XCTAssertTrue([unarchivedSerializer.acceptableStatusCodes isEqualToIndexSet:responseSerializer.acceptableStatusCodes]);
}

@end
