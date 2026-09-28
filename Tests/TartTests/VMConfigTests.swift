import XCTest
import Virtualization
@testable import tart

final class VMConfigTests: XCTestCase {
  func testVMDisplayConfig() throws {
    // Defaults units (points)
    var vmDisplayConfig = VMDisplayConfig.init(argument: "1234x5678")
    XCTAssertEqual(VMDisplayConfig(width: 1234, height: 5678, unit: nil), vmDisplayConfig)

    // Explicit units (points)
    vmDisplayConfig = VMDisplayConfig.init(argument: "1234x5678pt")
    XCTAssertEqual(VMDisplayConfig(width: 1234, height: 5678, unit: .point), vmDisplayConfig)

    // Explicit units (pixels)
    vmDisplayConfig = VMDisplayConfig.init(argument: "1234x5678px")
    XCTAssertEqual(VMDisplayConfig(width: 1234, height: 5678, unit: .pixel), vmDisplayConfig)
  }

  func testValidateHostCompatibilityLinux() throws {
    let config = VMConfig(platform: Linux(), cpuCountMin: 1, memorySizeMin: 1024 * 1024 * 1024)

    XCTAssertNoThrow(try config.validateHostCompatibility())
  }

  #if arch(arm64)
    func testDecodingUnsupportedHardwareModelThrowsUnsupportedHostOS() throws {
      let ecid = VZMacMachineIdentifier().dataRepresentation.base64EncodedString()
      let json = """
      {
        "version": 1,
        "os": "darwin",
        "arch": "arm64",
        "ecid": "\(ecid)",
        "hardwareModel": "AAAA",
        "cpuCountMin": 4,
        "cpuCount": 4,
        "memorySizeMin": 4294967296,
        "memorySize": 4294967296,
        "macAddress": "00:00:00:00:00:00",
        "display": {"width": 1024, "height": 768}
      }
      """

      XCTAssertThrowsError(try VMConfig(fromJSON: Data(json.utf8))) { error in
        XCTAssertTrue(error is UnsupportedHostOSError)
      }

      let name = try RemoteName("example.com/org/image:latest")
      XCTAssertThrowsError(try VMStorageOCI.checkHostCompatibility(configData: Data(json.utf8), name: name)) { error in
        guard case RuntimeError.PullFailed = error else {
          return XCTFail("expected PullFailed, got \(error)")
        }
      }
    }
  #endif

  func testCheckHostCompatibilityIgnoresUnrelatedDecodeErrors() throws {
    let name = try RemoteName("example.com/org/image:latest")

    XCTAssertNoThrow(try VMStorageOCI.checkHostCompatibility(configData: Data("not json".utf8), name: name))
  }
}
