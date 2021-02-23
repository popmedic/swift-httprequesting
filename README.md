# swift-httprequest

Sometimes you need a little more control over your connection then `URLSession` allows.

This class use `NWConnection` to create a `HTTPRequest` that does not need ATS exceptions. 
Point the request at a `URL` and it will get the raw response from the URL.  

## Usage

### Install with Swift Package Manager

### Making a get request

```swift
let request = NWHTTPRequest(url: url,
                            timeout: timeout,
                            required: requiredInterface)
try request.call(
    handle: { (error, data) in
        if let error = error { return print(error) }
        if let data = data {
            let result = String(data: data, encoding: .ascii) ??
                "data could not be string encoded"
            return print(result)
        }
        print("no error, no result")
    },
    complete: {
        grp.leave()
    }
)
```
