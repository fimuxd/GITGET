//
//  String+Extensions.swift
//  GITGET
//
//  Created by Bo-Young Park on 2024-10-07.
//

import Foundation

extension String {
    func toURL() -> URL? {
        return URL(string: self.trimmed)
    }
    
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func encodedURL() -> URL? {
        if let url = self.toURL() {
            // 사용 가능한 URL -> 그대로 사용
            return url
        } else if let queryStartIndex = self.firstIndex(of: "?") {
            // 쿼리 문자열이 존재하는 경우 -> 쿼리 부분은 보존, 쿼리 이전의 URL 문자열을 디코딩 > 인코딩 처리한다.
            var beforeQuery = String(self[..<queryStartIndex])
            let query = String(self[queryStartIndex...])
            if URL(string: beforeQuery) == nil {
                beforeQuery = beforeQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? beforeQuery
            }
            let url = beforeQuery + query
            return url.toURL()
        } else {
            // 쿼리 문자열이 존재하지 않는 경우 -> URL 문자열을 디코딩 > 인코딩 처리한다
            return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?.toURL()
        }
    }
}
