FROM mcr.microsoft.com/dotnet/sdk:8.0-noble AS build

WORKDIR /src

COPY Gateway02/ ./

RUN dotnet publish Gateway02.csproj \
    --configuration Release \
    --self-contained false \
    --output /out

FROM mcr.microsoft.com/dotnet/aspnet:8.0-noble AS final

WORKDIR /app

COPY --from=build /out/ ./

ENV ASPNETCORE_URLS=http://+:8080

EXPOSE 8080

USER $APP_UID

ENTRYPOINT ["dotnet", "Gateway02.dll"]