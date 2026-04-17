using Dapper;
using System.Data;
using TravelAccomodationAPI.DataAccessClass.InterFaces;
using TravelAccomodationAPI.Shared.DBHelper;

namespace TravelAccomodationAPI.DataAccessClass
{
    public class DataAccessClass : IDataAccess
    {
        private readonly DbContext _context;

        public DataAccessClass(DbContext context)
        {
            _context = context;
        }

        public async Task<T> GetAsync<T>(
            string sp, DynamicParameters? parameters)
        {
            using var connection = _context.GetConnection();
            return await connection.QueryFirstOrDefaultAsync<T>(
                sp, parameters, commandType: CommandType.StoredProcedure);
        }

        public async Task<IEnumerable<T>> GetListAsync<T>(
            string sp, DynamicParameters? parameters)
        {
            using var connection = _context.GetConnection();
            return await connection.QueryAsync<T>(
                sp, parameters, commandType: CommandType.StoredProcedure);
        }

        public async Task<int> ExecuteAsync(
            string sp, DynamicParameters? parameters)
        {
            using var connection = _context.GetConnection();
            return await connection.ExecuteAsync(
                sp, parameters, commandType: CommandType.StoredProcedure);
        }

        public async Task<T> ExecuteScalarAsync<T>(
            string sp, DynamicParameters? parameters)
        {
            using var connection = _context.GetConnection();
            return await connection.ExecuteScalarAsync<T>(
                sp, parameters, commandType: CommandType.StoredProcedure);
        }

    }
}
