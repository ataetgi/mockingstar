//
//  MockDomainDiscover.swift
//
//
//  Created by Yusuf Özgül on 22.09.2023.
//

import Foundation
import CommonKit

#if os(macOS)
@Observable
#endif
public final class MockDomainDiscover {
    private let logger = Logger(category: "MockDomainDiscover")
    public var domains: [String] = []
    private let fileManager: FileManagerInterface
    private var watcher: DirectoryMonitorInterface!
    private let fileUrlBuilder: FileUrlBuilderInterface
    private var isWatcherStarted = false

    public init(fileManager: FileManagerInterface = FileManager.default,
                fileUrlBuilder: FileUrlBuilderInterface = FileUrlBuilder(),
                watcher: DirectoryMonitorInterface = DirectoryMonitor()) {
        self.fileManager = fileManager
        self.fileUrlBuilder = fileUrlBuilder
        self.watcher = watcher
    }

    private func startWatcher() {
        guard let url: URL = try? fileUrlBuilder.domainsFolderUrl(), !isWatcherStarted else { return }
        watcher.startMonitoring(url: url) { [weak self] in
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await startDomainDiscovery()
                } catch {
                    logger.fault("ERROR: MockDomainDiscover: \(error)")
                }
            }
        }
        isWatcherStarted = true
    }

    /// Initiates the discovery of available mock domains.
    ///
    /// This function performs the following steps:
    /// 1. Constructs the URL for the "Domains" folder.
    /// 2. Retrieves the contents of the "Domains" folder, filtering only directories.
    /// 3. Extracts the names of available mock domains from the directory paths.
    /// 4. Initiates the watcher to monitor changes in the "Domains" folder.
    /// 5. Updates the `domains` property with the sorted list of discovered mock domains.
    ///
    /// - Throws: If any error occurs during the discovery process, it is thrown.
    public func startDomainDiscovery() async throws {
        let url: URL = try fileUrlBuilder.domainsFolderUrl()
        let domainFolders = try fileManager.folderContent(at: url)

        let domains = domainFolders
            .filter { $0.hasDirectoryPath }
            .map(\.lastPathComponent)

        logger.info("Available domain count: \(domains.count)")

        startWatcher()

        await MainActor.run {
            self.domains = domains.sorted()
        }
    }
}
