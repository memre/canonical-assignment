package main

import (
	"fmt"
	"os"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Println("Usage: main <filename>")
		os.Exit(1)
	}

	// Get the filename from command-line argument
	filename := os.Args[1]

	if err := Shred(filename); err != nil {
		fmt.Printf("Error while shredding file: %v\n", err)
		os.Exit(1)
	}
}
