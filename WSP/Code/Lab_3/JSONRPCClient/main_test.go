package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"reflect"
	"strings"
	"testing"
)

func TestBatchCallMatchesResponsesByID(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(
		writer http.ResponseWriter,
		request *http.Request,
	) {
		if request.Header.Get("Content-Type") != "application/json" {
			t.Errorf("Content-Type = %q, want application/json", request.Header.Get("Content-Type"))
		}

		var requests []RPCRequest
		if err := json.NewDecoder(request.Body).Decode(&requests); err != nil {
			t.Errorf("decode requests: %v", err)
			http.Error(writer, "invalid request", http.StatusBadRequest)
			return
		}

		if len(requests) != 2 {
			t.Errorf("request count = %d, want 2", len(requests))
			http.Error(writer, "invalid request count", http.StatusBadRequest)
			return
		}
		if requests[0].Method != "SUM" || requests[1].Method != "FACT" {
			t.Errorf(
				"methods = [%s, %s], want [SUM, FACT]",
				requests[0].Method,
				requests[1].Method,
			)
		}

		writer.Header().Set("Content-Type", "application/json")
		if err := json.NewEncoder(writer).Encode([]map[string]any{
			{
				"jsonrpc": "2.0",
				"result":  120,
				"id":      requests[1].ID,
			},
			{
				"jsonrpc": "2.0",
				"result":  5,
				"id":      requests[0].ID,
			},
		}); err != nil {
			t.Errorf("encode responses: %v", err)
		}
	}))
	defer server.Close()

	client := &RPCClient{
		URL:        server.URL,
		HTTPClient: server.Client(),
	}

	responses, err := client.BatchCall([]RPCCall{
		{
			Method: "SUM",
			Params: map[string]any{"x": 2.0, "y": 3.0},
		},
		{
			Method: "FACT",
			Params: map[string]any{"x": int32(5)},
		},
	})
	if err != nil {
		t.Fatalf("BatchCall returned an error: %v", err)
	}

	if got := string(responses[0].Result); got != "5" {
		t.Errorf("first result = %s, want 5", got)
	}
	if got := string(responses[1].Result); got != "120" {
		t.Errorf("second result = %s, want 120", got)
	}
	if *responses[0].ID >= *responses[1].ID {
		t.Errorf(
			"response order was not restored: IDs are %d, %d",
			*responses[0].ID,
			*responses[1].ID,
		)
	}
}

func TestBatchCallReturnsIndividualRPCErrors(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(
		writer http.ResponseWriter,
		request *http.Request,
	) {
		var requests []RPCRequest
		if err := json.NewDecoder(request.Body).Decode(&requests); err != nil {
			t.Errorf("decode requests: %v", err)
			http.Error(writer, "invalid request", http.StatusBadRequest)
			return
		}

		writer.Header().Set("Content-Type", "application/json")
		if err := json.NewEncoder(writer).Encode([]map[string]any{
			{
				"jsonrpc": "2.0",
				"error": map[string]any{
					"code":    1001,
					"message": "Division by zero is not allowed.",
				},
				"id": requests[0].ID,
			},
		}); err != nil {
			t.Errorf("encode response: %v", err)
		}
	}))
	defer server.Close()

	client := &RPCClient{
		URL:        server.URL,
		HTTPClient: server.Client(),
	}

	responses, err := client.BatchCall([]RPCCall{
		{
			Method: "DIV",
			Params: map[string]any{"x": 4.0, "y": 0.0},
		},
	})
	if err != nil {
		t.Fatalf("BatchCall returned a batch-level error: %v", err)
	}

	if responses[0].Error == nil {
		t.Fatal("response error is nil")
	}
	if responses[0].Error.Code != 1001 {
		t.Errorf("error code = %d, want 1001", responses[0].Error.Code)
	}
}

func TestBatchCallDoesNotExpectNotificationResponse(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(
		writer http.ResponseWriter,
		request *http.Request,
	) {
		var requests []RPCRequest
		if err := json.NewDecoder(request.Body).Decode(&requests); err != nil {
			t.Errorf("decode requests: %v", err)
			http.Error(writer, "invalid request", http.StatusBadRequest)
			return
		}

		if len(requests) != 2 {
			t.Errorf("request count = %d, want 2", len(requests))
			http.Error(writer, "invalid request count", http.StatusBadRequest)
			return
		}
		if requests[0].ID == nil {
			t.Error("regular request is missing an ID")
		}
		if requests[1].ID != nil {
			t.Errorf("notification ID = %d, want it omitted", *requests[1].ID)
		}

		writer.Header().Set("Content-Type", "application/json")
		if err := json.NewEncoder(writer).Encode([]map[string]any{
			{
				"jsonrpc": "2.0",
				"result":  3,
				"id":      requests[0].ID,
			},
		}); err != nil {
			t.Errorf("encode response: %v", err)
		}
	}))
	defer server.Close()

	client := &RPCClient{
		URL:        server.URL,
		HTTPClient: server.Client(),
	}

	responses, err := client.BatchCall([]RPCCall{
		{
			Method: "SUM",
			Params: map[string]any{"x": 1.0, "y": 2.0},
		},
		{
			Method:       "SUM",
			Params:       map[string]any{"x": 10.0, "y": 20.0},
			Notification: true,
		},
	})
	if err != nil {
		t.Fatalf("BatchCall returned an error: %v", err)
	}

	if len(responses) != 1 {
		t.Fatalf("response count = %d, want 1", len(responses))
	}
	if got := string(responses[0].Result); got != "3" {
		t.Errorf("result = %s, want 3", got)
	}
}

func TestPredefinedBatchContents(t *testing.T) {
	calls := predefinedBatch()
	if len(calls) != 10 {
		t.Fatalf("batch size = %d, want 10", len(calls))
	}

	wantParams := []map[string]any{
		{"x": 2.0, "y": 3.0},
		{"x": 10.0, "y": 15.0},
		{"x": 10.0, "y": 4.0},
		{"x": 5.0, "y": 12.0},
		{"x": 3.0, "y": 7.0},
		{"x": -2.0, "y": 8.0},
		{"x": 20.0, "y": 4.0},
		{"x": 7.0, "y": 2.0},
		{"x": int32(5)},
		{"x": 100.0, "y": 200.0},
	}
	for i, call := range calls {
		if !reflect.DeepEqual(call.Params, wantParams[i]) {
			t.Errorf(
				"parameters for batch item %d = %#v, want %#v",
				i+1,
				call.Params,
				wantParams[i],
			)
		}
	}

	methodCounts := make(map[string]int)
	notificationCount := 0

	for _, call := range calls {
		if call.Notification {
			notificationCount++
			continue
		}

		methodCounts[call.Method]++
	}

	wantCounts := map[string]int{
		"SUM":  2,
		"SUB":  2,
		"MUL":  2,
		"DIV":  2,
		"FACT": 1,
	}
	for method, want := range wantCounts {
		if got := methodCounts[method]; got != want {
			t.Errorf("%s request count = %d, want %d", method, got, want)
		}
	}
	if notificationCount != 1 {
		t.Errorf("notification count = %d, want 1", notificationCount)
	}
}

func TestBatchCallRejectsEmptyBatch(t *testing.T) {
	client := &RPCClient{}

	_, err := client.BatchCall(nil)
	if err == nil || !strings.Contains(err.Error(), "at least one") {
		t.Fatalf("BatchCall error = %v, want an empty-batch error", err)
	}
}
