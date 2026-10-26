package main

import (
	"bufio"
	"context"
	"errors"
	"fmt"
	"io"
	"math"
	"os"
	"strconv"
	"strings"
	"time"

	pb "example.com/grpcclient02/calculator"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/status"
)

const serverAddress = "127.0.0.1:5000"

func main() {
	connection, err := grpc.NewClient(
		serverAddress,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		fmt.Printf("Failed to create gRPC client: %v\n", err)
		return
	}
	defer connection.Close()

	client := pb.NewCalculatorClient(connection)
	scanner := bufio.NewScanner(os.Stdin)

	fmt.Println("gRPCClient02")
	fmt.Printf("Server: %s\n", serverAddress)

	for {
		fmt.Println()
		fmt.Println("1. SUM")
		fmt.Println("2. SUB")
		fmt.Println("3. MUL")
		fmt.Println("4. DIV")
		fmt.Println("5. FACT")
		fmt.Println("0. Exit")

		operation, err := readLine(scanner, "Choose an operation: ")
		if err != nil {
			return
		}

		if operation == "0" {
			return
		}

		switch operation {
		case "1", "2", "3", "4", "5":
		default:
			fmt.Println("Invalid operation. Choose a number from 0 to 5.")
			continue
		}

		err = executeOperation(client, scanner, operation)
		if err == nil {
			continue
		}

		if errors.Is(err, io.EOF) {
			return
		}

		rpcStatus, ok := status.FromError(err)
		if !ok {
			fmt.Printf("Input error: %v\n", err)
			return
		}

		fmt.Printf("gRPC error: %s\n", rpcStatus.Code())
		fmt.Printf("Message: %s\n", rpcStatus.Message())

		if rpcStatus.Code() == codes.Unavailable {
			fmt.Printf(
				"Check that gRPCServer02 is running at %s.\n",
				serverAddress,
			)
		}
	}
}

func executeOperation(
	client pb.CalculatorClient,
	scanner *bufio.Scanner,
	operation string,
) error {
	if operation == "5" {
		x, err := readInt32(scanner, "x")
		if err != nil {
			return err
		}

		ctx, cancel := context.WithTimeout(
			context.Background(),
			5*time.Second,
		)
		defer cancel()

		response, err := client.FACT(ctx, &pb.FactorialRequest{
			X: x,
		})
		if err != nil {
			return err
		}

		fmt.Printf("FACT(%d) = %d\n", x, response.GetResult())
		return nil
	}

	x, err := readDouble(scanner, "x")
	if err != nil {
		return err
	}

	y, err := readDouble(scanner, "y")
	if err != nil {
		return err
	}

	request := &pb.BinaryOperationRequest{
		X: x,
		Y: y,
	}

	ctx, cancel := context.WithTimeout(
		context.Background(),
		5*time.Second,
	)
	defer cancel()

	var response *pb.DoubleResponse

	switch operation {
	case "1":
		response, err = client.SUM(ctx, request)
	case "2":
		response, err = client.SUB(ctx, request)
	case "3":
		response, err = client.MUL(ctx, request)
	case "4":
		response, err = client.DIV(ctx, request)
	default:
		return fmt.Errorf("unsupported operation: %s", operation)
	}

	if err != nil {
		return err
	}

	fmt.Printf("Result: %g\n", response.GetResult())
	return nil
}

func readLine(scanner *bufio.Scanner, prompt string) (string, error) {
	fmt.Print(prompt)

	if !scanner.Scan() {
		if err := scanner.Err(); err != nil {
			return "", err
		}

		return "", io.EOF
	}

	return strings.TrimSpace(scanner.Text()), nil
}

func readDouble(scanner *bufio.Scanner, name string) (float64, error) {
	for {
		input, err := readLine(scanner, "Enter "+name+": ")
		if err != nil {
			return 0, err
		}

		input = strings.ReplaceAll(input, ",", ".")

		value, err := strconv.ParseFloat(input, 64)
		if err == nil && !math.IsNaN(value) && !math.IsInf(value, 0) {
			return value, nil
		}

		fmt.Println(
			"Invalid number. Enter a finite number, for example 10 or 2.5.",
		)
	}
}

func readInt32(scanner *bufio.Scanner, name string) (int32, error) {
	for {
		input, err := readLine(scanner, "Enter "+name+": ")
		if err != nil {
			return 0, err
		}

		value, err := strconv.ParseInt(input, 10, 32)
		if err == nil {
			return int32(value), nil
		}

		fmt.Println("Invalid number. Enter a 32-bit integer.")
	}
}