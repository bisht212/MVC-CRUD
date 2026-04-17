namespace TravelAccomodationAPI.ModelClass
{
    public class ApiResponse<T>
    {

        public int StatusCode { get; set; }

        public bool IsError { get; set; }

        public string? Message { get; set; }

        public T? Data { get; set; }



    }
}
