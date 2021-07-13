//
//  URLResponse.swift
//  sphinx
//
//  Created by Tomas Timinskas on 15/09/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation

extension URLResponse {
    func getFileName() -> String? {
        if let httpResponse = self as? HTTPURLResponse, let contentDisposition = httpResponse.allHeaderFields["Content-Disposition"] as? String {
            if let range = contentDisposition.range(of: "filename=") {
                let fileName = String(contentDisposition[range.upperBound...])
                return fileName
            }
        }
        return nil
    }
}
