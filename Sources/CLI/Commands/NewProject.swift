import ArgumentParser
import Foundation

private let kQuickstartRepo = "git@github.com:joshuawright11/alchemy.git"
private let kTempDirectory = "/tmp/alchemy-quickstart"
private let kServerOnlyDirectory = "Quickstart/ServerOnly"
private let kServerAppSharedDirectory = "Quickstart/ServerAppShared"
private let kServerPackageDirectory = "Server"
private let kSharedPackageDirectory = "Shared"
private let kXcodeprojName = "AlchemyQuickstart.xcodeproj"

/// What project template does the user want downloaded?
private enum TemplateType: CaseIterable {
    /// A fresh, server only template.
    case server
    /// Server & shared library template.
    case serverShared
    /// Server, shared library & iOS template.
    case serverSharediOS
    
    var description: String {
        switch self {
        case .server:
            return "Server only"
        case .serverShared:
            return "Server + Shared framework (useful for integrating into existing xcode projects)"
        case .serverSharediOS:
            return "Server + iOS App + Shared framework"
        }
    }
}

/// The kind of project that should be created.
private enum NewProjectType {
    /// A server only package.
    case server
    /// A shared package and a server package that has it as a dependency.
    case serverShared
    /// A shared package, a server package, and an iOS app target. The server & app depend on the shared
    /// package and there is a `.xcodeproj`.
    case serverSharedApp
}

struct NewProject: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "new")
    
    @Argument
    var name: String
    
    func run() throws {
        print("Cloning quickstart project...")
        // Blow away the temp directory so git doesn't complain if it already exists.
        _ = try Process().shell("rm -rf \(kTempDirectory)")
        _ = try Process().shell("git clone \(kQuickstartRepo) \(kTempDirectory)")
        
        try self.createProject()
    }
    
    private func createProject() throws {
        switch self.queryTemplateType() {
        case .server:
            _ = try Process().shell("cp -r \(kTempDirectory)/\(kServerOnlyDirectory) \(self.name)")
            print("Created package at '\(self.name)'.")
        case .serverShared:
            let serverDirectory = "\(kTempDirectory)/\(kServerAppSharedDirectory)/\(kServerPackageDirectory)"
            let sharedDirectory = "\(kTempDirectory)/\(kServerAppSharedDirectory)/\(kSharedPackageDirectory)"
            let serverDestination = "Server"
            let sharedDestination = "Shared"
            
            _ = try Process().shell("cp -r \(serverDirectory) \(serverDestination)")
            _ = try Process().shell("cp -r \(sharedDirectory) \(sharedDestination)")
            print("Created packages at '\(serverDestination)' & '\(sharedDestination)'.")
        case .serverSharediOS:
            _ = try Process().shell("cp -r \(kTempDirectory)/\(kServerAppSharedDirectory) \(self.name)")
            
            let projectTarget = "\(self.name)/\(self.name).xcodeproj"
            _ = try Process().shell("mv \(self.name)/\(kXcodeprojName) \(projectTarget)")
            // Rename relevant scheme containers so the iOS scheme loads properly.
            _ = try Process().shell("find \(self.name) -type f -name '*.xcscheme' -print0 | xargs -0 sed -i '' -e 's/AlchemyQuickstart/\(self.name)/g'")
            print("Created project at '\(self.name)'. Use the project file '\(projectTarget)'.")
        }
    }
    
    private func queryTemplateType(allowed: [TemplateType] = TemplateType.allCases) -> TemplateType {
        let response = Process().queryUser(
            query: "What type of project do you want to create?",
            choices: allowed.map { $0.description }
        )
        
        return allowed[response]
    }
}

extension Process {
    /// Gives queries as numerical options, then waits until the user enters a number.
    func queryUser(query: String, choices: [String]) -> Int {
        print(query)
        for (index, choice) in choices.enumerated() {
            print("\(index): \(choice)")
        }
        
        return getResponse(prompt: "> ", allowedResponses: choices.enumerated().map { "\($0.offset)" })
    }
    
    private func getResponse(prompt: String, allowedResponses: [String]) -> Int {
        print(prompt, terminator: "")
        var response = readLine()
        while response.map({ !allowedResponses.contains($0) }) ?? false {
            print("Invalid response.")
            print(prompt, terminator: "")
            response = readLine()
        }
        
        guard let unwrappedResponse = response, let intResponse = Int(unwrappedResponse) else {
            return 0
        }
        
        return intResponse
    }
}
