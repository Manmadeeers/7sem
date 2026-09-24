const SERVICE_URL = "http://192.168.122.79:8080/resource.FIA";

async function callService(method, body) {
    const options = {
        method: method,
        credentials: "same-origin"
    };

    if (body !== undefined && body !== null) {
        options.headers = { "Content-Type": "application/x-www-form-urlencoded" };
        options.body = body;
    }

    const response = await fetch(SERVICE_URL, options);
    const text = await response.text();

    let data;
    try {
        data = JSON.parse(text);
    } catch (e) {
        data = { raw: text };
    }

    return { status: response.status, data: data };
}

function updateOutput(data) {
    const el = document.querySelector(".output");
    if (data && typeof data === "object" && "RESULT" in data) {
        el.textContent = data.RESULT;
    } else {
        el.textContent = JSON.stringify(data);
    }
}

async function handleGET() {
    const result = await callService("GET");
    updateOutput(result.data);
}

async function handlePOST() {
    const value = document.querySelector("input[name='RESULT-input']").value;

    if (value === "") {
        alert("Enter a value for RESULT");
        return;
    }

    const body = "RESULT=" + encodeURIComponent(value);
    const result = await callService("POST", body);
    updateOutput(result.data);
}

async function handlePUT() {
    const value = document.querySelector("input[name='ADD-input']").value;

    if (value === "") {
        alert("Enter a value for ADD");
        return;
    }

    const body = "ADD=" + encodeURIComponent(value);
    await callService("PUT", body);
    // PUT only pushes to the stack; it does not change RESULT.
    // Fetch the current RESULT to keep the display accurate.
    await handleGET();
}

async function handleDELETE() {
    const result = await callService("DELETE");
    updateOutput(result.data);
}