package main

import (
	"fmt"
	"io"
	"os"
)

// 1K chunk size
const (
	chunkSize  = 1024
	shredCount = 3
)

func Shred(filename string) error {
	// Check if the file exists
	fileInfo, err := os.Stat(filename)
	if err != nil {
		fmt.Printf("File %s not found\n", filename)
		return err
	}

	fileSize := fileInfo.Size()

	fmt.Printf("File %s found (%d bytes)\n", filename, fileSize)

	for i := 1; i <= shredCount; i++ {
		if err := DoShred(filename, fileSize); err != nil {
			return err
		}
	}
	return nil
}

// DoShred is a function that shreds a file with random data.
func DoShred(filename string, fileSize int64) error {
	file, err := os.OpenFile(filename, os.O_WRONLY, os.ModePerm)
	if err != nil {
		return err
	}
	defer file.Close()

	randomFile, err := os.Open("/dev/urandom")
	if err != nil {
		return err
	}
	defer randomFile.Close()
	randomData := make([]byte, chunkSize)

	for offset := int64(0); offset < fileSize; offset += chunkSize {
		// Generate random data for the chunk
		_, err := io.ReadFull(randomFile, randomData)
		if err != nil {
			return err
		}

		// Seek to the current offset and write the random data
		_, err = file.Seek(offset, io.SeekStart)
		if err != nil {
			return err
		}

		_, err = file.Write(randomData)
		if err != nil {
			return err
		}
	}

	// Sync and truncate the file to ensure data is written
	if err := file.Sync(); err != nil {
		return err
	}

	return nil
}
