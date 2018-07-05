import XCTest

#if os(Linux) || os(FreeBSD)
   @testable import ServerTests

   XCTMain([
    ])
#endif