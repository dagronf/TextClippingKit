# TextClippingKit

A convenience for loading and saving Apple `.textClipping` files.

<p align="center">
    <img src="https://img.shields.io/github/v/tag/dagronf/TextClippingKit" />
    <img src="https://img.shields.io/badge/License-MIT-lightgrey" />
    <a href="https://swift.org/package-manager">
        <img src="https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat" alt="Swift Package Manager" />
    </a>
</p>

On a Mac, if you drag some text from any application onto a Finder window, it creates a `.textClipping` file.

The file format is somewhat convoluted, as it contains multiple representations of the text that was dropped.

The `TextClipping` struct provides a wrapper around reading and writing these files

## Reading a textClipping file

```swift 
let clipping = try TextClipping(fileURL: ...some file URL...)

// Get the basic text represetation
let text = clipping.utf8

// Get the attributed string representation (preserves formatting)
let text = clipping.rtf

// Get the HTML representation
let html = clipping.html
```

## Writing a textClipping file

```swift
// Generate raw textClipping data from a string
let data = try TextClipping.Encode("This is a test")

// Write an attributed string to a textClipping file
let ats = NSAttributedString(...)
try TextClipping.Encode(ats, to: ...some file URL...)
```

## License

```
MIT License

Copyright (c) 2025 Darren Ford

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
