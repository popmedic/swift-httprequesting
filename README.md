Code Coverage

![coverage](https://gist.githubusercontent.com/popmedic/a555f644f50b16b6dd3a04a28af6f293/raw/swift-httprequesting-coverage.svg)
# swift-httprequest

Sometimes you need a little more control over your connection then `URLSession` allows.

This class use `NWConnection` to create a `HTTPRequest` that does not need ATS exceptions. 
Point the request at a `URL` and it will get the raw response from the URL.  

## Usage

### Install with Swift Package Manager

### Making a get request

```swift
guard let url = URL(string: "https://www.yahoo.com") else {
	print("bad url")
	exit(1)
}
let timeout = 30 //seconds
let requiredInterface: NWInterface.InterfaceType = .wifi

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
        // clean up if needed.
    }
)
```
