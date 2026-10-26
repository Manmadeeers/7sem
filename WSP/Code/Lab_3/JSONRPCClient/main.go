package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"math"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

type RPCRequest struct {
	JSONRPC string         `json:"jsonrpc"`
	Method  string         `json:"method"`
	Params  map[string]any `json:"params"`
	ID      int64          `json:"id"`
}

type RPCError struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
}

func (e *RPCError) Error() string {
	return fmt.Sprintf("JSON-RPC error %d: %s", e.Code, e.Message)
}

type RPCResponse struct {
	JSONRPC string          `json:"jsonrpc"`
	Result  json.RawMessage `json:"result"`
	Error   *RPCError       `json:"error"`
	ID      *int64          `json:"id"`
}

type RPCClient struct {
	URL        string
	HTTPClient *http.Client
	nextID     int64
}

func (c *RPCClient) Call(
	method string,
	params map[string]any,
) (json.RawMessage, error) {
	c.nextID++

	request := RPCRequest{
		JSONRPC: "2.0",
		Method:  method,
		Params:  params,
		ID:      c.nextID,
	}

	body, err := json.Marshal(request)
	if err != nil {
		return nil, fmt.Errorf("encode request: %w", err)
	}

	response, err := c.HTTPClient.Post(
		c.URL,
		"application/json",
		bytes.NewReader(body),
	)
	if err != nil {
		return nil, fmt.Errorf("send request: %w", err)
	}
	defer response.Body.Close()

	responseBody, err := io.ReadAll(response.Body)
	if err != nil {
		return nil, fmt.Errorf("read response: %w", err)
	}

	if response.StatusCode != http.StatusOK {
		return nil, fmt.Errorf(
			"HTTP error %s: %s",
			response.Status,
			strings.TrimSpace(string(responseBody)),
		)
	}

	var rpcResponse RPCResponse

	if err := json.Unmarshal(responseBody, &rpcResponse); err != nil {
		return nil, fmt.Errorf("decode response: %w", err)
	}

	if rpcResponse.JSONRPC != "2.0" {
		return nil, errors.New("invalid JSON-RPC response version")
	}

	if rpcResponse.ID == nil || *rpcResponse.ID != request.ID {
		return nil, errors.New("response ID does not match request ID")
	}

	hasResult := len(rpcResponse.Result) > 0
	hasError := rpcResponse.Error != nil

	if hasResult == hasError {
		return nil, errors.New(
			"response must contain exactly one of result or error",
		)
	}

	if hasError {
		return nil, rpcResponse.Error
	}

	return rpcResponse.Result, nil
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

func readParameters(
	scanner *bufio.Scanner,
	method string,
) (map[string]any, error) {
	params := make(map[string]any)

	names := []string{"x", "y"}

	if method == "FACT" {
		names = []string{"x"}
	}

	for _, name := range names {
		input, err := readLine(scanner, name+" = ")
		if err != nil {
			return nil, err
		}

		if method == "FACT" {
			value, err := strconv.ParseInt(input, 10, 32)
			if err != nil {
				return nil, fmt.Errorf(
					"%s must be an Int32 integer",
					name,
				)
			}

			params[name] = int32(value)
			continue
		}

		value, err := strconv.ParseFloat(input, 64)
		if err != nil || math.IsNaN(value) || math.IsInf(value, 0) {
			return nil, fmt.Errorf(
				"%s must be a finite number",
				name,
			)
		}

		params[name] = value
	}

	return params, nil
}

func main() {
	serverURL := flag.String(
		"url",
		"http://localhost:5080/rpc",
		"JSON-RPC server URL",
	)
	flag.Parse()

	client := &RPCClient{
		URL: *serverURL,
		HTTPClient: &http.Client{
			Timeout: 10 * time.Second,
		},
	}

	scanner := bufio.NewScanner(os.Stdin)

	methods := map[string]string{
		"1": "SUM",
		"2": "SUB",
		"3": "MUL",
		"4": "DIV",
		"5": "FACT",
	}

	fmt.Println("JSON-RPC Calculator Client")
	fmt.Println("Server:", client.URL)

	for {
		fmt.Println()
		fmt.Println("1. SUM(x, y)")
		fmt.Println("2. SUB(x, y)")
		fmt.Println("3. MUL(x, y)")
		fmt.Println("4. DIV(x, y)")
		fmt.Println("5. FACT(x)")
		fmt.Println("0. Exit")

		choice, err := readLine(scanner, "Select operation: ")
		if err != nil {
			if !errors.Is(err, io.EOF) {
				fmt.Fprintln(os.Stderr, "Input error:", err)
			}

			return
		}

		if choice == "0" {
			return
		}

		method, exists := methods[choice]
		if !exists {
			fmt.Println("Invalid operation.")
			continue
		}

		params, err := readParameters(scanner, method)
		if err != nil {
			if errors.Is(err, io.EOF) {
				return
			}

			fmt.Println("Input error:", err)
			continue
		}

		result, err := client.Call(method, params)
		if err != nil {
			fmt.Println("Error:", err)
			continue
		}

		fmt.Printf("Result: %s\n", result)
	}
}