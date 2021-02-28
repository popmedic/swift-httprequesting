Code Coverage:<br/> 
![line coverage](https://gist.githubusercontent.com/popmedic/91a7a42d5a8b205ed4d4da6553969aa7/raw/swift-httprequesting-instantiations-coverage.svg) 
![line coverage](https://gist.githubusercontent.com/popmedic/66bf591f9bf0903867893afad30b8b2c/raw/swift-httprequesting-functions-coverage.svg)
![line coverage](https://gist.githubusercontent.com/popmedic/85d803a29268ce9ae5a6e59f3d8f7882/raw/swift-httprequesting-lines-coverage.svg)
![line coverage](https://gist.githubusercontent.com/popmedic/ac14c03f4beef83001796db0c3a4c112/raw/swift-httprequesting-regions-coverage.svg)

---
# swift-httprequest

Sometimes you need a little more control over your connection then `URLSession` allows.

This class use `NWConnection` to create a `HTTPRequest` that does not need ATS exceptions. 
Point the request at a `URL` and it will get the raw response from the URL.  

## Usage

### Install with Swift Package Manager

### Making a get request

```swift
import Foundation
import HTTPRequesting
import Network

// create the url
guard let url = URL(string: "https://www.yahoo.com") else {
	print("bad url")
	exit(1)
}
// 30 seconds time to live on the request
let timeout = 30.0
// force the request over wifi
let required = NWInterface.InterfaceType.wifi
// allow self signed certs
let insecured = true

// create the reqeust
let request = NWHTTPRequest(url: url,
                            timeout: timeout,
                            required: required)
// call the request
try request.call(
    insecured: insecured
    handle: { (error, data) in
        // handle when data comes in
        // if there is an error, handle the error and return
        if let error = error { return print(error) }
        // if there is data, handle the data
        if let data = data {
            let result = String(data: data, encoding: .ascii) ??
                "data could not be string encoded"
            return print(result)
        }
        print("no error, no result")
    },
    complete: {
        // clean up if needed.
    }
)
```
