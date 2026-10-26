const path = require("node:path");
const grpc = require("@grpc/grpc-js");
const protoLoader = require("@grpc/proto-loader");

const address = "127.0.0.1:5000";

const protoPath = path.join(
  __dirname,
  "..",
  "Proto",
  "calculator.proto"
);

const packageDefinition = protoLoader.loadSync(protoPath, {
  keepCase: true,
  defaults: true
});

const calculator = grpc.loadPackageDefinition(
  packageDefinition
).calculator;

function createRpcError(code, message) {
  return Object.assign(new Error(message), {
    code,
    details: message
  });
}

const implementation = {
  SUM(call, callback) {
    const { x, y } = call.request;

    callback(null, {
      result: x + y
    });
  },

  SUB(call, callback) {
    const { x, y } = call.request;

    callback(null, {
      result: x - y
    });
  },

  MUL(call, callback) {
    const { x, y } = call.request;

    callback(null, {
      result: x * y
    });
  },

  DIV(call, callback) {
    const { x, y } = call.request;

    if (y === 0) {
      callback(createRpcError(
        grpc.status.INVALID_ARGUMENT,
        "Division by zero is not allowed."
      ));

      return;
    }

    callback(null, {
      result: x / y
    });
  },

  FACT(call, callback) {
    const { x } = call.request;

    if (x < 0) {
      callback(createRpcError(
        grpc.status.INVALID_ARGUMENT,
        "Factorial is defined only for non-negative integers."
      ));

      return;
    }

    if (x > 12) {
      callback(createRpcError(
        grpc.status.OUT_OF_RANGE,
        "Factorial exceeds the maximum value of Int32."
      ));

      return;
    }

    let result = 1;

    for (let i = 2; i <= x; i++) {
      result *= i;
    }

    callback(null, {
      result
    });
  }
};

const server = new grpc.Server();

server.addService(
  calculator.Calculator.service,
  implementation
);

server.bindAsync(
  address,
  grpc.ServerCredentials.createInsecure(),
  (error) => {
    if (error) {
      console.error("Failed to start gRPCServer02:", error.message);
      process.exitCode = 1;
      return;
    }

    console.log("gRPCServer02");
    console.log(`Listening on ${address}`);
    console.log("Press Ctrl+C to stop.");
  }
);

process.on("SIGINT", () => {
  console.log("\nStopping gRPCServer02...");

  server.tryShutdown(() => {
    console.log("Server stopped.");
  });
});