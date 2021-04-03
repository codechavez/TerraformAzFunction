using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace AzFunctionHelloWorld
{
    public static class HelloWorldSample
    {
        [FunctionName("MirrorHelloWorld")]
        public static async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = null)] HttpRequest req, ILogger log)
        {
            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic data = JsonConvert.DeserializeObject(requestBody);

            if (data is null)
                return new BadRequestObjectResult("Dude! pass me some value");

            var responseMessage = $"You said, {data.message}";

            return new OkObjectResult(responseMessage);
        }
    }
}

