#import "AFTestCase.h"

#import "AFURLRequestSerialization.h"
#import "AFURLResponseSerialization.h"

// 分析的第一个类.

static NSData * AFJSONTestData() {
    return [NSJSONSerialization dataWithJSONObject:@{@"foo": @"bar"} options:(NSJSONWritingOptions)0 error:nil];
}

#pragma mark -

// AFNetworking iOS Tests
// 整个测试程序, 其实会变为一个 App. 里面, 测试的各种资源文件都会被移植到这个 App 内.
// 所以, Tests, 就是一个单独的程序, 来进行各个类的测试工作.
// 因为是单元测试, 一般来说, 一个测试用例也就测试一个类的方法, 彼此不会有太多的耦合的关系.

// 一个测试用例, 就是一个对象, 在里面可以存储信息. 在测试方法里面, 可以根据这些存储的信息. 进行方法的调用.
// 一般来说, 就是存储了被测试的类的实例, 调用这个实例的方法, 查看结果.
@interface AFJSONRequestSerializationTests : AFTestCase

@property (nonatomic, strong) AFJSONRequestSerializer *requestSerializer;

@end

@implementation AFJSONRequestSerializationTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    // 在这里, 进行了被测试对象的初始化的工作.
    self.requestSerializer = [[AFJSONRequestSerializer alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    // 在这里, 进行资源的回收, 或者全局状态重置的工作.
}

#pragma mark -

// 在方法的内部, 组织数据, 进行对象相关方法的调用, 然后验证对应的结果是不是符合 Assert 的声明.
// 如果不符合, 那么就是失败了. Xcode 就会进行标识.
// 然后最终, 就是 TestFailed.
// 如果都通过了测试, 就是 TestSuccess.
- (void)testThatJSONRequestSerializationHandlesParametersDictionary {
    NSDictionary *parameters = @{@"key":@"value"};
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"POST" URLString:self.baseURL.absoluteString parameters:parameters error:&error];

    XCTAssertNil(error, @"Serialization error should be nil");

    NSString *body = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];

    XCTAssertTrue([@"{\"key\":\"value\"}" isEqualToString:body], @"Parameters were not encoded correctly");
}

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
