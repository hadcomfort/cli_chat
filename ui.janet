# This is the ui file.

(import string) # For string/trim, string/join
# (import ./utils :as utils) # Assuming utils.janet is in the same directory or resolvable
# For the purpose of this subtask, we'll assume `utils/get-current-os` is available.
# In a real setup, ensure utils.janet is correctly imported.

(defn get-user-query []
  "Checks for command-line arguments or prompts the user for input."
  (let [args (dyn :args)]
    (if (> (length args) 0)
      (string/join args " ")
      (do
        (print "Describe the task: ")
        (flush stdout) # Ensure the prompt is displayed before input
        (string/trim (getline stdin))))))

(defn get-target-environment [detected-os]
  "Prompts the user to confirm or override the detected OS and specify a target shell.

  Args:
    detected-os: A string representing the auto-detected operating system (e.g., \"linux\").

  Returns:
    A table/struct with keys :target-os and :target-shell.
    Example: {:target-os \"linux\" :target-shell \"bash\"}
  "
  (default detected-os "unknown") # Fallback if detected-os is nil

  # 1. Shell Selection
  (print "Detected OS: " detected-os)
  (print "Specify target shell (e.g., bash, zsh, fish, powershell) or press Enter for default: ")
  (flush stdout)
  (def user-shell-input (string/trim (getline stdin)))

  (def target-shell
    (if (empty? user-shell-input)
      (case detected-os
        "linux" "bash"
        "macos" "zsh" # zsh is default on modern macOS, bash is also common
        "windows" "powershell"
        "bash") # Default fallback shell
      user-shell-input))
  (print "Using shell:" target-shell)

  # 2. OS Override
  # Initially, the target OS is the detected OS.
  (def current-target-os detected-os)
  (print "Current target OS for command generation: " current-target-os)
  (print "Press Enter to keep, or specify a different OS (e.g., linux, macos, windows): ")
  (flush stdout)
  (def user-os-override (string/trim (getline stdin)))

  (def final-target-os
    (if (empty? user-os-override)
      current-target-os
      user-os-override))
  (print "Targeting OS:" final-target-os)

  # 3. Return the environment settings
  @{:target-os final-target-os :target-shell target-shell})

# Example of how get-user-query might be called in main.janet:
# (def user-query (get-user-query))
# (print "User query:" user-query)

# Example of how get-target-environment might be called in main.janet:
#
# (comment
#   (def detected-os (utils/get-current-os)) # Requires utils.janet
#   (def env-prefs (get-target-environment detected-os))
#   (print "Chosen environment preferences:" env-prefs)
#   # These preferences would then be used to tailor the prompt to the LLM,
#   # for example, by including them in the system message or user query.
#   # e.g., "Generate a [env-prefs :target-shell] command for [env-prefs :target-os] to [user-query]"
# )

(defn notify-external-api-usage []
  "Prints a notification to the user before an external LLM API call is made.
  This function should be called before initiating any communication with the LLM service."
  (print "\n[INFO] Connecting to an external LLM API to generate the command.")
  (print "Your query, target OS, and target shell information will be sent to a third-party service.")
  (print "Please be mindful of the data you share. If you have privacy concerns, consider reviewing the API provider's privacy policy.")
  (print "---"))

# Example of where main.janet (or a UI orchestrator function) might call this:
# (comment
#   (notify-external-api-usage)
#   # ... proceed to call llm-api/generate-command-and-explanation ...
# )

(import ./filter :as cmd-filter) # Assuming filter.janet is in the same directory

(defn display-command-and-explanation [command explanation warnings]
  "Displays the generated command, its explanation, and any safety warnings.

  Args:
    command: The generated shell command string.
    explanation: The explanation for the command.
    warnings: A list of warning strings from cmd-filter/check-command-safety.
  "
  (print "\n--- Generated Command ---")

  (if (and warnings (> (length warnings) 0))
    (do
      (print "\n⚠️  **CAUTION: The generated command may be risky!** ⚠️")
      (print "Please review the following warnings carefully:")
      (each warning warnings
        (print "  - " warning))
      (print "---")
      # Future enhancement: Ask for confirmation before proceeding
      # (print "Do you want to display the command anyway? (yes/no): ")
      # (flush stdout)
      # (def confirmation (string/trim (getline stdin)))
      # (unless (string/equals-nocase confirmation "yes")
      #   (print "Command display aborted by user.")
      #   (return)) # Or handle differently
      ))

  (if (and command (not (empty? command)))
    (print "\nCommand:\n  " command)
    (print "\nNo command was generated."))

  (if (and explanation (not (empty? explanation)))
    (print "\nExplanation:\n  " explanation)
    (print "\nNo explanation was provided."))

  (print "\n-------------------------"))

# Example of how main.janet might call this:
# (comment
#   # ... (get command, explanation from LLM)
#   # ... (get warnings from (cmd-filter/check-command-safety command))
#   (display-command-and-explanation command explanation warnings)
# )
