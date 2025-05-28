# This is the llm-api file.

(import os)
(import parser)
(import vm)
(import joy/path)
(import http) # Added for http/post
(import json) # Added for json/encode and json/decode
(import string) # Added for string/split

# Configuration file path
(def config-dir (path/join (os/homedir) ".config" "cli-cmd-gen"))
(def config-file (path/join config-dir "config.janet"))

# Ensure the configuration directory exists
(unless (os/stat config-dir)
  (os/mkdir config-dir))

(defn get-api-key []
  "Retrieves the API key from environment variable, config file, or user prompt.

  The order of precedence is:
  1. Environment variable (CLI_CMD_GEN_API_KEY) - Most secure for CI/CD or ephemeral environments.
  2. Configuration file (~/.config/cli-cmd-gen/config.janet) - Convenient for local development.
     The file should contain: (def api-key \"YOUR_API_KEY_HERE\")
  3. User prompt - Least secure, used as a last resort. Avoid for regular use if possible.

  Security Considerations:
  - Environment Variables: Generally secure, especially if managed by a secrets manager or
    set temporarily in a session. Avoid committing them to version control.
  - Config File: Store with restricted permissions (e.g., chmod 600).
    Be mindful of who has access to your machine and home directory.
  - User Prompt: The key will be visible as you type it and might be stored in shell history
    depending on your shell's configuration. This method is provided for ease of first use
    but is not recommended for regular operation where security is paramount.
  "
  (let [env-key (os/getenv "CLI_CMD_GEN_API_KEY")]
    (if (and env-key (not (empty? env-key)))
      (do
        (print "API key found in environment variable CLI_CMD_GEN_API_KEY.")
        env-key)
      (let [key-from-file (try
                            (let [config-content (slurp config-file)
                                  parsed-forms (parser/parse config-content)
                                  env (vm/make-env)]
                              # Run the parsed forms in the new environment
                              (each form parsed-forms (vm/run form env))
                              # Attempt to get the api-key from the environment
                              (if (get env 'api-key)
                                (get env 'api-key)
                                nil))
                            ([err] # Catch any error during file read or parse
                              (print "Info: Could not read or parse API key from" config-file ":" err)
                              nil))]
        (if key-from-file
          (do
            (print "API key found in configuration file:" config-file)
            key-from-file)
          (do
            (print "API key not found in environment variable or config file.")
            (print "Please enter your API key: ")
            (flush stdout) # Ensure prompt is displayed before input
            (let [user-input (string/trim (getline stdin))]
              (if (empty? user-input)
                (error "API key cannot be empty.") # Or handle as a retry
                user-input))))))))

# --- LLM API Communication ---

# Define the API endpoint and model (can be made configurable later)
(def llm-api-url "https://api.openai.com/v1/chat/completions")
(def llm-model "gpt-3.5-turbo") # Or any other suitable model

(defn generate-command-and-explanation [user-query api-key target-os target-shell]
  "Generates a shell command and its explanation using an LLM,
  tailored for a specific operating system and shell.

  Args:
    user-query: The natural language query from the user.
    api-key: The API key for authenticating with the LLM service.
    target-os: The target operating system (e.g., \"linux\", \"macos\", \"windows\").
    target-shell: The target shell (e.g., \"bash\", \"zsh\", \"powershell\").

  Returns:
    A tuple [command, explanation] if successful.
    A tuple [nil, error-message] if an error occurs.
  "
  # 1. Construct the detailed prompt for the LLM
  (def prompt-template
    ``
    You are a highly intelligent CLI command generator.
    Based on the user's natural language query, generate a single, appropriate shell command
    for the specified target OS and shell.
    Also, provide a concise, one-sentence explanation of what the command does.
    Format your output strictly as follows:
    The shell command on the first line.
    A newline character.
    The one-sentence explanation on the second line.

    Example (for linux/bash, query: find text files):
    find . -name \"*.txt\"
    This command finds all files with the .txt extension in the current directory and its subdirectories.

    User query: \"%s\"
    Target OS: %s
    Target Shell: %s
    ``)
  (def full-prompt (string/format prompt-template user-query target-os target-shell)) # Pass target_os and target_shell here for user message

  # 2. Prepare the API Request Payload
  (def system-message-content
    (string/format "You are a helpful assistant that generates shell commands and explanations. The user is on %s and wants a command for the %s shell. Ensure the command is valid for this environment." target-os target-shell))

  (def payload @{
                 :model llm-model
                 :messages @[
                             @{:role "system" :content system-message-content}
                             @{:role "user" :content full-prompt} # full-prompt now also contains OS/shell for clarity in user message
                             ]
                 :temperature 0.5 # Adjust for creativity vs. determinism
                 })
  (def json-payload (json/encode payload))

  # 3. Make the HTTP POST Request (Simulated)
  (def headers @{
                 :Authorization (string "Bearer " api-key)
                 :Content-Type "application/json"
                 })

  # --- SIMULATED HTTP CALL ---
  # In a real scenario, you would make an actual HTTP call here.
  # For testing without network access or a live API key, we simulate the response.
  # (print "Simulating HTTP POST request to:" llm-api-url)
  # (print "Headers:" headers)
  # (print "Payload:" json-payload)

  # Example of an actual HTTP POST call (commented out):
  # (def response (try
  #                 (http/post llm-api-url json-payload headers)
  #               ([err]
  #                 (print "HTTP request failed:" err)
  #                 {:status 500 :body (json/encode @{:error @{:message (string "HTTP request error: " err)}})})))

  # Hardcoded successful response for testing
  (def simulated-response-success true) # Set to false to test error handling

  (def response
    (if simulated-response-success
      @{
        :status 200
        :body (json/encode @{
                             :choices @[
                                       @{
                                         :message @{
                                                     :content "ls -la\nLists all files and directories in the current location with detailed information."
                                                     }
                                         }
                                       ]
                             })
        }
      # Hardcoded error response for testing (e.g., invalid API key)
      @{
        :status 401 # Unauthorized
        :body (json/encode @{
                             :error @{
                                       :message "Invalid API key."
                                       :type "auth_error"
                                       :code "invalid_api_key"
                                       }
                             })
        }))


  # 4. Parse the Response
  (if (not= (:status response) 200)
    (do
      (err "LLM API request failed with status:" (:status response))
      (let [error-body (try (json/decode (buffer/to-string (:body response))) ([_] @{}))
            error-msg (get-in error-body [:error :message] "Unknown API error")]
        [nil (string "API Error (" (:status response) "): " error-msg)]))
    (let [response-body (try
                          (json/decode (buffer/to-string (:body response)))
                        ([err]
                          (err "Failed to decode JSON response:" err)
                          nil))]
      (if (nil? response-body)
        [nil "Failed to parse LLM response JSON."]
        (let [content (get-in response-body [:choices 0 :message :content])]
          (if (nil? content)
            [nil "Could not extract content from LLM response. Unexpected format."]
            (let [parts (string/split "\n" content 2)] # Split into max 2 parts
              (if (< (length parts) 2)
                [nil (string "LLM response content is not in the expected format (command\\nexplanation). Received: " content)]
                [(string/trim (parts 0)) (string/trim (parts 1))]))))))))


# Example of how this might be called (for testing purposes):
# (defn test-llm-api []
#   (print "Testing LLM API function...")
#   (def test-query "list all files in current directory")
#   (def test-api-key "fake-api-key-for-testing")
#   (def test-os "linux")
#   (def test-shell "bash")
#   (let [[command explanation] (generate-command-and-explanation test-query test-api-key test-os test-shell)]
#     (if command
#       (do
#         (print "Generated Command:" command)
#         (print "Explanation:" explanation))
#       (print "Error:" explanation))))
#
# (test-llm-api)

# To test the error path, you can change `simulated-response-success` to `false`
# inside `generate-command-and-explanation` and re-run.
#
# (defn test-llm-api-error []
#   (print "Testing LLM API error path...")
#   (def temp-generate-command-and-explanation generate-command-and-explanation)
#   # Temporarily modify the function for this test to simulate error
#   # This is a bit hacky for a simple test; normally you might have other ways to inject test data
#   (def generate-command-and-explanation
#     (fn [user-query api-key target-os target-shell] # Add new params here too if using this test
#       (print "SIMULATING ERROR RESPONSE for " target-os "/" target-shell)
#       # Directly return an error structure similar to how the real function would
#       [nil "Simulated API Error (401): Invalid API key."]))
#
#   (def test-query "list all files")
#   (def test-api-key "fake-key")
#   (def test-os "macos")
#   (def test-shell "zsh")
#   (let [[cmd err-msg] (generate-command-and-explanation test-query test-api-key test-os test-shell)]
#     (if cmd
#       (print "Unexpected success:" cmd)
#       (print "Correctly handled error:" err-msg)))
#   # Restore original function
#   (def generate-command-and-explanation temp-generate-command-and-explanation))
#
# (test-llm-api-error)
