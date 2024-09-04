package main

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"sort"
	"strings"

	"github.com/valyala/bytebufferpool"
)

// Sequence represents a FASTA sequence with its statistics
type Sequence struct {
	ID   string // Sequence identifier
	Len  int    // Length of the sequence
	GC   int    // Count of G and C nucleotides
	N    int    // Count of N nucleotides
}

func main() {
	// Check if a file path is provided as a command-line argument
	if len(os.Args) < 2 {
		fmt.Println("Usage: go run script.go <fasta_file>")
		os.Exit(1)
	}

	// Open the FASTA file
	file, err := os.Open(os.Args[1])
	if err != nil {
		fmt.Println("Error opening file:", err)
		os.Exit(1)
	}
	defer file.Close()

	// Process the file and get sequence statistics
	sequences := processFile(file)

	// Print the calculated statistics
	printStats(sequences)
}

// processFile reads the FASTA file and returns a slice of Sequence structs
func processFile(file io.Reader) []Sequence {
	scanner := bufio.NewScanner(file)
	// Set a larger buffer size to handle long lines
	scanner.Buffer(make([]byte, 1024*1024), 1024*1024*1024) // 1MB buffer, max 1GB line

	var sequences []Sequence
	var currentSeq Sequence
	seqBuffer := bytebufferpool.Get() // Get a buffer from the pool
	defer bytebufferpool.Put(seqBuffer) // Return the buffer to the pool when done

	for scanner.Scan() {
		line := scanner.Bytes()
		if len(line) > 0 && line[0] == '>' {
			// New sequence encountered
			if seqBuffer.Len() > 0 {
				// Process the previous sequence
				currentSeq.Len = seqBuffer.Len()
				sequences = append(sequences, currentSeq)
				seqBuffer.Reset()
			}
			// Initialize new sequence
			currentSeq = Sequence{ID: string(line[1:])}
		} else {
			// Process sequence data
			seqBuffer.Write(line)
			currentSeq.GC += countBytes(line, "GCgc")
			currentSeq.N += countBytes(line, "Nn")
		}
	}

	// Process the last sequence
	if seqBuffer.Len() > 0 {
		currentSeq.Len = seqBuffer.Len()
		sequences = append(sequences, currentSeq)
	}

	return sequences
}

// countBytes counts occurrences of bytes from the chars string in the data
func countBytes(data []byte, chars string) int {
	count := 0
	for _, b := range data {
		if strings.IndexByte(chars, b) != -1 {
			count++
		}
	}
	return count
}

// printStats calculates and prints various statistics about the sequences
func printStats(sequences []Sequence) {
	totalLength := 0
	totalGC := 0
	totalN := 0
	lengths := make([]int, len(sequences))

	for i, seq := range sequences {
		totalLength += seq.Len
		totalGC += seq.GC
		totalN += seq.N
		lengths[i] = seq.Len
	}

	// Sort lengths in descending order
	sort.Sort(sort.Reverse(sort.IntSlice(lengths)))

	// Print basic statistics
	fmt.Printf("Total length of sequence:\t%d bp\n", totalLength)
	fmt.Printf("Total number of sequences:\t%d\n", len(sequences))
	fmt.Printf("Average contig length:\t%d bp\n", totalLength/len(sequences))
	fmt.Printf("Largest contig:\t\t%d bp\n", lengths[0])
	fmt.Printf("Shortest contig:\t%d bp\n", lengths[len(lengths)-1])

	// Print N25, N50, N75 statistics
	printNStats(lengths, totalLength)

	// Print GC and N content statistics
	fmt.Printf("Total GC count:\t\t%d bp\n", totalGC)
	fmt.Printf("GC %%:\t\t\t%.2f %%\n", float64(totalGC)/float64(totalLength)*100)
	fmt.Printf("Number of Ns:\t\t%d\n", totalN)
	fmt.Printf("Ns %%:\t\t\t%.2f %%\n", float64(totalN)/float64(totalLength)*100)
}

// printNStats calculates and prints N25, N50, and N75 statistics
func printNStats(lengths []int, totalLength int) {
	n25, n50, n75 := 0, 0, 0
	n25count, n50count, n75count := 0, 0, 0
	sum := 0

	for _, length := range lengths {
		sum += length
		n75count++
		if sum >= totalLength/4 && n25 == 0 {
			n25 = length
			n25count = n75count
		}
		if sum >= totalLength/2 && n50 == 0 {
			n50 = length
			n50count = n75count
		}
		if sum >= 3*totalLength/4 && n75 == 0 {
			n75 = length
			break
		}
	}

	fmt.Printf("N25 stats:\t\t25%% of total sequence length is contained in the %d sequences >= %d bp\n", n25count, n25)
	fmt.Printf("N50 stats:\t\t50%% of total sequence length is contained in the %d sequences >= %d bp\n", n50count, n50)
	fmt.Printf("N75 stats:\t\t75%% of total sequence length is contained in the %d sequences >= %d bp\n", n75count, n75)
}