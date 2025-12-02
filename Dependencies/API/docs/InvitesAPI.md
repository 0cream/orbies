# InvitesAPI

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**verifyInviteCode**](InvitesAPI.md#verifyinvitecode) | **POST** /api/v1/invite/verify | Verify and redeem an invite code


# **verifyInviteCode**
```swift
    open class func verifyInviteCode(authorization: String, verifyInviteCodeRequest: VerifyInviteCodeRequest, completion: @escaping (_ data: VerifyInviteCodeResponse?, _ error: Error?) -> Void)
```

Verify and redeem an invite code

Redeems a 7-character invite code for the current user and generates new invite codes.

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let authorization = "authorization_example" // String | Authorization header containing the JWT token. Must start with \"Bearer \".
let verifyInviteCodeRequest = VerifyInviteCodeRequest(code: "code_example") // VerifyInviteCodeRequest | 

// Verify and redeem an invite code
InvitesAPI.verifyInviteCode(authorization: authorization, verifyInviteCodeRequest: verifyInviteCodeRequest) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **authorization** | **String** | Authorization header containing the JWT token. Must start with \&quot;Bearer \&quot;. | 
 **verifyInviteCodeRequest** | [**VerifyInviteCodeRequest**](VerifyInviteCodeRequest.md) |  | 

### Return type

[**VerifyInviteCodeResponse**](VerifyInviteCodeResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

