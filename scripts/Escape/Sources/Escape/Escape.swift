let escape = "\u{1B}"

func escape(_ string: String, terminator: String = "\n") {
	print("\(escape)\(string)", terminator: terminator)
}
