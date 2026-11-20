# Loads mise's completions from the installed mise the first time fish
# completes a mise command. The script asks mise for candidates as you type,
# so it also completes task names, with their descriptions, and tool versions.
if command -q mise
    mise completion fish | source
end
