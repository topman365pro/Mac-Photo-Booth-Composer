param(
    [string]$BuildDir = "build"
)

cmake -S . -B $BuildDir -G Ninja
cmake --build $BuildDir
cmake --install $BuildDir --prefix "$BuildDir/install"
Write-Host "Windows package assets installed under $BuildDir/install"
