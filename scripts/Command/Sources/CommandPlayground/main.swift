import Command

let command = Command("echo hello there my name is obi-wan")
try await command.run()

print(await command.standardOutput!)
