import Service

let defaultHost = "::1"
let defaultPort = 8888

let host = (CommandLine.argc > 1) ? CommandLine.arguments[1] : defaultHost

let service = KarbonService(host: host, port: defaultPort)
try service.start()
defer {
    service.stop()
}

