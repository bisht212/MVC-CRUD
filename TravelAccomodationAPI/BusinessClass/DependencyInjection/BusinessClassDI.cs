using TravelAccomodationAPI.TokenCreateClass;
using TravelAccomodationAPI.TokenCreateClass.InterFaces;

namespace TravelAccomodationAPI.BusinessClass.DependencyInjection
{
    public static class BusinessClassDI
    {

        public static IServiceCollection AddBusinessServices(
                   this IServiceCollection services)
        {
            // Business services (example)
            services.AddScoped<IToken, Token>();

            return services;
        }

    }
}
