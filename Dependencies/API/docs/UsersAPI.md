# UsersAPI

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**completeTask**](UsersAPI.md#completetask) | **POST** /api/v1/user/tasks/{id}/complete | Complete a task
[**getUserInviteCodes**](UsersAPI.md#getuserinvitecodes) | **GET** /api/v1/user/codes | Get user invite codes
[**getUserPoints**](UsersAPI.md#getuserpoints) | **GET** /api/v1/user/points | Get user points
[**getUserTasks**](UsersAPI.md#getusertasks) | **GET** /api/v1/user/tasks | Get user tasks


# **completeTask**
```swift
    open class func completeTask(authorization: String, id: UUID, completion: @escaping (_ data: CompleteTaskResponse?, _ error: Error?) -> Void)
```

Complete a task

Marks a specific task as completed for the current user.

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let authorization = "authorization_example" // String | Authorization header containing the JWT token. Must start with \"Bearer \".
let id = 987 // UUID | Task ID (UUID)

// Complete a task
UsersAPI.completeTask(authorization: authorization, id: id) { (response, error) in
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
 **id** | **UUID** | Task ID (UUID) | 

### Return type

[**CompleteTaskResponse**](CompleteTaskResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getUserInviteCodes**
```swift
    open class func getUserInviteCodes(authorization: String, completion: @escaping (_ data: UserInviteCodesResponse?, _ error: Error?) -> Void)
```

Get user invite codes

Returns the current user's invite codes with usage metadata.

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let authorization = "authorization_example" // String | Authorization header containing the JWT token. Must start with \"Bearer \".

// Get user invite codes
UsersAPI.getUserInviteCodes(authorization: authorization) { (response, error) in
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

### Return type

[**UserInviteCodesResponse**](UserInviteCodesResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getUserPoints**
```swift
    open class func getUserPoints(authorization: String, completion: @escaping (_ data: UserPointsResponse?, _ error: Error?) -> Void)
```

Get user points

Returns total points from completed tasks plus points from used invite codes.

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let authorization = "authorization_example" // String | Authorization header containing the JWT token. Must start with \"Bearer \".

// Get user points
UsersAPI.getUserPoints(authorization: authorization) { (response, error) in
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

### Return type

[**UserPointsResponse**](UserPointsResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getUserTasks**
```swift
    open class func getUserTasks(authorization: String, completion: @escaping (_ data: UserTasksResponse?, _ error: Error?) -> Void)
```

Get user tasks

Returns all tasks with completion state for the current user.

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let authorization = "authorization_example" // String | Authorization header containing the JWT token. Must start with \"Bearer \".

// Get user tasks
UsersAPI.getUserTasks(authorization: authorization) { (response, error) in
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

### Return type

[**UserTasksResponse**](UserTasksResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

