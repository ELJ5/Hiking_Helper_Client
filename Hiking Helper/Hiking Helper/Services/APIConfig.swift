
import Foundation
struct APIConfig {
    static let openAIKey: String = {
        // Create a Secrets.plist file with key "OPENAI_API_KEY"
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["OPENAI_API_KEY"] as? String else {
            fatalError("OpenAI API Key not found. Create Secrets.plist with OPENAI_API_KEY")
        }
        return key
    }()
}
