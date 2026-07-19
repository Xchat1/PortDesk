import Foundation
import XCTest
@testable import PortDeck

final class PortDeckTests: XCTestCase {
    func testSystemAndAppleSignedProcessesAreProtected() {
        XCTAssertTrue(makeItem(isSystemProcess: true).isProtected)
        XCTAssertTrue(makeItem(isAppleSigned: true).isProtected)
        XCTAssertFalse(makeItem().isProtected)
    }

    func testStopRejectsChangedProcessIdentity() throws {
        let process = try startSleepProcess()
        defer { stopTestProcess(process) }

        let rejected = expectation(description: "Reject stale process identity")
        PortService.shared.stopService(
            item: makeItem(
                pid: process.processIdentifier,
                path: "/bin/sleep",
                processStartTime: UInt64.max
            ),
            force: true
        ) { success in
            XCTAssertFalse(success)
            rejected.fulfill()
        }

        wait(for: [rejected], timeout: 5)
        XCTAssertTrue(process.isRunning)
    }

    func testServiceLayerRefusesProtectedProcess() throws {
        let process = try startSleepProcess()
        defer { stopTestProcess(process) }

        let rejected = expectation(description: "Reject protected process")
        PortService.shared.stopService(
            item: makeItem(
                pid: process.processIdentifier,
                path: "/bin/sleep",
                processStartTime: nil,
                isAppleSigned: true
            ),
            force: true
        ) { success in
            XCTAssertFalse(success)
            rejected.fulfill()
        }

        wait(for: [rejected], timeout: 5)
        XCTAssertTrue(process.isRunning)
    }

    func testConcurrentActionLogsAreNotLost() {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PortDeckTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let service = ActionLogService(logsDirectory: directory)
        let enqueueGroup = DispatchGroup()
        let callerQueue = DispatchQueue(label: "PortDeckTests.callers", attributes: .concurrent)

        for index in 0..<50 {
            enqueueGroup.enter()
            callerQueue.async {
                service.logAction(
                    type: "Test",
                    target: "Target \(index)",
                    details: "Concurrent write \(index)",
                    status: "Success"
                )
                enqueueGroup.leave()
            }
        }
        XCTAssertEqual(enqueueGroup.wait(timeout: .now() + 5), .success)

        let loaded = expectation(description: "Load serialized logs")
        var loadedLogs: [ActionLogItem] = []
        service.loadLogs { logs in
            loadedLogs = logs
            loaded.fulfill()
        }
        wait(for: [loaded], timeout: 5)

        XCTAssertEqual(loadedLogs.count, 50)
        XCTAssertEqual(Set(loadedLogs.map(\.target)).count, 50)
    }

    private func makeItem(
        pid: Int32 = 123,
        path: String? = "/tmp/test",
        processStartTime: UInt64? = 1,
        isSystemProcess: Bool = false,
        isAppleSigned: Bool = false
    ) -> PortServiceItem {
        PortServiceItem(
            pid: pid,
            ppid: 1,
            processName: "test",
            userName: "tester",
            ports: [8080],
            host: "127.0.0.1",
            protocolName: "TCP",
            isLocalOnly: true,
            path: path,
            cwd: "/tmp",
            commandLine: "test --serve",
            parentProcessName: "parent",
            framework: "Test",
            isAppleSigned: isAppleSigned,
            isSystemProcess: isSystemProcess,
            processStartTime: processStartTime
        )
    }

    private func startSleepProcess() throws -> Process {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sleep")
        process.arguments = ["30"]
        try process.run()
        return process
    }

    private func stopTestProcess(_ process: Process) {
        if process.isRunning {
            process.terminate()
        }
        process.waitUntilExit()
    }
}
