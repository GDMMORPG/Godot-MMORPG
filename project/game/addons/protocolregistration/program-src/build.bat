:: For Linux
set GOOS=linux
set GOARCH=amd64
go build -o ../bin/protocolregistry.amd64.linux.app

:: For macOS
set GOOS=darwin
set GOARCH=amd64
go build -o ../bin/protocolregistry.amd64.darwin.app

:: For Windows (from Windows, usually default)
set GOOS=windows
set GOARCH=amd64
go build -o ../bin/protocolregistry.amd64.windows.exe
