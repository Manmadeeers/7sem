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
	ID      *int64         `json:"id,omitempty"`
}

type RPCCall struct {
	Method       string
	Params       map[string]any
	Notification bool
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

func (c *RPCClient) send(body []byte) ([]byte, error) {
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

	return responseBody, nil
}

func validateResponse(response RPCResponse) error {
	if response.JSONRPC != "2.0" {
		return errors.New("invalid JSON-RPC response version")
	}

	hasResult := len(response.Result) > 0
	hasError := response.Error != nil

	if hasResult == hasError {
		return errors.New(
			"response must contain exactly one of result or error",
		)
	}

	return nil
}

func (c *RPCClient) Call(
	method string,
	params map[string]any,
) (json.RawMessage, error) {
	c.nextID++
	requestID := c.nextID

	request := RPCRequest{
		JSONRPC: "2.0",
		Method:  method,
		Params:  params,
		ID:      &requestID,
	}

	body, err := json.Marshal(request)
	if err != nil {
		return nil, fmt.Errorf("encode request: %w", err)
	}

	responseBody, err := c.send(body)
	if err != nil {
		return nil, err
	}

	var rpcResponse RPCResponse

	if err := json.Unmarshal(responseBody, &rpcResponse); err != nil {
		return nil, fmt.Errorf("decode response: %w", err)
	}

	if err := validateResponse(rpcResponse); err != nil {
		return nil, err
	}

	if rpcResponse.ID == nil || *rpcResponse.ID != requestID {
		return nil, errors.New("response ID does not match request ID")
	}

	if rpcResponse.Error != nil {
		return nil, rpcResponse.Error
	}

	return rpcResponse.Result, nil
}

func (c *RPCClient) BatchCall(calls []RPCCall) ([]RPCResponse, error) {
	if len(calls) == 0 {
		return nil, errors.New("batch must contain at least one request")
	}

	requests := make([]RPCRequest, len(calls))
	requestIndexes := make(map[int64]int, len(calls))
	responseCount := 0

	for i, call := range calls {
		requests[i] = RPCRequest{
			JSONRPC: "2.0",
			Method:  call.Method,
			Params:  call.Params,
		}

		if call.Notification {
			continue
		}

		c.nextID++
		requestID := c.nextID
		requests[i].ID = &requestID
		requestIndexes[requestID] = responseCount
		responseCount++
	}

	body, err := json.Marshal(requests)
	if err != nil {
		return nil, fmt.Errorf("encode batch request: %w", err)
	}

	responseBody, err := c.send(body)
	if err != nil {
		return nil, err
	}

	var responses []RPCResponse
	if err := json.Unmarshal(responseBody, &responses); err != nil {
		return nil, fmt.Errorf("decode batch response: %w", err)
	}

	if len(responses) != responseCount {
		return nil, fmt.Errorf(
			"batch response count does not match expected count: got %d, want %d",
			len(responses),
			responseCount,
		)
	}

	ordered := make([]RPCResponse, len(responses))
	seen := make(map[int64]bool, len(responses))

	for _, response := range responses {
		if err := validateResponse(response); err != nil {
			return nil, fmt.Errorf("invalid batch response: %w", err)
		}

		if response.ID == nil {
			return nil, errors.New("batch response is missing an ID")
		}

		index, exists := requestIndexes[*response.ID]
		if !exists {
			return nil, fmt.Errorf(
				"batch response contains unknown ID %d",
				*response.ID,
			)
		}

		if seen[*response.ID] {
			return nil, fmt.Errorf(
				"batch response contains duplicate ID %d",
				*response.ID,
			)
		}

		seen[*response.ID] = true
		ordered[index] = response
	}

	return ordered, nil
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

func printOperations() {
	fmt.Println("1. SUM(x, y)")
	fmt.Println("2. SUB(x, y)")
	fmt.Println("3. MUL(x, y)")
	fmt.Println("4. DIV(x, y)")
	fmt.Println("5. FACT(x)")
}

func predefinedBatch() []RPCCall {
	return []RPCCall{
		{Method: "SUM", Params: map[string]any{"x": 2.0, "y": 3.0}},
		{Method: "SUM", Params: map[string]any{"x": 10.0, "y": 15.0}},
		{Method: "SUB", Params: map[string]any{"x": 10.0, "y": 4.0}},
		{Method: "SUB", Params: map[string]any{"x": 5.0, "y": 12.0}},
		{Method: "MUL", Params: map[string]any{"x": 3.0, "y": 7.0}},
		{Method: "MUL", Params: map[string]any{"x": -2.0, "y": 8.0}},
		{Method: "DIV", Params: map[string]any{"x": 20.0, "y": 4.0}},
		{Method: "DIV", Params: map[string]any{"x": 7.0, "y": 2.0}},
		{Method: "FACT", Params: map[string]any{"x": int32(5)}},
		{
			Method:       "SUM",
			Params:       map[string]any{"x": 100.0, "y": 200.0},
			Notification: true,
		},
	}
}

func callLabel(call RPCCall) string {
	if call.Method == "FACT" {
		return fmt.Sprintf("FACT(%v)", call.Params["x"])
	}

	return fmt.Sprintf(
		"%s(%v, %v)",
		call.Method,
		call.Params["x"],
		call.Params["y"],
	)
}

func main() {
	serverURL := flag.String(
		"url",
		"http://localhost:5270/rpc",
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
		printOperations()
		fmt.Println("6. Send predefined batch (10 items)")
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

		if choice == "6" {
			calls := predefinedBatch()

			responses, err := client.BatchCall(calls)
			if err != nil {
				fmt.Println("Error:", err)
				continue
			}

			fmt.Println("Batch results:")
			responseIndex := 0
			for i, call := range calls {
				fmt.Printf("%d. %s: ", i+1, callLabel(call))
				if call.Notification {
					fmt.Println("notification sent (no response expected)")
					continue
				}

				response := responses[responseIndex]
				responseIndex++
				if response.Error != nil {
					fmt.Println(response.Error)
					continue
				}

				fmt.Printf("%s\n", response.Result)
			}

			continue
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
