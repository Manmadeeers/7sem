FROM mcr.microsoft.com/dotnet/sdk:8.0-noble AS build

WORKDIR /src

COPY WS01-02/ ./

RUN dotnet publish WS01-02.csproj \
    --configuration Release \
    --runtime linux-x64 \
    --self-contained true \
    -p:PublishSingleFile=true \
    -p:IncludeNativeLibrariesForSelfExtract=true \
    --output /out

FROM mcr.microsoft.com/dotnet/runtime-deps:8.0-noble AS final

WORKDIR /app

RUN mkdir -p /app/keys

RUN chown "$APP_UID:$APP_UID" /app/keys

COPY --from=build /out/WS01-02 ./

ENV ASPNETCORE_URLS=http://+:8080
ENV DOTNET_BUNDLE_EXTRACT_BASE_DIR=/tmp/ws02-bundle
ENV DataProtection__KeyPath=/app/keys

EXPOSE 8080

USER $APP_UID

ENTRYPOINT ["./WS01-02"]