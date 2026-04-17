using Dapper;

namespace TravelAccomodationAPI.DataAccessClass.InterFaces
{
    public interface IDataAccess
    {

        Task<T> GetAsync<T>(string sp, DynamicParameters parameters = null);

        Task<IEnumerable<T>> GetListAsync<T>(
            string sp, DynamicParameters parameters = null);

        Task<int> ExecuteAsync(
            string sp, DynamicParameters parameters = null);

        Task<T> ExecuteScalarAsync<T>(
            string sp, DynamicParameters parameters = null);

    }
}
