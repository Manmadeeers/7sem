using System;
using System.Collections.Generic;
using System.Web;
using System.Web.SessionState;
using System.Web.Script.Serialization;

namespace Lab1
{
    public class FiaHttpHandler : IHttpHandler, IRequiresSessionState
    {
        private const string SessionResultKey = "RESULT";
        private const string SessionStackKey = "Stack";

        public bool IsReusable => false;

        private void EnsureSessionInitialized(HttpContext context)
        {
            if (context.Application[SessionResultKey] == null)
                context.Application[SessionResultKey] = 0;

            if (context.Session[SessionStackKey] == null)
                context.Session[SessionStackKey] = new Stack<int>();
        }

        private void WriteJson(HttpContext context, object data)
        {
            var serializer = new JavaScriptSerializer();
            context.Response.Write(serializer.Serialize(data));
        }

        private void HandleGet(HttpContext context)
        {
            int result = (int)context.Application[SessionResultKey];
            WriteJson(context, new { RESULT = result });
        }

        private void HandlePost(HttpContext context)
        {
            string resultParam = context.Request["RESULT"];

            if (string.IsNullOrEmpty(resultParam) || !int.TryParse(resultParam, out int newResult))
            {
                context.Response.StatusCode = 400;
                WriteJson(context, new { error = "Parameter RESULT is required and must be an integer" });
                return;
            }

            context.Application[SessionResultKey] = newResult;
            WriteJson(context, new { RESULT = newResult });


        }

        private void HandlePut(HttpContext context)
        {
            string addParam = context.Request["ADD"];
            if (string.IsNullOrEmpty(addParam) || !int.TryParse(addParam, out int valueToAdd))
            {
                context.Response.StatusCode = 400;
                WriteJson(context, new { error = "Parameter ADD is required and must be an integer" });
                return;
            }

            var stack = (Stack<int>)context.Session[SessionStackKey];
            stack.Push(valueToAdd);
            context.Session[SessionStackKey] = stack;

            WriteJson(context, new { message = "Pushed", ADD = valueToAdd });
        }

        private void HandleDelete(HttpContext context)
        {
            var stack = (Stack<int>)context.Session[SessionStackKey];
            if (stack.Count == 0)
            {
                context.Response.StatusCode = 400;
                WriteJson(context, new { error = "Stack is empty, cannot POP" });
                return;
            }

            int poppedValue = stack.Pop();
            context.Session[SessionStackKey] = stack;

            int currentResult = (int)context.Application[SessionResultKey];
            int newResult = currentResult + poppedValue;
            context.Application[SessionResultKey] = newResult;

            WriteJson(context, new { RESULT = newResult, POP = poppedValue });
        }

        public void ProcessRequest(HttpContext context)
        {

            context.Response.Headers["Access-Control-Allow-Origin"] = "*";
            context.Response.Headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS";
            context.Response.Headers["Access-Control-Allow-Headers"] = "Content-Type";

            if (context.Request.HttpMethod == "OPTIONS")
            {
                context.Response.StatusCode = 200;
                return;
            }
            
            context.Response.ContentType = "application/json";
            EnsureSessionInitialized(context);

            try
            {
                switch (context.Request.HttpMethod)
                {
                    case "GET":
                        HandleGet(context);
                        break;
                    case "POST":
                        HandlePost(context);
                        break;
                    case "PUT":
                        HandlePut(context);
                        break;
                    case "DELETE":
                        HandleDelete(context);
                        break;
                }
            }
            catch (Exception ex)
            {
                context.Response.StatusCode = 500;
                WriteJson(context, new { error = ex.Message });
            }
        }
    }
}