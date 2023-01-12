using Godot;
using System;
using System.Collections.Generic;
using Microsoft.Azure.CognitiveServices.Vision.ComputerVision;
using Microsoft.Azure.CognitiveServices.Vision.ComputerVision.Models;
using System.Threading.Tasks;
using System.IO;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Threading;
using System.Linq;

public partial class CameraScript : Node2D
{
    static string subscriptionKey = "9026448ec0974609883be3a3fd84b2d2";
    static string endpoint = "https://legendarischeserver.cognitiveservices.azure.com/";
    private const string READ_TEXT_URL_IMAGE = "https://raw.githubusercontent.com/Azure-Samples/cognitive-services-sample-data-files/master/ComputerVision/Images/printed_text.jpg";
    bool imageRead = false;
    public override void _Process(float delta)
    {
        if(imageRead) return;
        imageRead = true;

        ComputerVisionClient client = Authenticate(endpoint, subscriptionKey);

        ReadFileUrl(client, READ_TEXT_URL_IMAGE);
    }

    public static ComputerVisionClient Authenticate(string endpoint, string key)
    {
        ComputerVisionClient client =
          new ComputerVisionClient(new ApiKeyServiceClientCredentials(key))
          { Endpoint = endpoint };
        return client;
    }

    public static async Task ReadFileUrl(ComputerVisionClient client, string urlFile)
    {
        GD.Print("reading image");

        // Read text from URL
        var textHeaders = await client.ReadAsync(urlFile);
        GD.Print("Request made");
        // After the request, get the operation location (operation ID)
        string operationLocation = textHeaders.OperationLocation;
        System.Threading.Thread.Sleep(2000);

        // Retrieve the URI where the extracted text will be stored from the Operation-Location header.
        // We only need the ID and not the full URL
        const int numberOfCharsInOperationId = 36;
        string operationId = operationLocation.Substring(operationLocation.Length - numberOfCharsInOperationId);

        // Extract the text
        ReadOperationResult results;
       
        do
        {
            results = await client.GetReadResultAsync(Guid.Parse(operationId));
        }
        while ((results.Status == OperationStatusCodes.Running ||
            results.Status == OperationStatusCodes.NotStarted));

        // Display the found text.
        
        var textUrlFileResults = results.AnalyzeResult.ReadResults;
        foreach (ReadResult page in textUrlFileResults)
        {
            foreach (Line line in page.Lines)
            {
                GD.Print(line.Text);
            }
        }
    }
}
