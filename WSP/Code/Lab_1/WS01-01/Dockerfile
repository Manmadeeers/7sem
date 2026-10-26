FROM mcr.microsoft.com/dotnet/sdk:8.0-noble AS build

WORKDIR /src

COPY WS01-01/ ./

RUN dotnet publish WS01-01.csproj \
    --configuration Release \
    --runtime linux-x64 \
    --self-contained true \
    -p:PublishSingleFile=true \
    -p:IncludeNativeLibrariesForSelfExtract=true \
    -p:DebugType=embedded \
    --output /out

FROM mcr.microsoft.com/dotnet/runtime-deps:8.0-noble AS final

WORKDIR /app

COPY --from=build /out/WS01-01 ./

ENV ASPNETCORE_URLS=http://+:8080
ENV DOTNET_BUNDLE_EXTRACT_BASE_DIR=/tmp/ws01-bundle

EXPOSE 8080

USER $APP_UID

ENTRYPOINT ["./WS01-01"]