# This is the filter file.
(import string)

# --- Destructive Command Patterns ---
# This is a list of patterns and associated warnings.
# To extend, add a new table to this list with a :pattern and :warning.
# Patterns can be simple strings. For more complex matching, PEGs (Parsing Expression Grammars)
# could be used with `(peg/match pattern command)`, but for simplicity,
# we primarily use `string/find` here for keyword spotting.

(def destructive-patterns
  @[
    # General sudo usage
    @{:pattern "sudo"
      :warning "Warning: Command uses 'sudo'. Ensure you understand its implications and that it's necessary."}

    # Common destructive commands often used with sudo
    @{:pattern "sudo rm"
      :warning "Warning: Command uses 'sudo rm'. This can permanently delete files/directories system-wide. Double-check the path and command."}
    @{:pattern "sudo mkfs"
      :warning "Warning: Command uses 'sudo mkfs'. This can format a partition and ERASE ALL DATA on it. Ensure the target device is correct."}
    @{:pattern "sudo dd"
      :warning "Warning: Command uses 'sudo dd'. Incorrect use of 'dd' can lead to DATA LOSS by overwriting filesystems or disks. Verify 'if=' and 'of=' parameters."}

    # Standalone potentially dangerous commands
    @{:pattern "rm -rf"
      :warning "Warning: Command uses 'rm -rf'. This will forcefully and recursively delete files/directories. Ensure the path is correct as this is irreversible."}
    @{:pattern "mkfs" # Without sudo, less likely to be system-critical but still dangerous
      :warning "Warning: Command uses 'mkfs'. This can format a partition and ERASE ALL DATA on it. Ensure the target device is correct."}
    @{:pattern "dd" # Without sudo, can still overwrite user files if 'of=' is not carefully set
      :warning "Warning: Command uses 'dd'. Incorrect use of 'dd' can lead to DATA LOSS by overwriting files. Verify 'if=' and 'of=' parameters carefully."}
    @{:pattern ":(){:|:&};:"
      :warning "Critical Warning: Command appears to be a 'fork bomb'. Executing this can freeze your system by rapidly consuming resources."}
    @{:pattern ">/dev/sd" # Matches >/dev/sda, >/dev/sdb, etc.
      :warning "Critical Warning: Command appears to be redirecting output directly to a block device (e.g., /dev/sda). This can CORRUPT YOUR FILESYSTEM AND CAUSE DATA LOSS."}
    @{:pattern "| sudo" # Piping to sudo
      :warning "Warning: Command pipes output to 'sudo'. Ensure the preceding command's output is safe and intended for privileged execution."}
    # Add more patterns here, for example:
    # @{:pattern "chown" :warning "Warning: 'chown' changes file ownership. Use with care."}
    # @{:pattern "chmod .* [0-7][0-7][0-7][0-7]" :warning "Warning: 'chmod' with octal mode. Ensure permissions are as intended."} # Would need PEG for this
  ])

(defn check-command-safety [command]
  "Scans a given command string for potentially destructive patterns.

  Args:
    command: The shell command string to check.

  Returns:
    A list of warning strings. If no risky patterns are found,
    returns an empty list.
  "
  (def warnings-found @[])
  (unless (string? command)
    (array/push warnings-found "Error: Invalid command input (not a string).")
    (return warnings-found)) # Early exit if command is not a string

  (each pattern-entry destructive-patterns
    (let [pattern (:pattern pattern-entry)
          warning-message (:warning pattern-entry)]
      # Using string/find for simple substring matching.
      # For more complex patterns, (peg/match peg-pattern command) would be more robust.
      (if (string/find pattern command)
        (array/push warnings-found warning-message))))
  warnings-found)

# --- Placeholder for Advanced Analysis ---
# For more sophisticated analysis (e.g., understanding command structure,
# argument parsing, or detecting more subtle risks), one might consider:
# 1. Building a more comprehensive PEG-based parser for shell command syntax.
# 2. Integrating with a dedicated static analysis library for shell scripts (if available).
# 3. Using an allowlist approach for known safe commands if the scope is very limited.
# However, for this tool, the current pattern-matching approach provides a
# reasonable first line of defense.

# --- Example Usage (for testing) ---
# (comment
#   (def test-commands @[
#     "ls -la"
#     "sudo rm -rf /tmp/my_stuff"
#     "echo 'hello' > /dev/sda1"
#     "dd if=/dev/zero of=/tmp/output.img bs=1M count=10"
#     "sudo mkfs.ext4 /dev/sdb1"
#     ":(){:|:&};:"
#     "git commit -m 'initial commit'"
#     "curl http://example.com | sudo bash"
#     123 # Invalid input test
#   ])
#
#   (each cmd test-commands
#     (print "Testing command: " (string cmd))
#     (def warnings (check-command-safety cmd))
#     (if (> (length warnings) 0)
#       (each warning warnings (print "  " warning))
#       (print "  No obvious risks detected.")))
#
#   # Test adding a new pattern (example)
#   (array/push destructive-patterns @{:pattern "fdisk" :warning "Warning: 'fdisk' is a disk partitioning utility. Use with extreme caution."})
#   (print "\nTesting with added 'fdisk' pattern:")
#   (def warnings-fdisk (check-command-safety "sudo fdisk /dev/sda"))
#   (each warning warnings-fdisk (print "  " warning))
# )
