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

	// Create a channel for progress updates
	progressCh := make(chan int)
	errCh := make(chan error)

	go func() {
		err := Shred(filename, progressCh)
		errCh <- err
		close(progressCh)
	}()

	for {
		select {
		case progress, ok := <-progressCh:
			if !ok {
				fmt.Println("")
				return
			}
			fmt.Printf("Shredding %s (%d%%)\r", filename, progress)
		case err := <-errCh:
			if err != nil {
				fmt.Printf("\nError: %v\n", err)
				return
			}
		}
	}
}
