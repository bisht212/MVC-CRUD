using TravelAccomodationAPI.Shared.DBHelper;

namespace TravelAccomodationAPI.DataAccessClass.DependencyInjection
{
    public static class DataAccessClassDI
    {

        public static IServiceCollection AddDataAccess(
                    this IServiceCollection services)
        {
            services.AddSingleton<DbContext>();

            return services;
        }

    }
}
