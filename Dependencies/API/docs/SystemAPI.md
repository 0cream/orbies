# SystemAPI

All URIs are relative to *http://localhost:3001*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getQueueStatus**](SystemAPI.md#getqueuestatus) | **GET** /api/indexing/queue | Get indexing queue status
[**healthCheck**](SystemAPI.md#healthcheck) | **GET** /health | Health check


# **getQueueStatus**
```swift
    open class func getQueueStatus(completion: @escaping (_ data: GetQueueStatusResponse?, _ error: Error?) -> Void)
```

Get indexing queue status

Returns the current status of the token indexing queue, including what's being processed and what's waiting.

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient


// Get indexing queue status
SystemAPI.getQueueStatus() { (response, error) in
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

[**GetQueueStatusResponse**](GetQueueStatusResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **healthCheck**
```swift
    open class func healthCheck(completion: @escaping (_ data: HealthCheckResponse?, _ error: Error?) -> Void)
```

Health check

Returns the health status of the API and its dependencies

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient


// Health check
SystemAPI.healthCheck() { (response, error) in
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

[**HealthCheckResponse**](HealthCheckResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

