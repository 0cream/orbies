# LanguagesAPI

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getLanguages**](LanguagesAPI.md#getlanguages) | **GET** /api/languages | Get All Languages


# **getLanguages**
```swift
    open class func getLanguages(completion: @escaping (_ data: LanguagesResponse?, _ error: Error?) -> Void)
```

Get All Languages

Get list of all supported languages with support flags for auto-translation

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient


// Get All Languages
LanguagesAPI.getLanguages() { (response, error) in
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
This endpoint does not need any parameter.

### Return type

[**LanguagesResponse**](LanguagesResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

