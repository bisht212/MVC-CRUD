using Microsoft.Data.SqlClient;
using System.Data;

namespace TravelAccomodationAPI.Shared.DBHelper
{
    public class DbContext
    {

        private readonly string _connectionString;

        public DbContext(IConfiguration configuration)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public IDbConnection GetConnection()
        {
            // return connection
            return new SqlConnection(_connectionString);
        }

    }
}
