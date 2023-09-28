package main

import (
	"os"
	"testing"
)

// given a filename that was not exists
// then expected Shred returns error
func TestShredFileNotFound(t *testing.T) {
	// Create a temporary test file and get its name
	tmpFile, err := os.CreateTemp("", "shred_example_")
	if err != nil {
		t.Fatal(err)
	}
	os.Remove(tmpFile.Name())

	// Call Shred with a non-existent filename
	err = Shred(tmpFile.Name())

	// Check if the error is not nil (file not found)
	if err == nil {
		t.Errorf("Expected error, but got nil for file %s", tmpFile.Name())
	}
}

// given a filename that was not exists
// then expected Shred returns success
func TestShredFileFound(t *testing.T) {
	// Create a temporary test file and get its name
	tmpFile, err := os.CreateTemp("", "shred_example_")
	if err != nil {
		t.Fatal(err)
	}
	// Remove the temporary file when test finished
	defer os.Remove(tmpFile.Name())

	// Call Shred with the existing filename
	err = Shred(tmpFile.Name())

	// Check if the error is nil (file found)
	if err != nil {
		t.Errorf("Expected no error, but got %v for file %s", err, tmpFile.Name())
	}
}
