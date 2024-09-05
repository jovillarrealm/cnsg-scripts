package main
// This script is based on the count_fasta_cnsg.pl file, originally by Joseph Fass (modified from script by Brad Sickler and then CNSG)

import (
	"bufio"
	"encoding/csv"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"github.com/valyala/bytebufferpool"
)


// Sequence represents a single sequence from the FASTA file
type Sequence struct {
	ID   string // Sequence identifier
	Len  int    // Length of the sequence
	GC   int    // Count of G and C nucleotides
	N    int    // Count of N nucleotides
}

// Stats contains all calculated statistics for the sequences
type Stats struct {
	TotalLength      int     // Sum of all sequence lengths
	NumSequences     int     // Total number of sequences
	AverageLength    int     // Average sequence length
	LargestContig    int     // Length of the largest sequence
	ShortestContig   int     // Length of the shortest sequence
	N25              int     // N25 statistic (25% of total length)
	N50              int     // N50 statistic (50% of total length)
	N75              int     // N75 statistic (75% of total length)
	TotalGC          int     // Total count of G and C nucleotides
	GCPercent        float64 // Percentage of GC content
	TotalN           int     // Total count of N nucleotides
	NPercent         float64 // Percentage of N content
}

func main() {
	// Check if the correct number of command-line arguments are provided
	if len(os.Args) < 3 {
		fmt.Println("Usage: go run script.go <fasta_file> <output_csv>")
		os.Exit(1)
	}

	fastaFile := os.Args[1]
	outputCSV := os.Args[2]

	// Process the FASTA file and get sequence information
	sequences, err := processFile(fastaFile)
	if err != nil {
		fmt.Printf("Error processing file: %v\n", err)
		os.Exit(1)
	}

	// Calculate statistics from the processed sequences
	stats := calculateStats(sequences)

	// Print statistics to console
	//printStats(stats)

	// Write statistics to CSV file
	err = writeStatsToCSV(outputCSV, stats, fastaFile)
	if err != nil {
		fmt.Printf("Error writing to CSV: %v\n", err)
		os.Exit(1)
	}
}

// processFile reads the FASTA file and extracts sequence information
func processFile(path string) ([]Sequence, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	scanner.Buffer(make([]byte, 1024*1024), 1024*1024*1024) // 1MB buffer, max 1GB line

	var sequences []Sequence
	var currentSeq Sequence
	seqBuffer := bytebufferpool.Get()
	defer bytebufferpool.Put(seqBuffer)

	for scanner.Scan() {
		line := scanner.Bytes()
		if len(line) > 0 && line[0] == '>' {
			// Start of a new sequence
			if seqBuffer.Len() > 0 {
				// Save the previous sequence if it exists
				currentSeq.Len = seqBuffer.Len()
				sequences = append(sequences, currentSeq)
				seqBuffer.Reset()
			}
			currentSeq = Sequence{ID: string(line[1:])}
		} else {
			// Continuation of the current sequence
			seqBuffer.Write(line)
			currentSeq.GC += countBytes(line, "GCgc")
			currentSeq.N += countBytes(line, "Nn")
		}
	}

	// Save the last sequence
	if seqBuffer.Len() > 0 {
		currentSeq.Len = seqBuffer.Len()
		sequences = append(sequences, currentSeq)
	}

	if err := scanner.Err(); err != nil {
		return nil, err
	}

	return sequences, nil
}

// countBytes counts the occurrences of specified characters in a byte slice
func countBytes(data []byte, chars string) int {
	count := 0
	for _, b := range data {
		if strings.IndexByte(chars, b) != -1 {
			count++
		}
	}
	return count
}

// calculateStats computes various statistics from the processed sequences
func calculateStats(sequences []Sequence) Stats {
	var stats Stats
	var lengths []int

	for _, seq := range sequences {
		stats.TotalLength += seq.Len
		stats.TotalGC += seq.GC
		stats.TotalN += seq.N
		lengths = append(lengths, seq.Len)
	}

	stats.NumSequences = len(sequences)
	stats.AverageLength = stats.TotalLength / stats.NumSequences
	sort.Sort(sort.Reverse(sort.IntSlice(lengths)))
	stats.LargestContig = lengths[0]
	stats.ShortestContig = lengths[len(lengths)-1]

	stats.N25 = calculateNX(lengths, stats.TotalLength, 0.25)
	stats.N50 = calculateNX(lengths, stats.TotalLength, 0.50)
	stats.N75 = calculateNX(lengths, stats.TotalLength, 0.75)

	stats.GCPercent = float64(stats.TotalGC) / float64(stats.TotalLength) * 100
	stats.NPercent = float64(stats.TotalN) / float64(stats.TotalLength) * 100

	return stats
}

// calculateNX calculates the NX statistic (e.g., N50) for the given lengths
func calculateNX(lengths []int, totalLength int, fraction float64) int {
	threshold := int(float64(totalLength) * fraction)
	var sum int
	for _, length := range lengths {
		sum += length
		if sum >= threshold {
			return length
		}
	}
	return 0
}

// printStats displays the calculated statistics to the console
func printStats(stats Stats) {
	fmt.Printf("Total length of sequence:\t%d bp\n", stats.TotalLength)
	fmt.Printf("Total number of sequences:\t%d\n", stats.NumSequences)
	fmt.Printf("Average contig length is:\t%d bp\n", stats.AverageLength)
	fmt.Printf("Largest contig:\t\t%d bp\n", stats.LargestContig)
	fmt.Printf("Shortest contig:\t%d bp\n", stats.ShortestContig)
	fmt.Printf("N25 stats:\t\t%d bp\n", stats.N25)
	fmt.Printf("N50 stats:\t\t%d bp\n", stats.N50)
	fmt.Printf("N75 stats:\t\t%d bp\n", stats.N75)
	fmt.Printf("Total GC count:\t\t%d bp\n", stats.TotalGC)
	fmt.Printf("GC %%:\t\t\t%.2f %%\n", stats.GCPercent)
	fmt.Printf("Number of Ns:\t\t%d\n", stats.TotalN)
	fmt.Printf("Ns %%:\t\t\t%.2f %%\n", stats.NPercent)
}

// writeStatsToCSV writes the calculated statistics to a CSV file
func writeStatsToCSV(outputPath string, stats Stats, fastaFile string) error {
	file, err := os.OpenFile(outputPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return err
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	writer.Comma = ';'
	defer writer.Flush()

	fileInfo, err := file.Stat()
	if err != nil {
		return err
	}

	if fileInfo.Size() == 0 {
		// Write header if file is empty
		header := []string{
			"filename", "total_length", "number_of_sequences", "average_length",
			"largest_contig", "shortest_contig", //"N25", "N50", "N75",
			"total_GC", "GC_percentage", "total_N", "N_percentage",
		}
		if err := writer.Write(header); err != nil {
			return err
		}
	}

	// Write stats
	row := []string{
		filepath.Base(fastaFile),
		strconv.Itoa(stats.TotalLength),
		strconv.Itoa(stats.NumSequences),
		strconv.Itoa(stats.AverageLength),
		strconv.Itoa(stats.LargestContig),
		strconv.Itoa(stats.ShortestContig),
		//strconv.Itoa(stats.N25),
		//strconv.Itoa(stats.N50),
		//strconv.Itoa(stats.N75),
		strconv.Itoa(stats.TotalGC),
		strconv.FormatFloat(stats.GCPercent, 'f', 2, 64),
		strconv.Itoa(stats.TotalN),
		strconv.FormatFloat(stats.NPercent, 'f', 2, 64),
	}

	if err := writer.Write(row); err != nil {
		return err
	}

	return nil
}