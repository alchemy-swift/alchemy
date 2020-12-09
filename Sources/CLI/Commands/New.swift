import ArgumentParser
import Foundation

private let kQuickstartRepo = ""

/// The context of this command; is there an existing XCode project, workspace, or nothing in this directory?
private enum ExistingProject {
    /// There is a .xcodeproj in the working directory.
    case project(named: String)
    /// There is a .xcworkspace in the working directory.
    case workspace(named: String)
}

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
            return "Server + Framework for shared code"
        case .serverSharediOS:
            return "Server + iOS App + Shared framework"
        }
    }
}

/// When the desired `TemplateType` is downloaded, what should be done with it?
private enum NewProjectType {
    /// Create a new project / workspace with it.
    case fresh
    /// Attempt to integrate it with an existing project or workspace.
    case integration
}

struct NewProject: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "new")
    
    func run() throws {
        switch self.detectExistingProjects() {
        case .project(let name):
            let response = Process().queryUser(
                query: "Found an existing project, '\(name)'. Would you like to integrate with it?",
                choices: ["Yes", "No"]
            )
            
            if response == 0 {
                self.integrate(with: .project(named: name))
            } else {
                self.createFreshProject()
            }
        case .workspace(let name):
            let response = Process().queryUser(
                query: "Found an existing workspace, '\(name)'. Would you like to integrate with it?",
                choices: ["Yes", "No"]
            )
            
            if response == 0 {
                self.integrate(with: .workspace(named: name))
            } else {
                self.createFreshProject()
            }
        case .none:
            self.createFreshProject()
        }
    }
    
    private func detectExistingProjects() -> ExistingProject? {
        print("Checking for existing projects...")
        let string = Process().shell("ls -d *.xcodeproj *.xcworkspace 2>/dev/null")
        let matches = string.split(separator: "\n")
        let projects = matches.filter { $0.hasSuffix(".xcodeproj") }
        let workspaces = matches.filter { $0.hasSuffix(".xcworkspace") }
        
        if let workspace = workspaces.first.map(String.init) {
            return .workspace(named: workspace)
        } else if let project = projects.first.map(String.init) {
            return .project(named: project)
        } else {
            return nil
        }
    }
    
    private func integrate(with: ExistingProject) {
        switch self.queryTemplateType(allowed: [.server, .serverShared]) {
        case .server:
            // Clone server, integrate with proj or workspace
        case .serverShared:
            // Clone server & shared, integrate with proj or workspace
        default:
            // This shouldn't be possible.
            break
        }
    }
    
    private func createFreshProject() {
        switch self.queryTemplateType() {
        case .server:
            // Clone server
        case .serverShared:
            // Clone server, shared
        case .serverSharediOS:
            Process().shell("git clone ")
            // Clone server, shared, iOS
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
