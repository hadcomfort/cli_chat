# This is the utils file.

(defn get-current-os []
  "Determines the host operating system and returns its name as a lowercase string.

  This function uses Janet's dynamic binding `(dyn :os)` to identify the
  operating system. The result is then converted to a lowercase string.

  Possible return values include:
    \"linux\"
    \"macos\"
    \"windows\"
    \"freebsd\"
    \"netbsd\"
    \"openbsd\"
    \"dragonfly\"
    \"solaris\"
    \"android\"
    \"emscripten\"
    (and potentially others depending on the Janet build and underlying system)
  "
  (string/ascii-lower (string (dyn :os))))

# Example usage (for testing purposes):
# (print "Detected OS:" (get-current-os))
