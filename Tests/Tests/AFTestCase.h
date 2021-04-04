#import <XCTest/XCTest.h>

SecTrustRef AFUTTrustChainForCertsInDirectory(NSString *directoryPath);

// 在 XCTestCase 下, 封装一层, 用作所有的测试用例的父类.
@interface AFTestCase : XCTestCase

@property (nonatomic, strong, readonly) NSURL *baseURL;
@property (nonatomic, strong, readonly) NSURL *pngURL;
@property (nonatomic, strong, readonly) NSURL *jpegURL;
@property (nonatomic, strong, readonly) NSURL *delayURL;
- (NSURL *)URLWithStatusCode:(NSInteger)statusCode;

@property (nonatomic, assign) NSTimeInterval networkTimeout;

- (void)waitForExpectationsWithCommonTimeout;
- (void)waitForExpectationsWithCommonTimeoutUsingHandler:(XCWaitCompletionHandler)handler;
- (NSData *)archivedDataWithRootObject:(id)object;
- (id)unarchivedObjectOfClass:(Class)class fromData:(NSData *)data;

@end
