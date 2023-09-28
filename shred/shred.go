package main

import (
	"fmt"
	"os"
)

func Shred(filename string) error {
	// Check if the file exists
	if _, err := os.Stat(filename); os.IsNotExist(err) {
		fmt.Printf("File %s not found\n", filename)
		return err
	}

	fmt.Printf("File %s found\n", filename)
	return nil
}
