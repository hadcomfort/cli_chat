# offline-templates.janet
# Defines a list of command templates for offline fallback.

# Each template is a table with:
#   :keywords (array of strings): Keywords to match against the user query (case-insensitive).
#   :command-template (string): The command to suggest.
#                                (Placeholders like {{OS}} or {{SHELL}} can be considered for future enhancements).
#   :explanation-template (string): The explanation for the command.

(def offline-command-templates
  @[
    @{:keywords ["list files" "ls" "show files" "list directory"]
      :command-template "ls -la"
      :explanation-template "Lists all files and directories in the current location with detailed information, including hidden files."}

    @{:keywords ["show current directory" "pwd" "current path" "which directory"]
      :command-template "pwd"
      :explanation-template "Prints the full path of the current working directory."}

    @{:keywords ["my ip address" "what is my ip" "show ip" "network address"]
      :command-template "# Use OS-specific commands like 'ip addr' or 'ifconfig' on Linux/macOS, or 'ipconfig' on Windows."
      :explanation-template "To find your IP address, you typically use commands like 'ip addr' (Linux), 'ifconfig' or 'ipconfig getifaddr en0' (macOS), or 'ipconfig' (Windows). This cannot be determined by a single universal offline command."}

    @{:keywords ["how to make directory" "create folder" "mkdir"]
      :command-template "mkdir new_directory_name"
      :explanation-template "Creates a new directory. Replace 'new_directory_name' with your desired directory name."}

    @{:keywords ["copy file" "cp"]
      :command-template "cp source_file destination_file"
      :explanation-template "Copies a file. Replace 'source_file' with the path to the file to copy and 'destination_file' with the path to the copy."}

    # Add more templates here as needed.
    # Examples:
    # @{:keywords ["find text in file" "grep"]
    #   :command-template "grep \"your text\" filename"
    #   :explanation-template "Searches for \"your text\" within the specified filename."}
    # @{:keywords ["show disk space" "df"]
    #   :command-template "df -h"
    #   :explanation-template "Shows disk space usage for all mounted filesystems in a human-readable format."}
  ])

# For future: Consider using PEGs for more complex keyword matching if simple string finding becomes insufficient.
# (import peg)
# Example PEG pattern for keywords:
# (def list-peg (peg/compile ~{:main (* (any (+ "list" "show")) "files")}))
# Then in the handler: (peg/match list-peg user-query)
# This would allow more flexible matching, e.g., "list all files", "show some files".
# For now, simple keyword array and string/find is used.
