import Foundation
import DopamineCore

// Local CLI smoke run for the Swift engine behavior.
let engine = DopamineEngine()
let sessionID = "cli-session"

var response = engine.start(sessionID: sessionID)
print("Started Dopamine session.")
print("Scores: F=\(response.scores.focus) M=\(response.scores.momentum) P=\(response.scores.progress)")

let demoMessages = [
    "I need to finish the onboarding email copy today.",
    "Done with draft one and sent it for review.",
    "Now I am switching to budget planning and roadmap sequencing.",
    "why is my focus score low and how can I improve momentum?"
]

for message in demoMessages {
    response = engine.postMessage(sessionID: sessionID, content: message)
    let lastAssistant = response.assistantMessage.content
    print("\nUser: \(message)")
    print("Assistant: \(lastAssistant)")
    print("Scores: F=\(response.scores.focus) M=\(response.scores.momentum) P=\(response.scores.progress)")
    print("Active projects: \(response.activeProjects.map(\.name).joined(separator: ", "))")
}

response = engine.finish(sessionID: sessionID)
print("\nFinal reflection: \(response.assistantMessage.content)")
