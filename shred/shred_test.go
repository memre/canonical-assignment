package main

import (
	"io"
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
	// Remvove the file
	os.Remove(tmpFile.Name())

	// Call Shred with a non-existent filename
	err = Shred(tmpFile.Name())

	// Check if the error is not nil (file not found)
	if err == nil {
		t.Errorf("Expected error, but got nil for file %s", tmpFile.Name())
	}
}

// given a filename that was created before
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

// given a filename that was not exists
// then expected DoShred cannot shred the file
func TestDoShredFileNotExists(t *testing.T) {
	// Create a temporary test file and get its name
	tmpFile, err := os.CreateTemp("", "shred_example_")
	if err != nil {
		t.Fatal(err)
	}
	// Remove the file
	os.Remove(tmpFile.Name())

	// Call Shred with the existing filename
	err = DoShred(tmpFile.Name(), 34343)

	// Check if the error is not nil (file not found)
	if err == nil {
		t.Errorf("Expected error, but got nil for file %s", tmpFile.Name())
	}
}

// given a filename that was created before
// then expected DoShred shreds the file content
func TestDoShred(t *testing.T) {
	// Create a temporary test file and get its name
	tmpFile, err := os.CreateTemp("", "shred_example_")
	if err != nil {
		t.Fatal(err)
	}
	// Remove the temporary file when test finished
	defer os.Remove(tmpFile.Name()) // Remove the temporary file

	// Populate the file with random data (4K)
	randomData := make([]byte, 4*1024)
	randomFile, err := os.Open("/dev/urandom")
	if err != nil {
		t.Fatal(err)
	}
	defer randomFile.Close()
	_, err = io.ReadFull(randomFile, randomData)
	if err != nil {
		t.Fatal(err)
	}
	_, err = tmpFile.Write(randomData)
	if err != nil {
		t.Fatal(err)
	}

	// Save the original content
	originalContent, err := os.ReadFile(tmpFile.Name())
	if err != nil {
		t.Fatal(err)
	}

	// Call DoShred on the file
	err = DoShred(tmpFile.Name(), int64(len(randomData)))
	if err != nil {
		t.Fatal(err)
	}

	// Read the content after shredding
	shreddedContent, err := os.ReadFile(tmpFile.Name())
	if err != nil {
		t.Fatal(err)
	}

	// Compare the content before and after shredding
	if string(originalContent) == string(shreddedContent) {
		t.Error("File content is not different after shredding")
	}
}
