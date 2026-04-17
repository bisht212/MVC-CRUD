using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;

namespace TravelAccomodationAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UsersController : ControllerBase
    {
        [HttpGet("GetUserList")]
        public IActionResult GetUsers() {

            return Ok(); 
        }


        [HttpPost("CreateUsers")]
        public IActionResult CreateUser() {
            return Created(); 
    }
}
